import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_import_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/chat_context_reference.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/research_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/chat_comparison_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/research_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/chat_comparison.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_import/merchant_import_grid.dart';
import 'fixtures.dart';
import 'vat_fixtures.dart';
import 'research_flow_test.dart' as research;

class UiAssistant implements AssistantRepository {
  @override
  Future<String> createSession() async => 'a' * 32;
  @override
  Future<AssistantReply> sendMessage(String id, String message) async =>
      AssistantReply.fromJson({
        'text':
            'Comparaison synthétique. Vérifiez les sources avant votre choix.',
        'blocks': []
      });
}

class UiImportUseCase extends MerchantImportUseCase {
  int imports = 0;
  static const batch =
      MerchantImportBatch(id: 12, status: 'review', source: 'synthese.csv');
  @override
  Future<MerchantImportBatch> getBatch(int id) async => batch;
  @override
  Future<List<MerchantImportRow>> getRows(int id, {String? status}) async =>
      [row(1, status: 'validated')];
  @override
  Future<MerchantImportResult> importValidated(int id,
      {String? idempotencyKey}) async {
    imports++;
    return MerchantImportResult(failed: [
      for (var i = 1; i <= 25; i++)
        MerchantImportFailure(
            id: i,
            error:
                'Échec synthétique de cette ligne à relire avant une nouvelle tentative.')
    ], skipped: const [
      26
    ]);
  }
}

