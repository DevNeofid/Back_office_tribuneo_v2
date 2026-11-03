import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/research_models.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/research_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/merchant_enrichment/enrichment_panel.dart';
import 'fixtures.dart';

const nextJob = '00000000-0000-4000-8000-000000000009';
Json criteriaJson() => {
      'name': 'Atelier public',
      'siret': '',
      'street': '',
      'zip': '04000',
      'city': '',
      'country': 'FR'
    };
Json capability({bool research = true, bool chat = false}) => {
      'enabled': true,
      'registry': true,
      'geocoding': true,
      'max_rows': 2000,
      'targeted_research': research,
      'chat_resolution': chat
    };
Json researchBlock() => {
      'type': 'enrichment_research',
      'batch_id': 12,
      'row_id': 1,
      'proposal_id': proposalId,
      'expected_version': 1
    };

class ResearchTransport extends FakeEnrichmentTransport {
  bool research = true, chat = false, fail = false;
  Json? metadata;
  EnrichmentResponse? researchError;
  Completer<EnrichmentResponse>? pendingStart;
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
      return EnrichmentResponse(
          200, {'data': capability(research: research, chat: chat)});
    }
    if (path.contains('enrichment-research-jobs')) {
      calls.add((
        method: method,
        path: path,
        tenant: tenant,
        body: body,
        headers: headers
      ));
      if (method == 'POST') {
        if (researchError != null) return researchError!;
        if (fail) throw TimeoutException('synthetic timeout');
        if (pendingStart != null) return pendingStart!.future;
        currentJob = {
          ...jobJson(status: 'queued', done: 0, total: 1),
          'id': nextJob
        };
        proposals = [];
        return EnrichmentResponse(202, {'data': currentJob});
      }
      if (metadata != null) return EnrichmentResponse(200, {'data': metadata});
      return const EnrichmentResponse(404, {
        'error': {
          'details': {'code': 'ENRICHMENT_NOT_FOUND'}
        }
      });
    }
    if (path.endsWith('/cancel') && currentJob['id'] == nextJob) {
      calls.add((
        method: method,
        path: path,
        tenant: tenant,
        body: body,
        headers: headers
      ));
      currentJob = {...currentJob, 'status': 'cancelled'};
      return EnrichmentResponse(200, {'data': currentJob});
    }
    return super
        .send(method, path, tenant: tenant, body: body, headers: headers);
  }

  int get posts => calls
      .where((c) =>
          c.method == 'POST' && c.path.endsWith('enrichment-research-jobs'))
      .length;
  Iterable<String> get keys => calls
      .where((c) =>
          c.method == 'POST' && c.path.endsWith('enrichment-research-jobs'))
      .map((c) => c.headers!['Idempotency-Key']!);
}

class ResearchAssistant implements AssistantRepository {
  int creates = 0;
  Json block = researchBlock();
  @override
  Future<String> createSession() async {
    creates++;
    return 'a' * 32;
  }

