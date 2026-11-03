// Bout en bout LOCAL : client BO réel (EnrichmentRepository, EnrichmentUseCase, modèles,
// MerchantImportRow.fromJson) contre la vraie API servie par la pile jetable de l'API
// (scripts/merchant-enrichment/e2e/local-stack.sh du dépôt API : MySQL/Redis jetables, worker
// réel, fournisseurs simulés sur réseau interne). Données synthétiques uniquement.
//
// Lancement explicite, hors suite par défaut (nom sans `_test`) :
//   flutter test --no-pub test/merchant_enrichment/live_local_api.dart --dart-define=ENRICHMENT_E2E=http://127.0.0.1
// :18080 flag allumé (tribuneo_cci04), :18081 flag absent, :18082 API sans enrichissement.
import 'dart:convert';
import 'dart:io';

import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

const _host = String.fromEnvironment('ENRICHMENT_E2E');
const _tenant = 'tribuneo_cci04';

class _Raw {
  final int status;
  final dynamic body;
  final bool replayed;
  const _Raw(this.status, this.body, this.replayed);
}

/// Même forme que TribuneoEnrichmentTransport (chemins relatifs, X-Tenant, session humaine,
/// POST JSON `{}` sans corps), sur HTTP réel avec un jeton porteur de test.
class _LocalApi implements EnrichmentTransport {
  final String base;
  final String tenant;
  String token = '';
  final List<String> calls = [];
  _Raw? last;
  _LocalApi(int port, {this.tenant = _tenant}) : base = '$_host:$port';

  Future<void> login() async {
    final r = await raw('POST', 'auth/login',
        body: {
          'username': 'admin-cci04-test',
          'password': 'synthetic-test-password'
        },
        auth: false);
    expect(r.status, 200, reason: '${r.body}');
    token = r.body['data']['access_token'] as String;
  }

  @override
  Future<String> currentTenant() async => tenant;

  @override
  Future<EnrichmentResponse> send(String method, String path,
      {required String tenant,
      Json? body,
      Map<String, String>? headers}) async {
    calls.add('$method $path');
    final r = await raw(method, path,
        tenant: tenant,
        body: method == 'GET' ? null : (body ?? {}),
        headers: headers);
    last = r;
    return EnrichmentResponse(r.status, r.body);
  }

  Future<_Raw> raw(String method, String path,
      {String? tenant,
      Object? body,
      Map<String, String>? headers,
      bool auth = true}) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, Uri.parse('$base/$path'));
      request.headers.set('Content-Type', 'application/json');
      if (auth) request.headers.set('Authorization', 'Bearer $token');
      if (tenant != null) request.headers.set('X-Tenant', tenant);
      headers?.forEach(request.headers.set);
      if (body != null) request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close();
      final text = await utf8.decodeStream(response);
      return _Raw(response.statusCode, text.isEmpty ? null : jsonDecode(text),
          response.headers.value('idempotent-replayed') == 'true');
    } finally {
      client.close();
    }
  }
}

String _siret(String siren, String nic) {
  bool luhn(String digits) {
    var sum = 0;
    var double = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = int.parse(digits[i]);
      if (double) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      double = !double;
    }
    return sum % 10 == 0;
  }

  for (var check = 0; check <= 9; check++) {
    if (luhn('$siren$nic$check')) return '$siren$nic$check';
  }
  throw StateError('unreachable');
}

final _localSiret = _siret('990000001', '0002');
final _siegeSiret = _siret('990000001', '0001');

/// Lot CSV par le VRAI parcours d'import (POST /merchant-import).
Future<int> _createBatch(_LocalApi api, List<Map<String, String>> rows) async {
  const columns = [
    'code', 'name', 'email', 'type', 'siret', 'street', 'zip', 'city', //
    'country', 'lat', 'lng', 'phone', 'iban'
  ];
  final lines = [columns.join(';')];
  for (var i = 0; i < rows.length; i++) {
    final row = {
      'code': 'E2E$i',
      'email': 'e2e$i@example.invalid',
      'type': 'partner',
      'country': 'France',
      'phone': '0400000000',
      ...rows[i]
    };
    lines.add(columns.map((c) => row[c] ?? '').join(';'));
  }
  final r = await api.raw('POST', 'merchant-import', tenant: _tenant, body: {
    'source_type': 'file',
    'file_name': 'e2e-synthetique.csv',
    'file_bytes': base64Encode(utf8.encode('${lines.join('\n')}\n'))
  });
  expect(r.status, 201, reason: '${r.body}');
  return r.body['data']['id'] as int;
}