void main() {
  const captureDir = String.fromEnvironment('E08_CAPTURE_DIR');
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (captureDir.isEmpty) return;
    // Offline capture fallback, explicitly documented: Segoe UI, not real Poppins.
    for (final family in [
      'Poppins',
      'Poppins_regular',
      'Roboto',
      for (var weight = 100; weight <= 900; weight += 100) 'Poppins_$weight'
    ]) {
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(
                File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync()))))
          .load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(File(
                  'C:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytesSync()))))
        .load();
  });

  Future<void> capture(WidgetTester tester, String name) async {
    if (captureDir.isEmpty) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('ui-capture')));
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(captureDir).createSync(recursive: true);
      File('$captureDir/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> host(
      WidgetTester tester, Size size, Widget Function(BuildContext) dialog,
      {double scale = 1.3, Future<void> Function(BuildContext)? open}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('ui-capture'),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => open != null
                            ? open(context)
                            : showDialog<void>(
                                context: context, builder: dialog),
                        child: const Text('Ouvrir')))))));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  EnrichmentUseCase session(FakeEnrichmentTransport transport,
          Map<int, MerchantImportRow> rows) =>
      EnrichmentUseCase(
          repository: EnrichmentRepository(transport),
          batchId: 12,
          enabled: true,
          currentRow: (id) => rows[id],
          batchEditable: () => true,
          replaceRows: (next) {
            for (final row in next) {
              rows[row.id] = row;
            }
          },
          reloadRows: () async => rows.values.toList(),
          pollInterval: const Duration(hours: 1));

  Future<void> visibleTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(1366, 768),
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(390, 844)
  ]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('ui real import abandonment confirmation $tag at 130%',
        (tester) async {
      bool? result;
      await host(tester, size, (_) => const SizedBox(), open: (context) async {
        result = await confirmCancelBatch(context);
      });
      expect(result, isNull);
      await capture(tester, 'confirmation-import-$tag-130');
      await visibleTap(tester, find.text('Annuler'));
      expect(result, isFalse);
      await visibleTap(tester, find.text('Ouvrir'));
      await visibleTap(tester, find.text('Abandonner'));
      expect(result, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets('ui grid import confirmation then many failures $tag at 130%',
        (tester) async {
      final useCase = UiImportUseCase();
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('ui-capture'),
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!),
              home: Scaffold(
                  body: OverflowBox(
                      minWidth: 1366,
                      maxWidth: 1366,
                      minHeight: 768,
                      maxHeight: 768,
                      alignment: Alignment.topLeft,
                      child: MerchantImportGrid(
                          batch: UiImportUseCase.batch,
                          useCase: useCase,
                          enrichmentEnabled: false,
                          onBack: () {},
                          onImported: () {}))))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importer les lignes validées (1)'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(useCase.imports, 0);
      await capture(tester, 'confirmation-lignes-$tag-130');
      await visibleTap(tester, find.text('Importer'));
      expect(useCase.imports, 1);
      expect(find.text("Résultat de l'import"), findsOneWidget);
      await capture(tester, 'resultat-import-$tag-130');
      await tester.ensureVisible(find.textContaining('nouvelles anomalies'));
      await tester.pumpAndSettle();
      final close = find.text('Fermer');
      expect(tester.getRect(close).bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);
      await visibleTap(tester, close);
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets('ui real selection, results, review/TVA and error $tag at 130%',
        (tester) async {
      final transport = VatTransport()
        ..currentJob = jobJson(status: 'completed', done: 1);
      final candidate = vatCandidateJson();
      candidate['label'] =
          'Atelier synthétique des spécialités et produits de la vallée — adresse publique très longue';
      candidate['legal_name'] = 'Atelier synthétique ' * 8;
      transport.proposals = [vatProposalJson(candidate)];
      final rows = {
        1: row(1, fields: {
          'type': 'partner',
          'name': 'Atelier de démonstration au nom très long ' * 4
        })
      };
      final s = session(transport, rows);
      addTearDown(s.dispose);
      await s.initialize();
      await host(tester, size,
          (_) => EnrichmentPanel(session: s, rows: () => rows.values.toList()));
      expect(tester.takeException(), isNull);
      final launch =
          find.widgetWithText(FilledButton, 'Rechercher sur ces 0 lignes');
      expect(tester.widget<FilledButton>(launch).onPressed, isNull);
      await tester.tap(launch);
      await tester.pumpAndSettle();
      expect(transport.calls.where((c) => c.method == 'POST'), isEmpty);
      await capture(tester, 'selection-$tag-130');
      await visibleTap(
          tester, find.byKey(const ValueKey('enrichment-scope-1')));
      await visibleTap(tester, find.text('Rechercher sur ces 1 lignes'));
      expect(transport.calls.where((c) => c.method == 'POST'), isEmpty);
      await visibleTap(tester, find.text('Retour'));
      await visibleTap(tester, find.text('Propositions / historique'));
      await visibleTap(
          tester, find.byKey(const ValueKey('proposal-$proposalId')));
      await capture(tester, 'resultats-debut-$tag-130');
      await tester.ensureVisible(find.text('Comparer / choisir'));
      await tester.pumpAndSettle();
      await capture(tester, 'resultats-$tag-130');
      await visibleTap(tester, find.text('Comparer / choisir'));
      final apply = find.widgetWithText(FilledButton, 'Appliquer au brouillon');
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(transport.calls.where((c) => c.path.endsWith('/apply')), isEmpty);
      await capture(tester, 'revue-avant-$tag-130');
      await tester.ensureVisible(find.byKey(const ValueKey('vat-section')));
      await tester.pumpAndSettle();
      expect(tester.getRect(apply).bottom, lessThan(size.height));
      await capture(tester, 'revue-tva-$tag-130');
      await visibleTap(tester, find.byKey(const ValueKey('vat-choice')));
      expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);
      transport.applyError = {'code': 'ENRICHMENT_VERSION_CONFLICT'};
      await visibleTap(tester, apply);
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);
      await tester.ensureVisible(find.textContaining('Relisez').last);
      await tester.pumpAndSettle();
      await capture(tester, 'erreur-$tag-130');
      expect(tester.takeException(), isNull);
      expect(transport.calls.where((c) => c.path.endsWith('/apply')).length, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ui research form, keyboard, busy and close $tag at 130%',
        (tester) async {
      final transport = research.ResearchTransport()
        ..currentJob = jobJson(status: 'completed');
      final rows = {
        1: row(1, fields: {'type': 'partner', ...research.criteriaJson()})
      };
      final s = session(transport, rows);
      addTearDown(s.dispose);
      await s.initialize();
      await s.resume();
      final p = EnrichmentProposal.fromJson(
          proposalJson(state: 'provider_unavailable', candidates: []));
      final form = ResearchUseCase(s, p, () => true);
      await host(tester, size, (_) => ResearchForm(session: form));
      expect(find.byType(TextField), findsNWidgets(6));
      expect(transport.posts, 0);
      await capture(tester, 'formulaire-$tag-130');
      final zip = find.byKey(const ValueKey('research-zip'));
      await tester.ensureVisible(zip);
      await tester.enterText(zip, '4000');
      await visibleTap(tester, find.text('Relancer la recherche'));
      expect(find.byKey(const ValueKey('research-error')), findsOneWidget);
      expect(transport.posts, 0);
      await tester.ensureVisible(zip);
      await tester.enterText(zip, '04000');
      tester.view.viewInsets =
          FakeViewPadding(bottom: size.width < 500 ? 300 : 200);
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(FilledButton, 'Relancer la recherche');
      expect(tester.getRect(submit).bottom,
          lessThanOrEqualTo(size.height - tester.view.viewInsets.bottom));
      transport.pendingStart = Completer<EnrichmentResponse>();
      await tester.tap(submit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(tester.widget<TextField>(zip).enabled, isFalse);
      expect(transport.posts, 1);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(form.closed, isTrue);
      transport.pendingStart!.complete(
          EnrichmentResponse(202, {'data': jobJson(status: 'queued')}));
      await tester.pumpAndSettle();
      expect(rows[1]!.version, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ui dedicated AssistantPanel and manual return $tag at 130%',
        (tester) async {
      final transport = FakeEnrichmentTransport()
        ..currentJob = jobJson(status: 'completed');
      final rows = {1: row(1)};
      final s = session(transport, rows);
      addTearDown(s.dispose);
      await s.initialize();
      s.capability = EnrichmentCapability.fromJson(
          {...research.capability(), 'chat_resolution': true});
      final p = EnrichmentProposal.fromJson(proposalJson(state: 'ambiguous'));
      final comparison = ChatComparisonUseCase(
          enrichment: s,
          reference: const ChatContextReference(
              batchId: 12,
              rowId: 1,
              proposalId: proposalId,
              expectedVersion: 1),
          proposal: p,
          tenant: transport.tenant,
          assistant: UiAssistant(),
          active: () => true);
      await host(tester, size, (_) => ChatComparison(session: comparison));
      expect(find.textContaining('Comparaison synthétique.'), findsOneWidget);
      await capture(tester, 'comparaison-$tag-130');
      expect(tester.takeException(), isNull);
      await visibleTap(tester, find.text('Retour au choix manuel'));
      expect(find.byType(ChatComparison), findsNothing);
      expect(transport.calls.where((c) => c.path.endsWith('/apply')), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'ui resize an open selection keeps the explicit choice without requests',
      (tester) async {
    final transport = FakeEnrichmentTransport()
      ..currentJob = jobJson(status: 'completed');
    final rows = {1: row(1)};
    final s = session(transport, rows);
    addTearDown(s.dispose);
    await s.initialize();
    await host(tester, const Size(1366, 768),
        (_) => EnrichmentPanel(session: s, rows: () => rows.values.toList()));
    await visibleTap(tester, find.byKey(const ValueKey('enrichment-scope-1')));
    for (final size in [
      const Size(1024, 768), const Size(768, 1024), const Size(390, 844),
      const Size(1366, 768),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      final launch = find.widgetWithText(FilledButton, 'Rechercher sur ces 1 lignes');
      expect(tester.widget<FilledButton>(launch).onPressed, isNotNull);
      expect(tester.getRect(launch).bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);
      expect(transport.calls.where((c) => c.method == 'POST'), isEmpty);
    }
    await visibleTap(tester, find.text('Rechercher sur ces 1 lignes'));
    expect(find.text('Lancer la recherche ?'), findsOneWidget);
    expect(transport.calls.where((c) => c.method == 'POST'), isEmpty);
    await visibleTap(tester, find.text('Retour'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ui French history and source failure remain readable on narrow view',
      (tester) async {
    final transport = FakeEnrichmentTransport()
      ..currentJob = {
        ...jobJson(status: 'completed_with_errors'),
        'error_code': 'LEASE_ATTEMPTS_EXHAUSTED',
      };
    final rows = {1: row(1)};
    final s = session(transport, rows);
    addTearDown(s.dispose);
    await s.initialize();
    await host(tester, const Size(390, 844),
        (_) => EnrichmentPanel(session: s, rows: () => rows.values.toList()));
    await visibleTap(tester, find.text('Historique des recherches'));
    await tester.ensureVisible(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    final dropdown = tester.getRect(find.byType(DropdownButton<String>));
    final label = tester.getRect(find.textContaining('Terminée, sources parfois indisponibles · ').first);
    expect(dropdown.height, greaterThanOrEqualTo(label.height),
        reason: 'le statut long et la date ne sont pas coupés à 48 px');
    await capture(tester, 'historique-390x844-130');
    expect(find.textContaining('Terminée, sources parfois indisponibles · '), findsWidgets);
    await visibleTap(tester, find.byType(DropdownButton<String>));
    expect(tester.takeException(), isNull);
    expect(transport.calls.where((c) => c.method == 'POST'), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'ui GPS agreement, keyboard focus and Escape preserve manual choice',
      (tester) async {
    final transport = FakeEnrichmentTransport()
      ..currentJob = jobJson(status: 'completed');
    final rows = {1: row(1)};
    final s = session(transport, rows);
    addTearDown(s.dispose);
    await s.initialize();
    await host(tester, const Size(390, 844),
        (_) => EnrichmentPanel(session: s, rows: () => rows.values.toList()));
    await visibleTap(tester, find.text('Propositions / historique'));
    await visibleTap(
        tester, find.byKey(const ValueKey('proposal-$proposalId')));
    await visibleTap(tester, find.text('Comparer / choisir'));
    final latitude = find.byType(Checkbox).at(4);
    await tester.ensureVisible(latitude);
    await tester.tap(latitude);
    await tester.pumpAndSettle();
    final apply = find.widgetWithText(FilledButton, 'Appliquer au brouillon');
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);
    expect(transport.calls.where((c) => c.path.endsWith('/apply')), isEmpty);
    await visibleTap(tester, find.textContaining('J’accepte des coordonnées'));
    expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNotNull);
    final nextFocus = FocusManager.instance.primaryFocus;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(FocusManager.instance.primaryFocus, isNot(same(nextFocus)));
    expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<Dialog>(),
        isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Appliquer au brouillon'), findsNothing);
    expect(transport.calls.where((c) => c.path.endsWith('/apply')), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
