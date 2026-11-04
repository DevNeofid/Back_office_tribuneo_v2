import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/chat_context_reference.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_controller.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_docked_panel.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_overlay.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/chat_comparison.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'fixtures.dart';

/// « Comparer avec Néo » dans `MySinglePage` : la comparaison s'ouvre dans le
/// bouton flottant de Néo au lieu d'un dialogue posé sur le dialogue
/// « Compléter les informations ».

class _MemoryPreferences implements AssistantPreferences {
  @override
  Future<bool> readHidden() async => false;
  @override
  Future<void> saveHidden(bool hidden) async {}
  @override
  Future<bool> readOpenedOnce() async => true;
  @override
  Future<void> saveOpenedOnce() async {}
}

const reference = ChatContextReference(
    batchId: 12, rowId: 1, proposalId: proposalId, expectedVersion: 1);

Response response(int status, dynamic data) => Response(
    statusCode: status,
    data: data,
    requestOptions: RequestOptions(path: '/chat'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeEnrichmentTransport transport;
  late EnrichmentUseCase enrichment;
  late Map<int, MerchantImportRow> rows;
  late List<String> chatCalls;

  AssistantRepository repository(ChatContextReference ref, String tenant) =>
      ApiAssistantRepository(
          enrichmentContext: ref,
          expectedTenant: tenant,
          tenantResolver: () => transport.currentTenant(),
          post: (path, body, tenant, timeout) async {
            chatCalls.add(path);
            if (path == 'chat/sessions') {
              return response(201, {
                'data': {'id': 'a' * 32}
              });
            }
            return response(200, {
              'data': {
                'reply': {
                  'text': 'Comparaison synthétique sans écriture',
                  'blocks': [
                    {
                      'type': 'enrichment_candidates',
                      ...ref.toJson(),
                      'candidates': [
                        {'id': candidateId, 'label': 'Adresse synthétique'}
                      ]
                    }
                  ]
                }
              }
            });
          });

  setUp(() {
    chatCalls = [];
    transport = FakeEnrichmentTransport()
      ..tenant = 'tribuneo_cci04'
      ..currentJob = jobJson(status: 'completed')
      ..proposals = [proposalJson(state: 'ambiguous')];
    rows = {1: row(1)};
    enrichment = EnrichmentUseCase(
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
  tearDown(() => enrichment.dispose());

  /// Grille (bouton) + overlay de Néo, comme dans `MySinglePage`.
  Future<
      ({
        AssistantDockedPanel docked,
        AssistantController ordinary,
        void Function() hideGrid
      })> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final docked = AssistantDockedPanel();
    addTearDown(docked.dispose);
    final ordinary = AssistantController(
        repository: repository(reference, transport.tenant),
        preferences: _MemoryPreferences());
    addTearDown(ordinary.dispose);
    await ordinary.load();
    bool showGrid = true;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
        // Sans animation : le lanceur de Néo rebondit en boucle sinon.
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: ChangeNotifierProvider<AssistantController>.value(
            value: ordinary,
            child: AssistantDockedScope(
                docked: docked,
                child: Scaffold(body: StatefulBuilder(builder: (context, set) {
                  update = set;
                  return Stack(children: [
                    if (showGrid)
                      Align(
                          alignment: Alignment.topLeft,
                          child: EnrichmentButton(
                              session: enrichment,
                              rows: () => rows.values.toList(),
                              prepare: () async => true,
                              comparisonRepository: repository)),
                    Positioned.fill(child: AssistantOverlay(docked: docked)),
                  ]);
                }))))));
    await tester.pumpAndSettle();
    enrichment.capability = EnrichmentCapability.fromJson({
      'enabled': true,
      'registry': true,
      'geocoding': true,
      'chat_resolution': true,
      'max_rows': 2000
    });
    await tester.tap(find.text('Compléter les informations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer avec Néo'));
    await tester.pumpAndSettle();
    return (
      docked: docked,
      ordinary: ordinary,
      hideGrid: () => update(() => showGrid = false)
    );
  }

  testWidgets('compare opens in the Néo floating panel, not a stacked dialog',
      (tester) async {
    final h = await pump(tester);
    // Le dialogue « Compléter les informations » est fermé, aucun dialogue
    // de comparaison n'est ouvert.
    expect(find.byType(EnrichmentPanel), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(h.docked.panel, isA<ChatComparison>());
    expect(find.text('Néo · Comparaison'), findsOneWidget);
    expect(find.textContaining('Comparaison Néo · Lot 12 · Ligne 1'),
        findsOneWidget);
    expect(find.text('Comparaison synthétique sans écriture'), findsOneWidget);
    // La conversation ordinaire n'est pas touchée.
    expect(h.ordinary.messages, isEmpty);
    expect(chatCalls.where((c) => c == 'chat/sessions').length, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('chosen candidate is reviewed, applied, then the panel reopens',
      (tester) async {
    final h = await pump(tester);
    await tester.tap(find.text('Revoir ce candidat : Adresse synthétique'));
    await tester.pumpAndSettle();
    expect(h.docked.panel, isNull);
    expect(find.textContaining('Choisir :'), findsOneWidget);
    expect(transport.calls.where((c) => c.method != 'GET'), isEmpty);
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer au brouillon'));
    await tester.pumpAndSettle();
    final writes = transport.calls.where((c) => c.method != 'GET').toList();
    expect(writes.length, 1);
    expect(writes.single.path, endsWith('/apply'));
    expect(find.byType(EnrichmentPanel), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('back to manual choice closes Néo and reopens the panel',
      (tester) async {
    final h = await pump(tester);
    await tester.tap(find.text('Retour au choix manuel'));
    await tester.pumpAndSettle();
    expect(h.docked.panel, isNull);
    expect(find.text('Néo · Comparaison'), findsNothing);
    expect(find.byType(EnrichmentPanel), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('minimizing Néo ends the comparison without reopening anything',
      (tester) async {
    final h = await pump(tester);
    await tester.tap(find.byTooltip('Réduire'));
    await tester.pumpAndSettle();
    expect(h.docked.panel, isNull);
    expect(find.byType(EnrichmentPanel), findsNothing);
    expect(find.text('Compléter les informations'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving the import screen closes the docked comparison',
      (tester) async {
    final h = await pump(tester);
    h.hideGrid();
    await tester.pumpAndSettle();
    expect(h.docked.panel, isNull);
    expect(find.text('Néo · Comparaison'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
