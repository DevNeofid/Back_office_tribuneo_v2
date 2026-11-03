import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';
import 'fixtures.dart';

// Données SYNTHÉTIQUES (contrat v1.1) : SIREN fictif 990000001, aucune donnée réelle.
const vatSiren = '990000001';
const vatSiret = '99000000100021';
const vatNumber = 'FRG3990000001';
const vatCandidateId = '00000000-0000-4000-8000-0000000000aa';

Json vatSourceJson({String provider = 'dgfip_tva'}) => {
      'provider': provider,
      'url':
          'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/numeros-de-tva-intracommunautaires-francais/records?where=vat_no%3D%22G3990000001%22',
      'retrieved_at': '2026-11-03T08:00:00Z',
      'record_id': 'G3990000001',
      'precision': null,
    };

Json registrySourceJson() => {
      'provider': 'recherche_entreprises',
      'url': 'https://example.invalid/synthetic-registry',
      'retrieved_at': date,
      'record_id': vatSiret,
      'precision': null,
    };

/// Candidat établissement ; `status` absent = ancienne proposition sans clé `vat_status`.
Json vatCandidateJson(
    {String? status = 'found',
    String? number = vatNumber,
    String sourceProvider = 'dgfip_tva'}) {
  final json = <String, dynamic>{
    'id': vatCandidateId,
    'kind': 'establishment',
    'label': 'ESSAI SYNTHÉTIQUE — 12 rue du Test',
    'legal_name': 'ESSAI SYNTHÉTIQUE SAS',
    'siren': vatSiren,
    'siret': vatSiret,
    'establishment_status': 'active',
    'fields': {
      'siret': vatSiret,
      'naf': '47.24Z',
      'intracommunity_vat_number': number,
    },
    'sources': {
      'siret': registrySourceJson(),
      'naf': registrySourceJson(),
      if (number != null)
        'intracommunity_vat_number': vatSourceJson(provider: sourceProvider),
    },
    'match_level': 'exact_identifier',
    'reason_codes': ['SIRET_EXACT', 'VAT_FOUND_IN_SOURCE'],
    'geo_precision': null,
  };
  if (status != null) json['vat_status'] = status;
  return json;
}

Json vatProposalJson(Json candidate, {String state = 'matched'}) =>
    proposalJson(state: state, candidates: [candidate]);

/// Faux transport v1.1 : capability `vat` pilotable, le reste comme le faux transport du lot 01.
class VatTransport extends FakeEnrichmentTransport {
  bool vat = true;
  @override
  Future<EnrichmentResponse> send(String method, String path,
      {required String tenant,
      Json? body,
      Map<String, String>? headers}) async {
    if (!path.endsWith('enrichment-capabilities')) {
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
    return EnrichmentResponse(200, {
      'data': {
        'enabled': enabled,
        'registry': true,
        'geocoding': true,
        'vat': vat,
        'chat_resolution': false,
        'max_rows': 2000
      }
    });
  }
}
