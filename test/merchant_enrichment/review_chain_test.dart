import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'fixtures.dart';

/// « Traiter une par une » : les propositions à traiter s'enchaînent, chaque
/// application reste un choix humain explicite (aucun champ coché d'office).

const _p4 = '00000000-0000-4000-8000-000000000014';
const _p5 = '00000000-0000-4000-8000-000000000015';

/// Apply répondu pour la proposition demandée (le faux transport commun ne
/// connaît que la première).
class _Transport extends FakeEnrichmentTransport {
  @override
  Future<EnrichmentResponse> send(String method, String path,
      {required String tenant,
      Json? body,
      Map<String, String>? headers}) async {
    final match =
        RegExp(r'enrichment-proposals/([^/]+)/apply').firstMatch(path);
    if (match == null) {
      return super
          .send(method, path, tenant: tenant, body: body, headers: headers);
    }
    calls.add((
      method: method,
      path: path,
      tenant: tenant,
      body: body,
      headers: headers
    ));
    final proposal = proposals.firstWhere((p) => p['id'] == match[1]);
    final rowId = proposal['row_id'] as int;
    return EnrichmentResponse(200, {
      'data': {
        'proposal': {...proposal, 'state': 'applied'},
        'row': rowJson(rowId, version: 2, fields: {
          'name': 'Atelier Synthétique $rowId',
          'type': 'partner',
          'city': 'Ville Synthétique'
        }),
        'related': <Json>[],
      }
    });
  }
}

void main() {
  late _Transport transport;
  late Map<int, MerchantImportRow> rows;
  late EnrichmentUseCase session;
  setUp(() {
    transport = _Transport()
      ..currentJob = jobJson(status: 'completed', done: 3, total: 3)
      ..proposals = [
        proposalJson(rowId: 1),
        // Rien à proposer : jamais dans la revue.
        {
          ...proposalJson(state: 'not_found', rowId: 5, candidates: []),
          'id': _p5
        },
        {
          ...proposalJson(state: 'ambiguous', rowId: 4, candidates: [
            candidateJson(),
            {
              ...candidateJson(id: '00000000-0000-4000-8000-000000000024'),
              'label': 'Autre adresse synthétique'
            }
          ]),
          'id': _p4
        },
      ];
    rows = {1: row(1), 4: row(4), 5: row(5)};
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

  Future<void> pump(WidgetTester tester) async {
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
  }

  /// Dans la fenêtre de revue (la liste reste derrière).
  Finder inReview(Finder finder) =>
      find.descendant(of: find.byType(Dialog).last, matching: finder);

  bool anyChecked(WidgetTester tester) => tester
      .widgetList<Checkbox>(find.byType(Checkbox))
      .any((c) => c.value == true);

  testWidgets('apply and next, explicit candidate, skip, end screen',
      (tester) async {
    await pump(tester);
    expect(find.text('Traiter une par une (2 propositions sur cette page)'),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('review-chain')));
    await tester.pumpAndSettle();

    // Ligne 1 : rien de coché, application impossible sans choix.
    expect(inReview(find.textContaining('Ligne 1 · ')), findsOneWidget);
    expect(
        find.text('2 propositions à traiter sur cette page'), findsOneWidget);
    expect(anyChecked(tester), isFalse);
    final next = find.widgetWithText(FilledButton, 'Appliquer et suivante');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    final applies =
        transport.calls.where((c) => c.path.endsWith('/apply')).toList();
    expect(applies.single.path, contains(proposalId));

    // La proposition sans candidat est sautée ; ligne 4 : deux candidats,
    // rien de coché, choix explicite du candidat affiché.
    expect(inReview(find.textContaining('Ligne 4 · ')), findsOneWidget);
    expect(find.text('1 proposition à traiter sur cette page'), findsOneWidget);
    expect(find.text('1 appliquée'), findsOneWidget);
    expect(anyChecked(tester), isFalse);
    expect(find.byType(ChoiceChip), findsNWidgets(2));
    await tester.tap(find.textContaining('2. Autre adresse'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir : Autre adresse synthétique'), findsOneWidget);

    // Passer : plus rien à traiter, écran de fin, aucune autre écriture.
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text('Revue terminée'), findsOneWidget);
    expect(find.textContaining('1 proposition appliquée au brouillon'),
        findsOneWidget);
    expect(
        transport.calls.where((c) => c.path.endsWith('/apply')), hasLength(1));
    await tester.tap(find.widgetWithText(FilledButton, 'Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Traiter une par une (1 proposition sur cette page)'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('« Comparer / choisir » stays a single review', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('proposal-$proposalId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer / choisir'));
    await tester.pumpAndSettle();
    expect(find.text('Passer'), findsNothing);
    expect(find.text('Appliquer et suivante'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Appliquer au brouillon'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
