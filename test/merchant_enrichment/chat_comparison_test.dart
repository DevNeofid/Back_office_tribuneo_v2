import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/chat_context_reference.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/errors/assistant_exception.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/chat_comparison_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_controller.dart';
import 'fixtures.dart';

const reference = ChatContextReference(
    batchId: 12, rowId: 1, proposalId: proposalId, expectedVersion: 1);
Json blockJson() => {
      'type': 'enrichment_candidates',
      ...reference.toJson(),
      'candidates': [
        {'id': candidateId, 'label': 'Adresse synthétique'}
      ]
    };
Response response(int status, dynamic data) => Response(
    statusCode: status,
    data: data,
    requestOptions: RequestOptions(path: '/chat'));
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeEnrichmentTransport transport;
  late EnrichmentUseCase enrichment;
  late Map<int, MerchantImportRow> rows;
  late List<({String path, dynamic body})> chatCalls;
  Completer<Response>? pending;
  int errorStatus = 0;
  String errorCode = 'CHAT_CONTEXT_STALE';
  bool scopeActive = true;
  AssistantRepository repository(ChatContextReference ref, String tenant) =>
      ApiAssistantRepository(
          enrichmentContext: ref,
          expectedTenant: tenant,
          tenantResolver: () => transport.currentTenant(),
          post: (path, body, tenant, timeout) async {
            chatCalls.add((path: path, body: body));
            if (path == 'chat/sessions')
              return response(201, {
                'data': {'id': 'a' * 32}
              });
            if (pending != null) return pending!.future;
            if (errorStatus != 0)
              return response(errorStatus, {
                'error': {
                  'details': {'code': errorCode}
                }
              });
            return response(200, {
              'data': {
                'reply': {
                  'text': 'Comparaison synthétique sans écriture',
                  'blocks': [blockJson()]
                }
              }
            });
          });
  setUp(() {
    pending = null;
    errorStatus = 0;
    errorCode = 'CHAT_CONTEXT_STALE';
    scopeActive = true;
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
    enrichment.capability = EnrichmentCapability.fromJson({
      'enabled': true,
      'registry': true,
      'geocoding': true,
      'chat_resolution': true,
      'max_rows': 2000
    });
  });
  tearDown(() => enrichment.dispose());
  ChatComparisonUseCase comparison() => ChatComparisonUseCase(
      enrichment: enrichment,
      reference: reference,
      proposal: EnrichmentProposal.fromJson(transport.proposals.first),
      tenant: transport.tenant,
      assistant: repository(reference, transport.tenant),
      active: () => scopeActive);
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EnrichmentPanel(
                session: enrichment,
                rows: () => rows.values.toList(),
                comparisonRepository: repository,
                scopeActive: () => scopeActive))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await pump(tester);
    await tester.tap(find.text('Comparer avec Néo'));
    if (pending != null) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tester.pumpAndSettle();
    }
  }

  test(
      'strict block parser ignores unknown and malformed references/candidates',
      () {
    expect(AssistantBlock.fromJson(blockJson()),
        isA<AssistantEnrichmentCandidatesBlock>());
    for (final b in [
      null,
      {1: 'bad'},
      {'type': 'unknown'},
      {...blockJson(), 'row_id': '1'},
      {...blockJson(), 'expected_version': 0},
      {...blockJson(), 'tenant': 'evil'},
      {...blockJson(), 'candidates': []},
      {
        ...blockJson(),
        'candidates': [
          {'id': '../apply', 'label': 'X'}
        ]
      },
      {
        ...blockJson(),
        'candidates': List.filled(6, {'id': candidateId, 'label': 'X'})
      }
    ]) {
      expect(AssistantBlock.fromJson(b), isNull);
    }
  });
  test(
      'context POST carries only references and preserves retry id; ordinary chat stays isolated',
      () async {
    final c = comparison();
    errorStatus = 503;
    errorCode = 'CHAT_UNAVAILABLE';
    await expectLater(c.sendMessage('a' * 32, 'Comparer'),
        throwsA(isA<AssistantException>()));
    errorStatus = 0;
    await c.sendMessage('a' * 32, 'Comparer');
    expect(chatCalls.map((c) => c.body['request_id']).toSet().length, 1);
    expect(chatCalls.first.body.keys,
        unorderedEquals(['message', 'request_id', 'enrichment_context']));
    expect(chatCalls.first.body['enrichment_context'], reference.toJson());
    expect(transport.calls, isEmpty);
  });
  test('tenant change during reply and logout reject late response', () async {
    pending = Completer<Response>();
    final c = comparison();
    final result = c.sendMessage('a' * 32, 'Comparer');
    await Future<void>.delayed(Duration.zero);
    transport.tenant = 'tribuneo_other';
    pending!.complete(response(200, {
      'data': {
        'reply': {
          'text': 'LATE',
          'blocks': [blockJson()]
        }
      }
    }));
    await expectLater(result, throwsA(isA<AssistantException>()));
    scopeActive = false;
    await expectLater(c.createSession(), throwsA(isA<AssistantException>()));
  });
  test('review refreshes and checks membership/version without writes',
      () async {
    final c = comparison();
    final b = AssistantBlock.fromJson(blockJson())
        as AssistantEnrichmentCandidatesBlock;
    final selection = await c.review(b, candidateId);
    expect(selection.candidate.id, candidateId);
    expect(transport.calls.every((c) => c.method == 'GET'), true);
    transport.proposals = [proposalJson(state: 'stale')];
    await expectLater(
        c.review(b, candidateId), throwsA(isA<AssistantException>()));
    transport.proposals = [proposalJson(state: 'ambiguous', candidates: [])];
    await expectLater(
        c.review(b, candidateId), throwsA(isA<AssistantException>()));
    rows[1] = row(1, version: 2);
    await expectLater(
        c.review(b, candidateId), throwsA(isA<AssistantException>()));
  });
  test('address-only candidate review requires the targeted research capability', () async {
    transport.proposals = [proposalJson(state: 'address_only')];
    final block = AssistantBlock.fromJson(blockJson()) as AssistantEnrichmentCandidatesBlock;
    await expectLater(comparison().review(block, candidateId), throwsA(isA<AssistantException>()));
    enrichment.capability = EnrichmentCapability.fromJson({
      'enabled': true, 'registry': true, 'geocoding': true,
      'chat_resolution': true, 'targeted_research': true, 'max_rows': 2000
    });
    final selected = await comparison().review(block, candidateId);
    expect(selected.proposal.state, 'address_only');
    expect(transport.calls.where((c) => c.path.endsWith('/apply')), isEmpty);
  });

  testWidgets(
      'button to dedicated session to block to review to explicit human apply',
      (tester) async {
    final ordinary = AssistantController(
        repository: repository(reference, transport.tenant));
    addTearDown(ordinary.dispose);
    await open(tester);
    expect(chatCalls.where((c) => c.path == 'chat/sessions').length, 1);
    expect(ordinary.messages, isEmpty);
    expect(find.textContaining('Comparaison Néo · Lot 12 · Ligne 1'),
        findsOneWidget);
    expect(transport.calls.where((c) => c.method != 'GET'), isEmpty);
    await tester.tap(find.text('Revoir ce candidat : Adresse synthétique'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Choisir :'), findsOneWidget);
    expect(transport.calls.where((c) => c.method != 'GET'), isEmpty);
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer au brouillon'));
    await tester.pumpAndSettle();
    final writes = transport.calls.where((c) => c.method != 'GET').toList();
    expect(writes.length, 1);
    expect(writes.single.path, endsWith('/apply'));
    expect(writes.single.body!['candidate_id'], candidateId);
    expect(writes.single.body!['expected_version'], 1);
    expect(writes.single.headers!['Idempotency-Key'], isNotEmpty);
    expect(
        writes.any((c) =>
            c.path.contains('/import') || c.body?['status'] == 'validated'),
        false);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'stale response removes candidate actions but keeps manual fallback',
      (tester) async {
    errorStatus = 409;
    await open(tester);
    expect(find.textContaining('Cette comparaison est devenue obsolète'),
        findsOneWidget);
    expect(find.textContaining('Revoir ce candidat'), findsNothing);
    await tester.tap(find.text('Retour au choix manuel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('proposal-$proposalId')));
    await tester.pumpAndSettle();
    expect(find.text('Comparer / choisir'), findsOneWidget);
    expect(transport.calls.where((c) => c.method != 'GET'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'close ignores late reply; reopen creates another dedicated session',
      (tester) async {
    pending = Completer<Response>();
    await open(tester);
    await tester.tap(find.text('Retour au choix manuel'));
    await tester.pumpAndSettle();
    pending!.complete(response(200, {
      'data': {
        'reply': {
          'text': 'LATE',
          'blocks': [blockJson()]
        }
      }
    }));
    pending = null;
    await tester.pumpAndSettle();
    expect(find.text('LATE'), findsNothing);
    await tester.tap(find.text('Comparer avec Néo'));
    await tester.pumpAndSettle();
    expect(chatCalls.where((c) => c.path == 'chat/sessions').length, 2);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('stale click never applies', (tester) async {
    await open(tester);
    transport.proposals = [proposalJson(state: 'applied')];
    await tester.tap(find.text('Revoir ce candidat : Adresse synthétique'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cette comparaison est devenue obsolète'),
        findsOneWidget);
    expect(transport.calls.where((c) => c.method != 'GET'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('capability absent and old API keep compare hidden',
      (tester) async {
    enrichment.capability = EnrichmentCapability.fromJson({
      'enabled': true,
      'registry': true,
      'geocoding': true,
      'max_rows': 2000
    });
    await pump(tester);
    expect(find.text('Comparer avec Néo'), findsNothing);
    expect(chatCalls, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'new conversation exits dedicated scope without replacing ordinary history',
      (tester) async {
    final ordinary = AssistantController(
        repository: repository(reference, transport.tenant));
    addTearDown(ordinary.dispose);
    await ordinary.send('Conversation ordinaire conservée');
    final before = ordinary.messages.toList();
    chatCalls.clear();
    await open(tester);
    await tester.tap(find.byTooltip('Nouvelle conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fermer et effacer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Comparaison Néo · Lot'), findsNothing);
    expect(ordinary.messages, before);
    expect(chatCalls.where((c) => c.path == 'chat/sessions').length, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'double click creates one comparison; logout prevents late publication',
      (tester) async {
    await pump(tester);
    pending = Completer<Response>();
    final button = find.widgetWithText(OutlinedButton, 'Comparer avec Néo');
    final onPressed = tester.widget<OutlinedButton>(button).onPressed!;
    onPressed();
    onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(chatCalls.where((c) => c.path == 'chat/sessions').length, 1);
    scopeActive = false;
    await tester.pump(const Duration(seconds: 1));
    pending!.complete(response(200, {
      'data': {
        'reply': {
          'text': 'LATE LOGOUT',
          'blocks': [blockJson()]
        }
      }
    }));
    pending = null;
    await tester.pumpAndSettle();
    expect(find.text('LATE LOGOUT'), findsNothing);
    expect(find.textContaining('Cette comparaison est devenue obsolète'),
        findsOneWidget);
    expect(transport.calls.where((c) => c.method != 'GET'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('old chat API refuses context without retrying ordinary chat',
      (tester) async {
    errorStatus = 400;
    errorCode = 'CHAT_BAD_INPUT';
    await open(tester);
    expect(chatCalls.where((c) => c.path.endsWith('/messages')).length, 1);
    expect(chatCalls.last.body['enrichment_context'], reference.toJson());
    expect(find.textContaining('Revoir ce candidat'), findsNothing);
    expect(find.text('Retour au choix manuel'), findsOneWidget);
    expect(transport.calls.where((c) => c.method != 'GET'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'destroying the owning button invalidates a still-open comparison',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bool show = true;
    late StateSetter updateHost;
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      updateHost = setState;
      return Scaffold(
          body: show
              ? EnrichmentButton(
                  session: enrichment,
                  rows: () => rows.values.toList(),
                  prepare: () async => true,
                  comparisonRepository: repository)
              : const SizedBox());
    })));
    await tester.pumpAndSettle();
    // initialize() uses the old-capability fixture; explicitly supply the E04 capability.
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
    updateHost(() {
      show = false;
    });
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('Cette comparaison est devenue obsolète'),
        findsOneWidget);
    expect(find.textContaining('Revoir ce candidat'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
