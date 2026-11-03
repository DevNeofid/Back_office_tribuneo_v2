import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'fixtures.dart';

void main() {
  late FakeEnrichmentTransport transport;
  late Map<int, MerchantImportRow> rows;
  late EnrichmentUseCase session;
  late int refreshes;
  bool editable = true;
  EnrichmentUseCase create({bool enabled = true, int maxPolls = 100}) =>
      EnrichmentUseCase(
          repository: EnrichmentRepository(transport),
          batchId: 12,
          enabled: enabled,
          currentRow: (id) => rows[id],
          batchEditable: () => editable,
          replaceRows: (next) {
            for (final r in next) {
              if (r.version >= (rows[r.id]?.version ?? 0)) rows[r.id] = r;
            }
          },
          reloadRows: () async {
            refreshes++;
            return rows.values.toList();
          },
          pollInterval: const Duration(milliseconds: 10),
          maxPolls: maxPolls);
  setUp(() {
    editable = true;
    transport = FakeEnrichmentTransport();
    rows = {1: row(1), 2: row(2)};
    refreshes = 0;
    session = create();
  });
  tearDown(() => session.dispose());
  Future<void> ready() async {
    await session.initialize();
    await session.resume();
    session.pause();
  }

  EnrichmentProposal proposal() => EnrichmentProposal.fromJson(proposalJson());

  test('build flag defaults off; off performs no request', () async {
    expect(merchantEnrichmentEnabled, false);
    session.dispose();
    session = create(enabled: false);
    await session.initialize();
    await session.resume();
    await session.start([1]);
    expect(transport.calls, isEmpty);
  });
  test('disabled capability, old API and offline fail closed', () async {
    transport.enabled = false;
    await session.initialize();
    await session.resume();
    await session.start([1]);
    expect(session.available, false);
    expect(transport.calls.length, 1);
    transport.oldApi = true;
    await session.initialize();
    expect(session.available, false);
    transport.oldApi = false;
    transport.offline = true;
    await session.initialize();
    expect(session.message, isNotNull);
  });
  test('explicit pending partner scope; deduplication; tenant and start key',
      () async {
    await session.initialize();
    rows[2] = row(2, status: 'validated');
    await session.start([1, 2]);
    expect(transport.calls.length, 1);
    await session.start([1, 1]);
    session.pause();
    final start = transport.calls.singleWhere((c) => c.method == 'POST');
    expect(start.body, {
      'row_ids': [1],
      'mode': 'missing_only'
    });
    expect(start.tenant, 'synthetic_tenant');
    expect(start.headers!['Idempotency-Key'], isNotEmpty);
    expect(rows[1]!.fields.containsKey('city'), false);
  });
  test('start double click sends one mutation', () async {
    await session.initialize();
    transport.barrier = Completer<void>();
    final first = session.start([1]);
    await Future<void>.delayed(Duration.zero);
    await session.start([1]);
    transport.barrier!.complete();
    await first;
    session.pause();
    expect(transport.calls.where((c) => c.method == 'POST').length, 1);
  });
  test('network retry retains start idempotency key', () async {
    await session.initialize();
    transport.offline = true;
    await session.start([1]);
    transport.offline = false;
    await session.start([1]);
    session.pause();
    final starts = transport.calls.where((c) => c.method == 'POST').toList();
    expect(starts[0].headers, starts[1].headers);
  });
  test('read resumes persisted job; progression never regresses', () async {
    await ready();
    expect(session.job!.id, jobId);
    transport.currentJob = jobJson(done: 2);
    await session.readPage(0);
    transport.currentJob = jobJson(done: 0);
    await session.readPage(0);
    expect(session.job!.done, 2);
    await session.resume();
    session.pause();
    expect(session.job!.done, 2);
    expect(rows[1]!.version, 1);
  });
  test('pagination uses frozen envelope and requested offset', () async {
    transport.proposals = List.generate(
        51,
        (i) => {
              ...proposalJson(rowId: i + 1),
              'id':
                  '00000000-0000-4000-8000-${(i + 10).toString().padLeft(12, '0')}'
            });
    await ready();
    expect(session.page!.items.length, 50);
    expect(session.page!.hasNext, true);
    await session.readPage(50);
    expect(session.page!.offset, 50);
    expect(session.page!.items.single.rowId, 51);
    expect(session.page!.hasNext, false);
  });
  test('cancel only the research; proposals remain; reopen reads durable state',
      () async {
    await ready();
    await session.cancel();
    expect(session.job!.status, 'cancelled');
    expect(session.page!.items, isNotEmpty);
    expect(rows[1]!.isPending, true);
    expect(transport.calls.where((c) => c.path.endsWith('/cancel')).length, 1);
    await session.resume();
    session.pause();
    expect(session.job!.status, 'cancelled');
  });
  test('apply sends chosen fields only, updates row + related, stays pending',
      () async {
    await ready();
    final p = proposal();
    expect(await session.apply(p, p.candidates.single, {'city'}), true);
    expect(rows[1]!.textOf('city'), 'Ville Synthétique');
    expect(rows[1]!.isPending, true);
    expect(rows[2]!.version, 2);
    final apply = transport.calls.singleWhere((c) => c.path.endsWith('/apply'));
    expect(apply.body, {
      'candidate_id': candidateId,
      'expected_version': 1,
      'fields': ['city'],
      'acknowledge_approximate_coordinates': false
    });
    expect(
        transport.calls
            .any((c) => c.path.endsWith('/import') || c.method == 'PATCH'),
        false);
  });
  test(
      'human field, numeric zero, stale, TVA and mixed coordinate pair are protected',
      () async {
    await ready();
    final p = proposal(), c = p.candidates.single;
    rows[1] = row(1, fields: {
      'name': 'Humain',
      'type': 'partner',
      'city': 'Saisie',
      'lat': 0
    });
    expect(session.applicable(p, c), isNot(contains('city')));
    expect(session.applicable(p, c), isNot(contains('lat')));
    expect(session.applicable(p, c), isNot(contains('lng')));
    expect(await session.apply(p, c, {'intracommunity_vat_number'}), false);
    rows[1] = row(1, version: 2);
    expect(await session.apply(p, c, {'city'}), false);
    expect(transport.calls.any((c) => c.path.endsWith('/apply')), false);
  });
  test('approximate coordinates require acknowledgement, pair applies together',
      () async {
    await ready();
    final p = proposal(), c = p.candidates.single;
    expect(await session.apply(p, c, {'lat', 'lng'}), false);
    expect(await session.apply(p, c, {'lat'}, acknowledge: true), false);
    expect(await session.apply(p, c, {'lat', 'lng'}, acknowledge: true), true);
  });
  test('identity conflict is blocked locally even for address fields',
      () async {
    await ready();
    rows[1] = row(1, fields: {'type': 'partner', 'siret': '00000000000001'});
    final p = EnrichmentProposal.fromJson(proposalJson(candidates: [
      {...candidateJson(), 'kind': 'establishment', 'siret': '00000000000002'}
    ]));
    expect(session.applicable(p, p.candidates.single), isEmpty);
  });
  test('address-only candidate does not substitute a different identity',
      () async {
    await ready();
    rows[1] = row(1, fields: {'type': 'partner', 'siret': '00000000000001'});
    final p = proposal();
    expect(session.applicable(p, p.candidates.single), contains('city'));
    expect(
        session.applicable(p, p.candidates.single), isNot(contains('siret')));
  });
  test('capability refresh failure removes a previously available capability',
      () async {
    await session.initialize();
    expect(session.available, true);
    transport.oldApi = true;
    await session.initialize();
    expect(session.available, false);
  });
  test('server precision refusal and unavailability keep draft unchanged',
      () async {
    await ready();
    final p = proposal();
    transport.applyErrorStatus = 422;
    transport.applyError = {
      'code': 'ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED'
    };
    expect(await session.apply(p, p.candidates.single, {'city'}), false);
    expect(session.message, contains('précision'));
    transport.applyErrorStatus = 503;
    transport.applyError = {'code': 'ENRICHMENT_UNAVAILABLE'};
    expect(await session.apply(p, p.candidates.single, {'city'}), false);
    expect(rows[1]!.version, 1);
  });
  test(
      'batch and row status changes block writes; unsourced values cannot apply',
      () async {
    await ready();
    final p = proposal();
    editable = false;
    expect(await session.apply(p, p.candidates.single, {'city'}), false);
    editable = true;
    for (final status in ['validated', 'imported', 'rejected']) {
      rows[1] = row(1, status: status);
      expect(await session.apply(p, p.candidates.single, {'city'}), false);
    }
    rows[1] = row(1);
    final unsourced = EnrichmentProposal.fromJson(proposalJson(candidates: [
      {...candidateJson(), 'sources': <String, dynamic>{}}
    ]));
    expect(session.applicable(unsourced, unsourced.candidates.single), isEmpty);
  });
  test('conflicting proposal is disabled after refresh', () async {
    await ready();
    final p = proposal();
    transport.applyError = {'code': 'ENRICHMENT_ADDRESS_CONTEXT_CONFLICT'};
    await session.apply(p, p.candidates.single, {'city'});
    expect(session.applicable(p, p.candidates.single), isEmpty);
  });
  test('conflict refreshes once without replaying apply', () async {
    await ready();
    transport.applyError = {
      'code': 'ENRICHMENT_VERSION_CONFLICT',
      'row': rowJson(1, version: 2)
    };
    final p = proposal();
    expect(await session.apply(p, p.candidates.single, {'city'}), false);
    expect(refreshes, 1);
    expect(transport.calls.where((c) => c.path.endsWith('/apply')).length, 1);
    expect(session.message, contains('Relisez'));
  });
  test('idempotency in-progress keeps apply retryable with the same key',
      () async {
    await ready();
    final p = proposal();
    transport.applyError = {'code': 'IDEMPOTENCY_REQUEST_IN_PROGRESS'};
    expect(await session.apply(p, p.candidates.single, {'city'}), false);
    expect(session.applicable(p, p.candidates.single), contains('city'));
    expect(refreshes, 0);
    transport.applyError = null;
    expect(await session.apply(p, p.candidates.single, {'city'}), true);
    final writes =
        transport.calls.where((c) => c.path.endsWith('/apply')).toList();
    expect(writes[0].headers, writes[1].headers);
  });
  test('late idempotent response older than current grid triggers reread',
      () async {
    await ready();
    transport.barrier = Completer<void>();
    final p = proposal();
    final applying = session.apply(p, p.candidates.single, {'city'});
    await Future<void>.delayed(Duration.zero);
    rows[1] = row(1, version: 4);
    transport.barrier!.complete();
    await applying;
    expect(refreshes, 1);
    expect(rows[1]!.version, 4);
  });
  test('apply double click and transient retry key', () async {
    await ready();
    transport.offline = true;
    final p = proposal();
    await session.apply(p, p.candidates.single, {'city'});
    transport.offline = false;
    transport.barrier = Completer<void>();
    final applying = session.apply(p, p.candidates.single, {'city'});
    await Future<void>.delayed(Duration.zero);
    expect(await session.apply(p, p.candidates.single, {'city'}), false);
    transport.barrier!.complete();
    await applying;
    final writes =
        transport.calls.where((c) => c.path.endsWith('/apply')).toList();
    expect(writes.length, 2);
    expect(writes[0].headers, writes[1].headers);
  });
  test('tenant change prevents write and cache reuse', () async {
    await ready();
    transport.tenant = 'other_synthetic_tenant';
    final p = proposal();
    expect(await session.apply(p, p.candidates.single, {'city'}), false);
    expect(transport.calls.any((c) => c.path.endsWith('/apply')), false);
  });
  test('paused or disposed late response cannot publish proposals', () async {
    await ready();
    session.page = null;
    transport.barrier = Completer<void>();
    final reading = session.readPage(0);
    await Future<void>.delayed(Duration.zero);
    session.pause();
    transport.barrier!.complete();
    await reading;
    expect(session.page, null);
    transport.barrier = Completer<void>();
    final next = session.readPage(0);
    await Future<void>.delayed(Duration.zero);
    session.dispose();
    transport.barrier!.complete();
    await next;
    expect(session.page, null);
    // tearDown owns a fresh instance, avoiding a second notifier disposal.
    session = create();
  });
  testWidgets('polling is bounded and stops on dispose', (tester) async {
    session.dispose();
    session = create(maxPolls: 2);
    await session.initialize();
    await session.resume();
    await tester.pump(const Duration(milliseconds: 11));
    await tester.pump(const Duration(milliseconds: 11));
    await tester.pump(const Duration(milliseconds: 11));
    expect(session.paused, true);
    final count = transport.calls.length;
    await tester.pump(const Duration(seconds: 10));
    expect(transport.calls.length, count);
    session.dispose();
    session = create();
  });
  test('malformed successful envelope is an error, never a simulated success',
      () async {
    transport.handler =
        (_, __, ___) async => const EnrichmentResponse(200, {'items': []});
    await session.initialize();
    expect(session.available, false);
    expect(session.message, isNotNull);
  });
}
