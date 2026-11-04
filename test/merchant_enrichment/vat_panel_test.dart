import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'fixtures.dart';
import 'vat_fixtures.dart';

void main() {
  late VatTransport transport;
  late Map<int, MerchantImportRow> rows;
  late EnrichmentUseCase session;
  setUp(() {
    transport = VatTransport()
      ..currentJob = jobJson(status: 'completed', done: 1, total: 1);
    rows = {1: row(1)};
    session = EnrichmentUseCase(
        repository: EnrichmentRepository(transport),
        batchId: 12,
        enabled: true,
        currentRow: (id) => rows[id],
        batchEditable: () => true,
        replaceRows: (next) {
          for (final r in next) {
            rows[r.id] = r;
          }
        },
        reloadRows: () async => rows.values.toList());
  });
  tearDown(() => session.dispose());

  Future<void> openCandidate(WidgetTester tester, Json candidate) async {
    transport.proposals = [vatProposalJson(candidate)];
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await session.initialize();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EnrichmentButton(
                session: session,
                rows: () => rows.values.toList(),
                prepare: () async => true))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compléter les informations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('proposal-$proposalId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer / choisir'));
    await tester.pumpAndSettle();
  }

  void expectNoFakeVerification() {
    expect(find.widgetWithText(OutlinedButton, 'VIES'), findsNothing);
    expect(find.textContaining('Vérifier'), findsNothing);
    expect(find.textContaining('validée'), findsNothing);
    expect(find.textContaining('assujettissement garanti'), findsNothing);
  }

  testWidgets(
      'found VAT: value, dated DGFiP source, disclaimer, choice linked to SIRET',
      (tester) async {
    await openCandidate(tester, vatCandidateJson());

    expect(find.textContaining('Trouvée dans la source DGFiP datée'),
        findsWidgets);
    expect(find.text('Appliquer la TVA $vatNumber'), findsOneWidget);
    expect(find.textContaining('Date de lecture : 3 novembre 2026 à '), findsOneWidget);
    // Requête DGFiP complète au survol du lien court, pas dans le texte.
    final vatLink = find.byKey(const ValueKey('vat-source-link'));
    expect(vatLink, findsOneWidget);
    expect(
        find.descendant(
            of: vatLink,
            matching: find.byWidgetPredicate((w) =>
                w is Tooltip &&
                (w.message ?? '').contains('vat_no%3D%22G3990000001%22'))),
        findsOneWidget);
    expect(find.textContaining('vat_no%3D%22G3990000001%22'), findsNothing);
    expect(find.byKey(const ValueKey('vat-disclaimer')), findsOneWidget);
    expect(find.textContaining('ni une vérification VIES en temps réel'),
        findsOneWidget);
    expectNoFakeVerification();

    final choice = find.byKey(const ValueKey('vat-choice'));
    expect(tester.widget<CheckboxListTile>(choice).value, false,
        reason: 'aucune sélection implicite');
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(choice).value, true);

    final apply = find.widgetWithText(FilledButton, 'Appliquer au brouillon');
    await tester.tap(apply);
    await tester.pumpAndSettle();
    final write = transport.calls.singleWhere((c) => c.path.endsWith('/apply'));
    expect(write.body!['fields'], ['intracommunity_vat_number', 'siret'],
        reason: 'ligne sans SIRET : TVA et SIRET dans la même opération');
    expect(transport.calls.any((c) => c.path.endsWith('/import')), false);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('not found, unavailable and ambiguous never offer a choice',
      (tester) async {
    for (final (status, label) in [
      ('not_found', 'n’exclut pas un numéro hors de cette source'),
      ('unavailable', 'ce n’est pas une absence'),
      ('ambiguous', 'Plusieurs numéros dans la source : aucun proposé'),
    ]) {
      transport.calls.clear();
      await openCandidate(
          tester, vatCandidateJson(status: status, number: null));
      expect(find.textContaining(label), findsWidgets, reason: status);
      expect(find.byKey(const ValueKey('vat-choice')), findsNothing,
          reason: status);
      expectNoFakeVerification();
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      session = EnrichmentUseCase(
          repository: EnrichmentRepository(transport),
          batchId: 12,
          enabled: true,
          currentRow: (id) => rows[id],
          batchEditable: () => true,
          replaceRows: (_) {},
          reloadRows: () async => rows.values.toList());
    }
  });

  testWidgets('capability vat off keeps the lot 01 presentation',
      (tester) async {
    transport.vat = false;
    await openCandidate(tester, vatCandidateJson());

    expect(find.textContaining('TVA : Non vérifiée'), findsOneWidget);
    expect(find.byKey(const ValueKey('vat-choice')), findsNothing);
    expect(find.textContaining(vatNumber), findsNothing,
        reason: 'aucune valeur TVA affichée sans capability');
    expect(find.byKey(const ValueKey('vat-disclaimer')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('existing VAT on the row is kept and not selectable',
      (tester) async {
    rows[1] = row(1, fields: {
      'name': 'Atelier Synthétique 1',
      'type': 'partner',
      'siret': vatSiret,
      'intracommunity_vat_number': 'FR00999999999'
    });
    await openCandidate(tester, vatCandidateJson());

    expect(find.textContaining('Valeur actuelle conservée : FR00999999999'),
        findsOneWidget);
    final choice = find.byKey(const ValueKey('vat-choice'));
    expect(tester.widget<CheckboxListTile>(choice).onChanged, isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
