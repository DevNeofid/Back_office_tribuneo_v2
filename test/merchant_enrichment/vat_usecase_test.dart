import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/vat_status.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/merchant_enrichment/enrichment_usecase.dart';
import 'fixtures.dart';
import 'vat_fixtures.dart';

void main() {
  late VatTransport transport;
  late Map<int, MerchantImportRow> rows;
  late EnrichmentUseCase session;
  setUp(() {
    transport = VatTransport();
    rows = {1: row(1)};
    session = EnrichmentUseCase(
        repository: EnrichmentRepository(transport),
        batchId: 12,
        enabled: true,
        currentRow: (id) => rows[id],
        batchEditable: () => true,
        replaceRows: (next) {
          for (final r in next) {
            if (r.version >= (rows[r.id]?.version ?? 0)) rows[r.id] = r;
          }
        },
        reloadRows: () async => rows.values.toList());
  });
  tearDown(() => session.dispose());

  Future<void> ready() async {
    await session.initialize();
    await session.resume();
    session.pause();
  }

  EnrichmentProposal proposal(Json candidate) =>
      EnrichmentProposal.fromJson(vatProposalJson(candidate));
  EnrichmentCandidate candidate(Json json) =>
      EnrichmentCandidate.fromJson(json);

  test('old proposals and unknown statuses decode as not_checked', () {
    expect(candidate(vatCandidateJson(status: null, number: null)).vatStatus,
        VatStatus.notChecked);
    expect(candidate(vatCandidateJson(status: 'valid_vies')).vatStatus,
        VatStatus.notChecked);
    expect(
        EnrichmentCandidate.fromJson(candidateJson()).vatStatus, 'not_checked');
    for (final s in VatStatus.values) {
      expect(candidate(vatCandidateJson(status: s)).vatStatus, s);
    }
  });

  test('capability vat: absent (old API) or disabled means false', () {
    final caps = {
      'enabled': true,
      'registry': true,
      'geocoding': true,
      'chat_resolution': false,
      'max_rows': 2000
    };
    expect(EnrichmentCapability.fromJson(caps).vat, false);
    expect(EnrichmentCapability.fromJson({...caps, 'vat': true}).vat, true);
    expect(
        EnrichmentCapability.fromJson({...caps, 'enabled': false, 'vat': true})
            .vat,
        false);
  });

  test('only a found, well-formed, DGFiP-sourced number of the same SIREN', () {
    expect(VatRules.proposedNumber(candidate(vatCandidateJson())), vatNumber);
    for (final s in ['not_found', 'unavailable', 'ambiguous', 'not_checked']) {
      expect(
          VatRules.proposedNumber(candidate(vatCandidateJson(status: s))), null,
          reason: s);
    }
    expect(
        VatRules.proposedNumber(
            candidate(vatCandidateJson(number: 'FR01990000002'))),
        null,
        reason: 'autre SIREN');
    expect(
        VatRules.proposedNumber(
            candidate(vatCandidateJson(number: 'FR0199000000'))),
        null);
    expect(
        VatRules.proposedNumber(candidate(
            vatCandidateJson(sourceProvider: 'recherche_entreprises'))),
        null,
        reason: 'jamais une TVA du registre');
  });

  test('row without SIRET: VAT applicable only together with the SIRET',
      () async {
    await ready();
    final p = proposal(vatCandidateJson());
    final c = p.candidates.single;
    final allowed = session.applicable(p, c);
    expect(allowed, containsAll(['siret', 'naf', VatRules.field]));

    expect(await session.apply(p, c, {VatRules.field}), false);
    expect(transport.calls.any((c) => c.path.endsWith('/apply')), false,
        reason: 'TVA seule sans SIRET : aucun envoi');

    expect(await session.apply(p, c, {VatRules.field, 'siret'}), true);
    final write = transport.calls.singleWhere((c) => c.path.endsWith('/apply'));
    expect(write.body!['fields'], ['intracommunity_vat_number', 'siret']);
    expect(write.body!.containsKey('values'), false,
        reason: 'jamais de valeur envoyée');
  });

  test(
      'row with the same SIRET: VAT alone; another SIRET or a VAT already set: never',
      () async {
    await ready();
    final p = proposal(vatCandidateJson());
    final c = p.candidates.single;
    rows[1] =
        row(1, fields: {'name': 'X', 'type': 'partner', 'siret': vatSiret});
    expect(session.applicable(p, c), contains(VatRules.field));
    rows[1] = row(1,
        fields: {'name': 'X', 'type': 'partner', 'siret': '99000000200029'});
    expect(session.applicable(p, c), isEmpty);
    rows[1] = row(1, fields: {
      'name': 'X',
      'type': 'partner',
      'siret': vatSiret,
      'intracommunity_vat_number': 'FR00999999999'
    });
    expect(session.applicable(p, c), isNot(contains(VatRules.field)));
  });

  test('capability vat off or non-found status: never applicable', () async {
    transport.vat = false;
    await ready();
    final p = proposal(vatCandidateJson());
    expect(session.applicable(p, p.candidates.single),
        isNot(contains(VatRules.field)));
    expect(
        await session.apply(p, p.candidates.single, {VatRules.field, 'siret'}),
        false);

    transport.vat = true;
    await session.initialize();
    for (final s in ['not_found', 'unavailable', 'ambiguous']) {
      final q = proposal(vatCandidateJson(status: s, number: null));
      expect(session.applicable(q, q.candidates.single),
          isNot(contains(VatRules.field)),
          reason: s);
    }
  });

  test('BO v1.1 contract copy: VAT enum, DGFiP provider, number pattern', () {
    final spec = jsonDecode(
        File('docs/merchant-enrichment/v1.1/CONTRAT_V1_1.openapi.json')
            .readAsStringSync()) as Map<String, dynamic>;
    final schemas = spec['components']['schemas'] as Map<String, dynamic>;
    expect(spec['info']['version'], '1.1.0');
    expect(
        Set<String>.from(
            schemas['Candidate']['properties']['vat_status']['enum'] as List),
        VatStatus.values);
    expect(schemas['FieldSource']['properties']['provider']['enum'],
        contains(VatRules.provider));
    final pattern = RegExp(schemas['ProposedFields']['properties']
        ['intracommunity_vat_number']['pattern'] as String);
    expect(pattern.hasMatch(vatNumber), true);
    expect(pattern.hasMatch('FR01990000001'), true);
    expect(pattern.hasMatch('01990000001'), false);
    // Les anciennes propositions (v1.0.0) sont des réponses v1.1 valides.
    final v1 = jsonDecode(
        File('docs/merchant-enrichment/CONTRAT_V1.openapi.json')
            .readAsStringSync()) as Map<String, dynamic>;
    expect(v1['components']['schemas']['Candidate']['properties']['vat_status'],
        {'type': 'string', 'const': 'not_checked'});
  });

  test('selection links VAT to SIRET only when the row has no SIRET', () {
    final selection = <String>{};
    VatRules.select(selection, VatRules.field, true, rowSiretEmpty: true);
    expect(selection, {VatRules.field, 'siret'});
    VatRules.select(selection, 'siret', false, rowSiretEmpty: true);
    expect(selection, isEmpty);
    VatRules.select(selection, VatRules.field, true, rowSiretEmpty: false);
    expect(selection, {VatRules.field});
    expect(
        VatRules.selectionValid({VatRules.field}, rowSiretEmpty: true), false);
    expect(
        VatRules.selectionValid({VatRules.field}, rowSiretEmpty: false), true);
  });
}