Future<List<MerchantImportRow>> _rows(_LocalApi api, int batch) async {
  final r =
      await api.raw('GET', 'merchant-import/$batch/rows', tenant: _tenant);
  expect(r.status, 200, reason: '${r.body}');
  return (r.body['data'] as List)
      .map((v) => MerchantImportRow.fromJson(object(v)))
      .toList();
}

Future<String> _batchStatus(_LocalApi api, int batch) async {
  final r = await api.raw('GET', 'merchant-import/$batch', tenant: _tenant);
  expect(r.status, 200, reason: '${r.body}');
  return r.body['data']['status'] as String;
}

Future<_Raw> _patch(_LocalApi api, int batch, MerchantImportRow row,
        Map<String, dynamic> body) =>
    api.raw('PATCH', 'merchant-import/$batch/rows/${row.id}',
        tenant: _tenant, body: {'version': row.version, ...body});

String _state(MerchantImportRow r) =>
    '${r.id}:${r.version}:${r.status}:${jsonEncode(r.fields)}';

Future<void> _until(bool Function() done,
    {Duration timeout = const Duration(seconds: 90)}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('Délai dépassé');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// Grille minimale : même règle de remplacement que la grille (version la plus récente gagne).
class _Grid {
  final Map<int, MerchantImportRow> rows = {};
  void replace(List<MerchantImportRow> next) {
    for (final row in next) {
      final current = rows[row.id];
      if (current == null || row.version >= current.version) rows[row.id] = row;
    }
  }
}

EnrichmentUseCase _session(_LocalApi api, int batch, _Grid grid,
        {bool enabled = true}) =>
    EnrichmentUseCase(
      repository: EnrichmentRepository(api),
      batchId: batch,
      enabled: enabled,
      currentRow: (id) => grid.rows[id],
      batchEditable: () => true,
      replaceRows: grid.replace,
      reloadRows: () => _rows(api, batch),
      pollInterval: const Duration(milliseconds: 300),
      maxPolls: 400,
    );

Future<EnrichmentException> _refusal(Future<Object?> call) async {
  try {
    await call;
  } on EnrichmentException catch (e) {
    return e;
  }
  fail('Refus attendu');
}

void main() {
  if (_host.isEmpty) {
    test('pile locale non fournie (--dart-define=ENRICHMENT_E2E=...)', () {},
        skip: 'Lancement explicite seulement');
    return;
  }

  test(
      'flag serveur absent : capabilities false, routes 503, import existant intact',
      () async {
    final api = _LocalApi(18081);
    await api.login();
    final repo = EnrichmentRepository(api);
    final caps = await repo.capabilities(_tenant);
    expect([caps.enabled, caps.registry, caps.geocoding, caps.maxRows],
        [false, false, false, 2000]);
    final rawCaps = api.last!.body['data'] as Map;
    expect([rawCaps['vat'], rawCaps['chat_resolution']], [false, false]);

    final batch = await _createBatch(api, [
      {
        'name': 'ESSAI REGRESSION',
        'siret': _siret('990000009', '0001'),
        'street': '1 RUE DES ESSAIS',
        'zip': '04000',
        'city': 'DIGNE-LES-BAINS',
        'lat': '44.09',
        'lng': '6.23'
      },
      {'name': 'ESSAI REJET'},
    ]);
    final grid = _Grid()..replace(await _rows(api, batch));

    // Flag de build BO éteint (valeur par défaut) : aucune requête.
    final calls = api.calls.length;
    final buildOff =
        _session(api, batch, grid, enabled: merchantEnrichmentEnabled);
    await buildOff.initialize();
    expect(merchantEnrichmentEnabled, isFalse);
    expect(buildOff.available, isFalse);
    expect(api.calls.length, calls);

    final session = _session(api, batch, grid);
    await session.initialize();
    expect(session.available, isFalse);

    final disabled = await _refusal(repo.start(
        _tenant,
        batch,
        {
          'row_ids': [grid.rows.keys.first],
          'mode': 'missing_only'
        },
        'e2e-off-1'));
    expect([disabled.status, disabled.code], [503, 'ENRICHMENT_DISABLED']);
    final list = await _refusal(repo.jobs(_tenant, batch));
    expect([list.status, list.code], [503, 'ENRICHMENT_DISABLED']);

    // Parcours existant : correction, rejet, validation, import.
    final rows = grid.rows.values.toList();
    final edited = await _patch(
        api, batch, rows[0], {'field': 'phone', 'value': '0400000001'});
    expect(edited.status, 200, reason: '${edited.body}');
    final rejected = await _patch(api, batch, rows[1], {'status': 'rejected'});
    expect(rejected.status, 200, reason: '${rejected.body}');
    final current =
        (await _rows(api, batch)).firstWhere((r) => r.id == rows[0].id);
    final validated =
        await _patch(api, batch, current, {'status': 'validated'});
    expect(validated.status, 200, reason: '${validated.body}');
    final imported = await api.raw('POST', 'merchant-import/$batch/import',
        tenant: _tenant,
        headers: {'Idempotency-Key': 'e2e-off-import-1'},
        body: {});
    // ignore: avoid_print
    print(
        '[e2e] off : import existant → HTTP ${imported.status} ${jsonEncode(imported.body)}');
    expect(imported.status, 200, reason: '${imported.body}');
    expect(imported.body['data']['imported'], 1);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test(
      'API sans enrichissement : 404 = recherche indisponible, import existant lisible',
      () async {
    final api = _LocalApi(18082);
    await api.login();
    final batch = await _createBatch(api, [
      {'name': 'ESSAI ANCIENNE API'}
    ]);
    final grid = _Grid()..replace(await _rows(api, batch));
    final refusal =
        await _refusal(EnrichmentRepository(api).capabilities(_tenant));
    expect(refusal.status, 404);
    expect(refusal.toString(), 'Recherche indisponible sur cette API.');
    final session = _session(api, batch, grid);
    await session.initialize();
    expect(session.available, isFalse);
    expect(session.message, 'Recherche indisponible sur cette API.');
    expect(grid.rows, hasLength(1));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
      'flag allumé : propositions séparées, application CAS, conflits, sans validation ni import',
      () async {
    final api = _LocalApi(18080);
    await api.login();
    final repo = EnrichmentRepository(api);
    final batch = await _createBatch(api, [
      {'name': 'ESSAI BOULANGERIE', 'siret': _localSiret},
      {'name': 'ESSAI MULTIPLE', 'zip': '04000', 'city': 'DIGNE-LES-BAINS'},
      {'name': 'ESSAI PANNE', 'zip': '04000'},
      {'name': 'ESSAI CLIENT', 'type': 'customer'},
      {
        'name': 'ESSAI ADRESSE',
        'street': '5 RUE APPROX',
        'zip': '04000',
        'city': 'DIGNE-LES-BAINS'
      },
    ]);
    final grid = _Grid()..replace(await _rows(api, batch));
    final ids = (grid.rows.values.toList()
          ..sort((a, b) => a.position.compareTo(b.position)))
        .map((r) => r.id)
        .toList();
    final before = grid.rows.values.map(_state).toList();

    final session = _session(api, batch, grid);
    final progress = <int>[];
    session.addListener(() {
      final job = session.job;
      if (job != null) progress.add(job.done);
    });
    await session.initialize();
    expect(session.available, isTrue);

    // Le client exclut la ligne client avant tout POST.
    final calls = api.calls.length;
    await session.start(ids);
    expect(api.calls.length, calls);
    expect(session.message, startsWith('Sélectionnez explicitement'));

    await session.start([ids[0], ids[1], ids[2], ids[4]]);
    expect(session.job, isNotNull, reason: session.message);
    await _until(() => session.job?.active == false && !session.busy);
    await session.readPage(0);
    final job = session.job!;
    expect([
      job.status,
      job.done,
      job.total,
      job.matched,
      job.ambiguous,
      job.unresolved,
      job.stale
    ], [
      'completed_with_errors',
      4,
      4,
      1,
      1,
      2,
      0
    ]);
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]),
          reason: 'progression monotone');
    }

    // Recherche et lecture des propositions : aucune ligne modifiée.
    expect((await _rows(api, batch)).map(_state).toList(), before);

    final byRow = {for (final p in session.page!.items) p.rowId: p};
    final exact = byRow[ids[0]]!;
    expect(exact.state, 'matched');
    final establishment = exact.candidates.single;
    expect([
      establishment.kind,
      establishment.matchLevel,
      establishment.siret,
      establishment.geoPrecision
    ], [
      'establishment',
      'exact_identifier',
      _localSiret,
      'housenumber'
    ]);
    expect(establishment.siret, isNot(_siegeSiret));
    expect(establishment.fields['intracommunity_vat_number'], isNull);
    expect(establishment.sources['lat']!.provider, 'ign_geocodage');
    expect(establishment.sources['street']!.provider, 'recherche_entreprises');
    final ambiguous = byRow[ids[1]]!;
    expect(ambiguous.state, 'ambiguous');
    expect(ambiguous.reasons, contains('PROVIDER_RESULTS_NOT_EXHAUSTIVE'));
    expect(ambiguous.candidates.length, lessThanOrEqualTo(5));
    final outage = byRow[ids[2]]!;
    expect(outage.state, 'provider_unavailable');
    expect(outage.reasons, contains('REGISTRY_RATE_LIMITED'));
    final address = byRow[ids[4]]!;
    expect(address.state, 'address_only');
    final addressCandidate =
        address.candidates.firstWhere((c) => c.kind == 'address');
    expect([addressCandidate.siret, addressCandidate.geoPrecision],
        [null, 'street']);

    // Application humaine : champs vides seulement, une version, ligne pending.
    final row0 = grid.rows[ids[0]]!;
    final fillable = session.applicable(exact, establishment);
    expect(fillable, containsAll(['street', 'zip', 'city', 'lat', 'lng']));
    expect(fillable.intersection({'name', 'siret', 'country'}), isEmpty);
    expect(await session.apply(exact, establishment, fillable), isTrue,
        reason: session.message);
    final applied = grid.rows[ids[0]]!;
    expect([applied.status, applied.version], ['pending', row0.version + 1]);
    expect(applied.valueOf('lat'), 44.0921);
    expect(applied.valueOf('name'), 'ESSAI BOULANGERIE',
        reason: 'nom saisi conservé');
    final server0 = (await _rows(api, batch)).firstWhere((r) => r.id == ids[0]);
    expect(_state(server0), _state(applied));
    expect(session.page!.items.firstWhere((p) => p.id == exact.id).state,
        'applied');
    expect(session.applicable(exact, establishment), isEmpty);

    // Coordonnées approximatives : accord exigé côté BO puis côté serveur ; rejeu idempotent.
    final row4 = grid.rows[ids[4]]!;
    final coords = session.applicable(address, addressCandidate);
    expect(coords, {'lat', 'lng'});
    final beforeNoAck = api.calls.length;
    expect(await session.apply(address, addressCandidate, coords), isFalse);
    expect(api.calls.length, beforeNoAck, reason: 'aucun POST sans accord');
    Json body(bool ack) => {
          'candidate_id': addressCandidate.id,
          'expected_version': row4.version,
          'fields': ['lat', 'lng'],
          'acknowledge_approximate_coordinates': ack
        };
    final precision = await _refusal(
        repo.apply(_tenant, batch, address.id, body(false), 'e2e-ack-0'));
    expect([precision.status, precision.code],
        [422, 'ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED']);
    final first =
        await repo.apply(_tenant, batch, address.id, body(true), 'e2e-ack-1');
    final firstBody = jsonEncode(api.last!.body);
    final replay =
        await repo.apply(_tenant, batch, address.id, body(true), 'e2e-ack-1');
    expect(api.last!.replayed, isTrue);
    expect(jsonEncode(api.last!.body), firstBody);
    expect([first.row.version, replay.row.version],
        [row4.version + 1, row4.version + 1]);
    expect(first.row.status, 'pending');
    final server4 = (await _rows(api, batch)).firstWhere((r) => r.id == ids[4]);
    expect(server4.version, row4.version + 1, reason: 'aucune double écriture');
    grid.replace([first.row, ...first.related]);

    // Correction humaine pendant/après la recherche : proposition périmée, valeur humaine gardée.
    final row1 = grid.rows[ids[1]]!;
    final human = await _patch(
        api, batch, row1, {'field': 'street', 'value': '7 RUE HUMAINE'});
    expect(human.status, 200, reason: '${human.body}');
    grid.replace(await _rows(api, batch));
    await session.readPage(0);
    expect(session.job!.stale, 1);
    final stale = session.page!.items.firstWhere((p) => p.rowId == ids[1]);
    expect(stale.state, 'stale');
    expect(stale.reasons, contains('ROW_VERSION_CHANGED'));
    expect(session.applicable(stale, stale.candidates.first), isEmpty);
    final current1 = grid.rows[ids[1]]!;
    final staleRefusal = await _refusal(repo.apply(
        _tenant,
        batch,
        stale.id,
        {
          'candidate_id': stale.candidates.first.id,
          'expected_version': current1.version,
          'fields': ['siret']
        },
        'e2e-stale-1'));
    expect([staleRefusal.status, staleRefusal.code, staleRefusal.row?.version],
        [409, 'ENRICHMENT_PROPOSAL_STALE', current1.version]);
    final versionRefusal = await _refusal(repo.apply(
        _tenant,
        batch,
        stale.id,
        {
          'candidate_id': stale.candidates.first.id,
          'expected_version': row1.version,
          'fields': ['siret']
        },
        'e2e-version-1'));
    expect([versionRefusal.status, versionRefusal.code],
        [409, 'ENRICHMENT_VERSION_CONFLICT']);
    final after1 = (await _rows(api, batch)).firstWhere((r) => r.id == ids[1]);
    expect([after1.valueOf('street'), after1.version],
        ['7 RUE HUMAINE', current1.version]);

    // Isolation : autre réseau refusé avec la session CCI04.
    final other = _LocalApi(18080, tenant: 'tribuneo_autre_test')
      ..token = api.token;
    final forbidden = await _refusal(
        EnrichmentRepository(other).capabilities('tribuneo_autre_test'));
    expect(forbidden.status, 403);

    // Rien n'a été validé ni importé par la fonctionnalité.
    expect(await _batchStatus(api, batch), 'review');
    expect((await _rows(api, batch)).map((r) => r.status).toSet(), {'pending'});

    // Le parcours humain existant reprend la main ensuite.
    final validated =
        await _patch(api, batch, grid.rows[ids[0]]!, {'status': 'validated'});
    // ignore: avoid_print
    print(
        '[e2e] on : validation humaine de la ligne enrichie → HTTP ${validated.status} '
        '${validated.status == 200 ? '' : validated.body}');
    expect(validated.status, anyOf(200, 409, 422));
    session.dispose();
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('annulation : job seul, lot intact, aucun résultat tardif', () async {
    final api = _LocalApi(18080);
    await api.login();
    final repo = EnrichmentRepository(api);
    // Noms uniques : le cache Redis des lectures publiques (TTL) servirait sinon un essai précédent.
    final run = DateTime.now().millisecondsSinceEpoch;
    final batch = await _createBatch(api, [
      for (var i = 1; i <= 4; i++)
        {'name': 'ESSAI LENT $run $i', 'zip': '04000'},
      {'name': 'ESSAI CLIENT 2', 'type': 'customer'},
      {'name': 'ESSAI REJETEE', 'zip': '04000'},
    ]);
    final grid = _Grid()..replace(await _rows(api, batch));
    final ordered = grid.rows.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final rejected =
        await _patch(api, batch, ordered[5], {'status': 'rejected'});
    expect(rejected.status, 200, reason: '${rejected.body}');
    grid.replace(await _rows(api, batch));
    final before = (await _rows(api, batch)).map(_state).toList();
    final ids = ordered.map((r) => r.id).toList();

    final body = {'row_ids': ids, 'mode': 'missing_only'};
    final job = await repo.start(_tenant, batch, body, 'e2e-cancel-1');
    expect([job.total, job.done], [6, 2],
        reason: 'client et ligne rejetée comptés ignorés');
    final again = await repo.start(_tenant, batch, body, 'e2e-cancel-1');
    expect(again.id, job.id, reason: 'même clé, même corps : même job');
    final running =
        await _refusal(repo.start(_tenant, batch, body, 'e2e-cancel-2'));
    expect([running.status, running.code], [409, 'ENRICHMENT_ALREADY_RUNNING']);
    final early = await repo.proposals(_tenant, batch, job.id);
    final skipped = early.items
        .where((p) => p.state == 'skipped')
        .expand((p) => p.reasons)
        .toSet();
    expect(skipped, {'ROW_NOT_PARTNER', 'ROW_NOT_PENDING'});

    final session = _session(api, batch, grid);
    await session.initialize();
    await session.resume();
    await _until(() => (session.job?.done ?? 0) >= 3 && !session.busy);
    await session.cancel();
    expect(session.job!.status, 'cancelled', reason: session.message);
    expect(await _batchStatus(api, batch), 'review');

    final atCancel = await repo.read(_tenant, batch, job.id);
    final proposalsAtCancel =
        (await repo.proposals(_tenant, batch, job.id)).total;
    await Future<void>.delayed(const Duration(seconds: 6));
    final later = await repo.read(_tenant, batch, job.id);
    expect([later.status, later.done], ['cancelled', atCancel.done]);
    expect((await repo.proposals(_tenant, batch, job.id)).total,
        proposalsAtCancel);
    expect(proposalsAtCancel, lessThan(6));
    expect((await _rows(api, batch)).map(_state).toList(), before);
    session.dispose();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
