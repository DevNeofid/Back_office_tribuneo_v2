import 'dart:io';
import 'dart:ui' as ui;
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';

/// Captures du rendu réel des messages (données synthétiques, faux transport).
/// Inactif par défaut : `flutter test --dart-define=E07_CAPTURE_DIR=<dossier>`.
const _dir = String.fromEnvironment('E07_CAPTURE_DIR');

class _Transport extends FakeEnrichmentTransport {
  @override
  Future<EnrichmentResponse> send(String method, String path,
      {required String tenant,
      Json? body,
      Map<String, String>? headers}) async {
    if (path.endsWith('enrichment-capabilities')) {
      calls.add((
        method: method,
        path: path,
        tenant: tenant,
        body: body,
        headers: headers
      ));
      return const EnrichmentResponse(200, {
        'data': {
          'enabled': true,
          'registry': true,
          'geocoding': true,
          'vat': true,
          'chat_resolution': false,
          'targeted_research': true,
          'max_rows': 2000
        }
      });
    }
    if (method == 'GET' && path.contains('enrichment-research-jobs/')) {
      return const EnrichmentResponse(404, {
        'error': {
          'details': {'code': 'ENRICHMENT_NOT_FOUND'}
        }
      });
    }
    return super
        .send(method, path, tenant: tenant, body: body, headers: headers);
  }
}

void main() {
  if (_dir.isEmpty) {
    test('captures E07 désactivées (E07_CAPTURE_DIR absent)', () {});
    return;
  }
  setUpAll(() async {
    final font = FontLoader('E07Segoe')
      ..addFont(Future.value(ByteData.sublistView(
          File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync())));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(File(
              'C:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
          .readAsBytesSync())));
    await icons.load();
  });

  late _Transport transport;
  late Map<int, MerchantImportRow> rows;
  late EnrichmentUseCase session;
  setUp(() {
    transport = _Transport()
      ..currentJob = {
        ...jobJson(status: 'completed_with_errors', done: 1, total: 1),
        'error_code': null
      }
      ..proposals = [
        {
          ...proposalJson(state: 'ambiguous', candidates: [
            {
              ...candidateJson(),
              'kind': 'establishment',
              'label': 'Boulangerie Synthétique',
              'legal_name': 'SAS SYNTHÉTIQUE',
              'siren': '732829320',
              'siret': '73282932000074',
              'establishment_status': 'active',
              'match_level': 'ambiguous',
              'reason_codes': [
                'NAME_MATCH',
                'ADDRESS_NOT_CORROBORATED',
                'VAT_UNAVAILABLE',
                'SYNTHETIC_X'
              ],
              'vat_status': 'unavailable',
            },
            {
              ...candidateJson(id: '00000000-0000-4000-8000-000000000004'),
              'label': 'Autre adresse synthétique',
              'reason_codes': ['ADDRESS_FROM_ROW', 'GEOCODE_IMPRECISE'],
            }
          ]),
          'reason_codes': [
            'MULTIPLE_CANDIDATES',
            'PROVIDER_RESULTS_NOT_EXHAUSTIVE',
            'GEOCODING_RATE_LIMITED'
          ],
        }
      ];
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

  Future<void> open(WidgetTester tester, Size size, {double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await session.initialize();
    await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('capture'),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'E07Segoe'),
            home: Scaffold(
                body: EnrichmentButton(
                    session: session,
                    rows: () => rows.values.toList(),
                    prepare: () async => true)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compléter les informations'));
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('capture')));
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> proposals(WidgetTester tester) async {
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('proposal-$proposalId')));
    await tester.pumpAndSettle();
  }

  testWidgets('E07-1 propositions et raisons', (tester) async {
    await open(tester, const Size(1366, 768));
    await proposals(tester);
    await shot(tester, 'E07-1_propositions_1366x768');
  });

  testWidgets('E07-2 relecture, sources datées et TVA', (tester) async {
    await open(tester, const Size(1366, 900));
    await proposals(tester);
    await tester.tap(find.text('Comparer / choisir').first);
    await tester.pumpAndSettle();
    await shot(tester, 'E07-2_relecture_1366x900');
  });

  testWidgets('E07-3 refus serveur sur application', (tester) async {
    transport.applyError = {
      'code': 'ENRICHMENT_PROPOSAL_STALE',
      'row': rowJson(1)
    };
    await open(tester, const Size(1366, 900));
    await proposals(tester);
    await tester.ensureVisible(find.text('Comparer / choisir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer / choisir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(FilledButton, 'Appliquer au brouillon'));
    await tester.pumpAndSettle();
    await shot(tester, 'E07-3_refus_application_1366x900');
  });

  testWidgets('E07-4 erreur de job', (tester) async {
    transport.currentJob = {
      ...jobJson(status: 'failed', done: 0, total: 1),
      'error_code': 'LEASE_ATTEMPTS_EXHAUSTED'
    };
    transport.proposals = [];
    await open(tester, const Size(1366, 768));
    await shot(tester, 'E07-4_erreur_job_1366x768');
  });

  testWidgets('E07-5 formulaire de précision, erreur SIRET', (tester) async {
    await open(tester, const Size(1366, 768));
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Préciser la recherche'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('research-siret')), '12345678901234');
    await tester.tap(find.text('Relancer la recherche'));
    await tester.pumpAndSettle();
    await shot(tester, 'E07-5_formulaire_erreur_1366x768');
  });

  testWidgets('E07-6 texte agrandi 130 %', (tester) async {
    await open(tester, const Size(1366, 768), scale: 1.3);
    await proposals(tester);
    await shot(tester, 'E07-6_propositions_texte130_1366x768');
  });
}
