import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'fixtures.dart';

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('E02_CAPTURE_UI')) {
      final font = FontLoader('E02Segoe')
        ..addFont(Future.value(ByteData.sublistView(
            File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync())));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(File(
                'C:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
            .readAsBytesSync())));
      await icons.load();
    }
  });
  late FakeEnrichmentTransport transport;
  late Map<int, MerchantImportRow> rows;
  late EnrichmentUseCase session;
  setUp(() {
    transport = FakeEnrichmentTransport()
      ..currentJob = jobJson(status: 'completed', done: 2);
    rows = {
      1: row(1),
      2: row(2, status: 'validated'),
      3: row(3, fields: {'name': 'Client Synthétique', 'type': 'customer'})
    };
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
    await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('capture'),
        child: MaterialApp(
            theme: ThemeData(
                fontFamily: const bool.fromEnvironment('E02_CAPTURE_UI')
                    ? 'E02Segoe'
                    : null),
            home: Scaffold(
                body: EnrichmentButton(
                    session: session,
                    rows: () => rows.values.toList(),
                    prepare: () async => true)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compléter les informations'));
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('E02_CAPTURE_UI')) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('capture')));
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('docs/merchant-enrichment/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
      'explicit selection excludes validated and customer rows; launch confirmation',
      (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('enrichment-scope-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('enrichment-scope-2')), findsNothing);
    expect(find.byKey(const ValueKey('enrichment-scope-3')), findsNothing);
    expect(find.text('Rechercher sur ces 0 lignes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('enrichment-scope-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechercher sur ces 1 lignes'));
    await tester.pumpAndSettle();
    expect(find.text('Lancer la recherche ?'), findsOneWidget);
    expect(transport.calls.any((c) => c.method == 'POST'), false);
    await capture(tester, 'ui-launch');
    await tester.tap(find.text('Lancer'));
    await tester.pumpAndSettle();
    expect(transport.calls.where((c) => c.method == 'POST').length, 1);
    expect(rows[1]!.version, 1);
    expect(rows[2]!.isValidated, true);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'select all checks only eligible rows, a second click clears; no request',
      (tester) async {
    rows[4] = row(4);
    rows[5] = row(5);
    await pump(tester);
    final all = find.byKey(const ValueKey('enrichment-select-all'));
    expect(tester.widget<CheckboxListTile>(all).value, false);
    await tester.tap(all);
    await tester.pumpAndSettle();
    // Lignes 1, 4 et 5 ; jamais la ligne validée ni la ligne client.
    expect(find.text('Rechercher sur ces 3 lignes'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(all).value, true);
    for (final id in [1, 4, 5]) {
      expect(
          tester
              .widget<CheckboxListTile>(
                  find.byKey(ValueKey('enrichment-scope-$id')))
              .value,
          true);
    }
    // Une ligne décochée : sélection partielle.
    await tester.tap(find.byKey(const ValueKey('enrichment-scope-4')));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(all).value, isNull);
    await tester.tap(all);
    await tester.pumpAndSettle();
    expect(find.text('Rechercher sur ces 3 lignes'), findsOneWidget);
    await tester.tap(all);
    await tester.pumpAndSettle();
    expect(find.text('Rechercher sur ces 0 lignes'), findsOneWidget);
    expect(transport.calls.any((c) => c.method == 'POST'), false);
    // Historique : la liste déroulante seule, sans pagination.
    expect(find.text('Recherches précédentes'), findsNothing);
    expect(find.text('Recherches suivantes'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'candidate requires manual choice; sources and before/after; explicit apply',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('proposal-$proposalId')));
    await tester.pumpAndSettle();
    await capture(tester, 'ui-proposals');
    await tester.tap(find.text('Comparer / choisir'));
    await tester.pumpAndSettle();
    expect(find.text('Avant'), findsOneWidget);
    // Sources folded by default; the full URL is the link tooltip.
    await tester.ensureVisible(find.textContaining('Sources ('));
    await tester.tap(find.textContaining('Sources ('));
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate((w) =>
            w is Tooltip &&
            (w.message ?? '').contains('https://example.invalid/synthetic-source')),
        findsWidgets);
    final apply = find.widgetWithText(FilledButton, 'Appliquer au brouillon');
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);
    // No candidate/field is selected implicitly, including an unambiguous result.
    final checkboxes = find.byType(Checkbox);
    await tester.ensureVisible(checkboxes.at(2));
    await tester.pumpAndSettle();
    await tester.tap(checkboxes.at(2));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);
    await capture(tester, 'ui-compare');
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(rows[1]!.textOf('city'), 'Ville Synthétique');
    expect(rows[1]!.isPending, true);
    expect(
        find.text('Choisir : 12 rue du Test, Ville Synthétique'), findsNothing);
    expect(transport.calls.any((c) => c.path.endsWith('/import')), false);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('closing stops reading, reopening consults persisted jobs',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(session.paused, true);
    final before = transport.calls.length;
    await tester.pump(const Duration(minutes: 10));
    expect(transport.calls.length, before);
    await tester.tap(find.text('Compléter les informations'));
    await tester.pumpAndSettle();
    expect(transport.calls.length, greaterThan(before));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'ambiguous candidates remain manual and coordinates need explicit precision consent',
      (tester) async {
    transport.proposals = [
      proposalJson(state: 'ambiguous', candidates: [
        candidateJson(),
        {
          ...candidateJson(id: '00000000-0000-4000-8000-000000000004'),
          'label': 'Autre adresse synthétique'
        }
      ])
    ];
    await pump(tester);
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Choix manuel requis'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('proposal-$proposalId')));
    await tester.pumpAndSettle();
    expect(find.text('Comparer / choisir'), findsNWidgets(2));
    expect(transport.calls.any((c) => c.path.endsWith('/apply')), false);
    await tester.ensureVisible(find.text('Comparer / choisir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer / choisir').last);
    await tester.pumpAndSettle();
    expect(find.text('Choisir : Autre adresse synthétique'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).at(4));
    await tester.pumpAndSettle();
    final apply = find.widgetWithText(FilledButton, 'Appliquer au brouillon');
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);
    final consent = find.textContaining('J’accepte des coordonnées');
    await tester.ensureVisible(consent);
    await tester.pumpAndSettle();
    await tester.tap(consent);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    final write = transport.calls.singleWhere((c) => c.path.endsWith('/apply'));
    expect(write.body!['candidate_id'], '00000000-0000-4000-8000-000000000004');
    expect(write.body!['fields'], ['lat', 'lng']);
    expect(write.body!['acknowledge_approximate_coordinates'], true);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'conflict refreshes and leaves comparison disabled without importing',
      (tester) async {
    transport.applyError = {'code': 'ENRICHMENT_VERSION_CONFLICT'};
    await pump(tester);
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('proposal-$proposalId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer / choisir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    final apply = find.widgetWithText(FilledButton, 'Appliquer au brouillon');
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);
    expect(find.textContaining('Relisez'), findsWidgets);
    expect(rows[1]!.version, 1);
    expect(rows[1]!.isPending, true);
    expect(transport.calls.where((c) => c.path.endsWith('/apply')).length, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