  @override
  Future<AssistantReply> sendMessage(String id, String message) async =>
      AssistantReply.fromJson({
        'text': 'Le fournisseur était indisponible. Précisez vos critères.',
        'blocks': [block]
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ResearchTransport transport;
  late EnrichmentUseCase enrichment;
  late Map<int, MerchantImportRow> rows;
  bool active = true;
  EnrichmentProposal proposal() => EnrichmentProposal.fromJson(
      proposalJson(state: 'provider_unavailable', candidates: []));
  ResearchUseCase form() =>
      ResearchUseCase(enrichment, proposal(), () => active);
  setUp(() async {
    active = true;
    transport = ResearchTransport()
      ..currentJob = jobJson(status: 'completed')
      ..proposals = [
        proposalJson(state: 'provider_unavailable', candidates: [])
      ];
    rows = {
      1: row(1, fields: {'type': 'partner', ...criteriaJson()})
    };
    enrichment = EnrichmentUseCase(
        repository: EnrichmentRepository(transport),
        batchId: 12,
        enabled: true,
        currentRow: (id) => rows[id],
        batchEditable: () => true,
        replaceRows: (_) => fail('Research must not replace row cells'),
        reloadRows: () async => rows.values.toList(),
        pollInterval: const Duration(hours: 1));
    await enrichment.initialize();
    await enrichment.resume();
  });
  tearDown(() => enrichment.dispose());

  test('criteria strict forms, Luhn, country, controls, URL and UTF8 budget',
      () {
    expect(ResearchCriteria(criteriaJson().cast()).error, isNull);
    expect(
        ResearchCriteria({
          ...criteriaJson().cast<String, String>(),
          'siret': '73282932000074'
        }).error,
        isNull);
    for (final delta in <Map<String, String>>[
      {'zip': '4000'},
      {'siret': '12345678901234'},
      {'country': 'BE'},
      {'name': 'https://evil.invalid'},
      {'name': 'javascript:launch'},
      {'name': 'data:text/plain,forged'},
      {'street': 'mailto:test@example.invalid'},
      {'name': '\nAtelier'},
      {'name': 'x' * 513},
      {'name': '', 'zip': '', 'city': '', 'street': ''},
      {'name': '😀' * 512, 'street': '😀' * 512, 'city': '😀' * 128}
    ]) {
      expect(
          ResearchCriteria({...criteriaJson().cast<String, String>(), ...delta})
              .error,
          isNotNull);
    }
    expect(() => ResearchCriteria.fromJson({...criteriaJson(), 'city': null}),
        throwsA(isA<EnrichmentException>()));
  });
  test('capability absent/off and old API prevent any targeted POST', () async {
    for (final value in [null, false]) {
      enrichment.capability = EnrichmentCapability.fromJson(
          {...capability(), 'targeted_research': value});
      expect(enrichment.canResearch(proposal()), isFalse);
      expect(
          await enrichment.research(
              proposal(),
              ResearchCriteria(criteriaJson().cast()),
              transport.tenant,
              () => true),
          isFalse);
    }
    transport.oldApi = true;
    transport.research = false;
    await enrichment.initialize();
    expect(transport.posts, 0);
  });
  test('load reads metadata, no POST, fallback only on 404', () async {
    final original = await form().load();
    expect(original.values['zip'], '04000');
    expect(transport.posts, 0);
    transport.metadata = {
      'job': jobJson(status: 'completed'),
      'row_id': 1,
      'base_version': 1,
      'source_proposal_id': proposalId,
      'criteria': {...criteriaJson(), 'city': 'Digne-les-Bains'}
    };
    final reload = await form().load();
    expect(reload.values['city'], 'Digne-les-Bains');
    expect(transport.posts, 0);
    transport.metadata!['row_id'] = 2;
    await expectLater(form().load(), throwsA(isA<EnrichmentException>()));
  });
  test('timeout retains same key, changed body gets a new key', () async {
    transport.fail = true;
    final f = form();
    await f.load();
    final c = ResearchCriteria(criteriaJson().cast());
    expect(await f.confirm(c), isFalse);
    expect(await f.confirm(c), isFalse);
    expect(transport.keys.toSet().length, 1);
    expect(
        await f.confirm(ResearchCriteria(
            {...criteriaJson().cast<String, String>(), 'city': 'Digne'})),
        isFalse);
    expect(transport.keys.toSet().length, 2);
  });
  test(
      'double click only one POST, result enters existing progression, no row writes',
      () async {
    final f = form();
    await f.load();
    transport.pendingStart = Completer();
    final a = f.confirm(ResearchCriteria(criteriaJson().cast()));
    await Future<void>.delayed(Duration.zero);
    expect(await f.confirm(ResearchCriteria(criteriaJson().cast())), isFalse);
    expect(transport.posts, 1);
    transport.currentJob = {
      ...jobJson(status: 'running', total: 1),
      'id': nextJob
    };
    transport.proposals = [];
    transport.pendingStart!
        .complete(EnrichmentResponse(202, {'data': transport.currentJob}));
    expect(await a, isTrue);
    expect(enrichment.job!.id, nextJob);
    expect(enrichment.paused, isFalse);
    expect(rows[1]!.version, 1);
    expect(transport.calls.where((c) => c.path.contains('/apply')), isEmpty);
  });
  test(
      'close, tenant/logout, version change and pause discard late targeted response',
      () async {
    for (final variant in ['close', 'tenant', 'logout', 'version', 'pause']) {
      active = true;
      transport.tenant = 'synthetic_tenant';
      rows[1] = row(1, fields: {'type': 'partner', ...criteriaJson()});
      final f = form();
      await f.load();
      transport.pendingStart = Completer();
      final operation = f.confirm(ResearchCriteria(criteriaJson().cast()));
      await Future<void>.delayed(Duration.zero);
      if (variant == 'close') f.closed = true;
      if (variant == 'tenant') transport.tenant = 'other';
      if (variant == 'logout') transport.tenant = '';
      if (variant == 'version') rows[1] = row(1, version: 2);
      if (variant == 'pause') enrichment.pause();
      transport.pendingStart!.complete(EnrichmentResponse(202, {
        'data': {...jobJson(total: 1), 'id': nextJob}
      }));
      expect(await operation, isFalse, reason: variant);
      expect(enrichment.job!.id, jobId);
      transport.pendingStart = null;
    }
  });
  test('block parsing rejects extra model criteria and wrong primitive types',
      () {
    expect(AssistantBlock.fromJson(researchBlock()),
        isA<AssistantEnrichmentResearchBlock>());
    for (final b in [
      {...researchBlock(), 'search': criteriaJson()},
      {...researchBlock(), 'row_id': '1'},
      {...researchBlock(), 'expected_version': 0}
    ]) {
      expect(AssistantBlock.fromJson(b), isNull);
    }
  });
  test(
      'old targeted endpoint, disabled flag, rate limit and concurrent job return real refusal',
      () async {
    for (final refusal in [
      (404, 'ENRICHMENT_NOT_FOUND'),
      (503, 'ENRICHMENT_RESEARCH_DISABLED'),
      (429, 'ENRICHMENT_RESEARCH_RATE_LIMITED'),
      (409, 'ENRICHMENT_ALREADY_RUNNING')
    ]) {
      transport.researchError = EnrichmentResponse(refusal.$1, {
        'error': {
          'details': {'code': refusal.$2}
        }
      });
      final f = form();
      await f.load();
      expect(await f.confirm(ResearchCriteria(criteriaJson().cast())), isFalse);
      expect(enrichment.job!.id, jobId);
      expect(enrichment.canResearch(proposal()), isTrue);
      expect(enrichment.message, isNotEmpty);
    }
  });
  test('matched allows manual research; terminal states and CAS forbid POST',
      () async {
    expect(
        enrichment.canResearch(
            EnrichmentProposal.fromJson(proposalJson(state: 'matched'))),
        isTrue);
    for (final state in ['applied', 'skipped', 'stale']) {
      expect(
          enrichment.canResearch(
              EnrichmentProposal.fromJson(proposalJson(state: state))),
          isFalse);
    }
    transport.researchError = const EnrichmentResponse(409, {
      'error': {
        'details': {'code': 'ENRICHMENT_VERSION_CONFLICT'}
      }
    });
    final f = form();
    await f.load();
    expect(await f.confirm(ResearchCriteria(criteriaJson().cast())), isFalse);
    expect(enrichment.canResearch(proposal()), isFalse);
    expect(transport.calls.where((c) => c.path.contains('/apply')), isEmpty);
  });
  test('targeted job uses existing cancel and history resume', () async {
    final f = form();
    await f.load();
    expect(await f.confirm(ResearchCriteria(criteriaJson().cast())), isTrue);
    await enrichment.cancel();
    expect(enrichment.job!.status, 'cancelled');
    expect(enrichment.job!.id, nextJob);
    await enrichment.resume(jobId: nextJob);
    expect(enrichment.job!.id, nextJob);
    expect(transport.posts, 1);
  });

  Future<void> panel(WidgetTester tester,
      {ResearchAssistant? assistant}) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EnrichmentPanel(
                session: enrichment,
                rows: () => rows.values.toList(),
                comparisonRepository: assistant == null
                    ? null
                    : (ref, _) => assistant
                      ..block = {
                        'type': 'enrichment_research',
                        ...ref.toJson()
                      }))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Propositions / historique'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'real panel -> shared form -> explicit confirmation -> POST -> progression -> results',
      (tester) async {
    await panel(tester);
    await tester.tap(find.text('Préciser la recherche'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('research-name')), findsOneWidget);
    expect(transport.posts, 0);
    await tester.enterText(find.byKey(const ValueKey('research-zip')), 'bad');
    await tester.tap(find.text('Relancer la recherche'));
    await tester.pumpAndSettle();
    expect(transport.posts, 0);
    await tester.enterText(find.byKey(const ValueKey('research-zip')), '04000');
    await tester.tap(find.text('Relancer la recherche'));
    await tester.pumpAndSettle();
    expect(transport.posts, 1);
    expect(enrichment.job!.id, nextJob);
    expect(find.textContaining('En attente'), findsWidgets);
    transport.currentJob = {
      ...jobJson(status: 'completed', total: 1),
      'id': nextJob
    };
    transport.proposals = [
      {...proposalJson(), 'job_id': nextJob}
    ];
    await enrichment.readPage(0);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('proposal-$proposalId')), findsOneWidget);
    expect(transport.calls.where((c) => c.path.contains('/apply')), isEmpty);
  });
  testWidgets(
      'Neo zero candidates -> server block -> SAME form -> confirmation, fresh next comparison',
      (tester) async {
    transport.chat = true;
    await enrichment.initialize();
    final assistant = ResearchAssistant();
    await panel(tester, assistant: assistant);
    await tester.tap(find.text('Comparer avec Néo'));
    await tester.pumpAndSettle();
    expect(assistant.creates, 1);
    expect(transport.posts, 0);
    await tester.tap(find.text('Préciser la recherche').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('research-name')), findsOneWidget);
    expect(transport.posts, 0);
    await tester.tap(find.text('Relancer la recherche'));
    await tester.pumpAndSettle();
    expect(transport.posts, 1);
    expect(find.text('Retour au choix manuel'), findsNothing);
    expect(transport.calls.where((c) => c.path.contains('/apply')), isEmpty);
    transport.currentJob = {
      ...jobJson(status: 'completed', total: 1),
      'id': nextJob
    };
    transport.proposals = [
      {
        ...proposalJson(state: 'not_found', candidates: []),
        'job_id': nextJob,
        'id': '00000000-0000-4000-8000-000000000008'
      }
    ];
    await enrichment.readPage(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer avec Néo'));
    await tester.pumpAndSettle();
    expect(assistant.creates, 2);
    expect(transport.posts, 1);
  });
  testWidgets(
      'closing the form immediately ignores a response arriving during the close transition',
      (tester) async {
    await panel(tester);
    await tester.tap(find.text('Préciser la recherche'));
    await tester.pumpAndSettle();
    transport.pendingStart = Completer();
    await tester.tap(find.text('Relancer la recherche'));
    await tester.pump();
    await tester.tap(find.text('Fermer').last);
    await tester.pump();
    transport.pendingStart!.complete(EnrichmentResponse(202, {
      'data': {...jobJson(total: 1), 'id': nextJob}
    }));
    await tester.pumpAndSettle();
    expect(enrichment.job!.id, jobId);
    expect(transport.posts, 1);
  });
  testWidgets('historical metadata is readable on a stale row after reopening',
      (tester) async {
    rows[1] = row(1, version: 2);
    transport.metadata = {
      'job': jobJson(status: 'completed'),
      'row_id': 1,
      'base_version': 1,
      'source_proposal_id': proposalId,
      'criteria': {...criteriaJson(), 'city': 'HISTORIQUE_SYNTHETIQUE'}
    };
    await panel(tester);
    expect(find.byKey(const ValueKey('research-metadata')), findsOneWidget);
    expect(find.textContaining('HISTORIQUE_SYNTHETIQUE'), findsOneWidget);
    final text = tester.widget<SelectableText>(
        find.byKey(const ValueKey('research-metadata'))).data!;
    expect(text, contains('Nom : Atelier public'));
    expect(text, contains('Adresse : —'));
    expect(text, contains('Code postal : 04000'));
    expect(text, contains('Ville : HISTORIQUE_SYNTHETIQUE'));
    expect(text, isNot(contains('Version')));
    expect(text, isNot(contains('zip :')));
    expect(find.text('Préciser la recherche'), findsNothing);
    expect(transport.posts, 0);
  });
}
