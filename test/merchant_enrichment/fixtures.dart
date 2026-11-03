import 'dart:async';
import 'package:back_office_tribuneo_v2/domain/models/merchant_enrichment/enrichment_models.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/merchant_enrichment/enrichment_repository.dart';

const jobId = '00000000-0000-4000-8000-000000000001';
const proposalId = '00000000-0000-4000-8000-000000000002';
const candidateId = '00000000-0000-4000-8000-000000000003';
const date = '2026-11-02T10:00:00Z';

Json rowJson(int id,
        {int version = 1, Json? fields, String status = 'pending'}) =>
    {
      'id': id,
      'id_batch': 12,
      'position': id,
      'status': status,
      'fields':
          fields ?? {'name': 'Atelier Synthétique $id', 'type': 'partner'},
      'suggested': {'values': {}, 'sources': {}},
      'issues': [],
      'version': version,
    };
MerchantImportRow row(int id,
        {int version = 1, Json? fields, String status = 'pending'}) =>
    MerchantImportRow.fromJson(
        rowJson(id, version: version, fields: fields, status: status));
Json jobJson({String status = 'running', int done = 1, int total = 2}) => {
      'id': jobId,
      'batch_id': 12,
      'status': status,
      'progress_done': done,
      'progress_total': total,
      'matched': done,
      'ambiguous': 0,
      'unresolved': 0,
      'stale': 0,
      'error_code': null,
      'created_at': date,
      'updated_at': date,
    };
Json sourceJson({String? precision = 'street'}) => {
      'provider': 'ign_geocodage',
      'url': 'https://example.invalid/synthetic-source',
      'retrieved_at': date,
      'record_id': 'synthetic-address',
      'precision': precision,
    };
Json candidateJson({String id = candidateId, String precision = 'street'}) => {
      'id': id,
      'kind': 'address',
      'label': '12 rue du Test, Ville Synthétique',
      'legal_name': null,
      'siren': null,
      'siret': null,
      'establishment_status': null,
      'fields': {
        'street': '12 rue du Test',
        'zip': '00000',
        'city': 'Ville Synthétique',
        'country': 'France',
        'lat': 0.0,
        'lng': 0.0
      },
      'sources': {
        for (final f in ['street', 'zip', 'city', 'country', 'lat', 'lng'])
          f: sourceJson(precision: precision)
      },
      'match_level': 'address_only',
      'reason_codes': ['SYNTHETIC_ADDRESS'],
      'geo_precision': precision,
      'vat_status': 'not_checked',
    };
Json proposalJson(
        {String state = 'address_only',
        int rowId = 1,
        int version = 1,
        List<Json>? candidates}) =>
    {
      'id': proposalId,
      'job_id': jobId,
      'batch_id': 12,
      'row_id': rowId,
      'base_version': version,
      'state': state,
      'reason_codes': ['SYNTHETIC_ADDRESS'],
      'candidates': candidates ?? [candidateJson()],
      'created_at': date,
    };
Json pageJson(List<Json> items,
        {int total = 1, int limit = 50, int offset = 0}) =>
    {'items': items, 'total': total, 'limit': limit, 'offset': offset};

/// Synthetic, in-memory transport. This file is never imported by production.
class FakeEnrichmentTransport implements EnrichmentTransport {
  String tenant = 'synthetic_tenant';
  bool enabled = true, oldApi = false, offline = false;
  final List<
      ({
        String method,
        String path,
        String tenant,
        Json? body,
        Map<String, String>? headers
      })> calls = [];
  Json currentJob = jobJson();
  List<Json> proposals = [proposalJson()];
  Json? applyError;
  int applyErrorStatus = 409;
  Json appliedRow = rowJson(1, version: 2, fields: {
    'name': 'Atelier Synthétique 1',
    'type': 'partner',
    'city': 'Ville Synthétique'
  });
  List<Json> related = [rowJson(2, version: 2)];
  Completer<void>? barrier;
  Future<EnrichmentResponse> Function(String, String, Json?)? handler;
  @override
  Future<String> currentTenant() async => tenant;
  @override
  Future<EnrichmentResponse> send(String method, String path,
      {required String tenant,
      Json? body,
      Map<String, String>? headers}) async {
    calls.add((
      method: method,
      path: path,
      tenant: tenant,
      body: body,
      headers: headers
    ));
    if (barrier != null) await barrier!.future;
    if (offline) throw StateError('synthetic offline');
    if (handler != null) return handler!(method, path, body);
    if (oldApi)
      return const EnrichmentResponse(404, {
        'error': {
          'type': 'NOT_FOUND',
          'description': 'Unavailable',
          'details': {'code': 'NOT_FOUND'}
        }
      });
    Json data;
    if (path.endsWith('enrichment-capabilities')) {
      data = {
        'enabled': enabled,
        'registry': true,
        'geocoding': true,
        'vat': false,
        'chat_resolution': false,
        'max_rows': 2000
      };
    } else if (path.contains('/apply')) {
      if (applyError != null)
        return EnrichmentResponse(applyErrorStatus, {
          'error': {
            'type': 'CONFLICT',
            'description': 'Conflict',
            'details': applyError
          }
        });
      data = {
        'proposal': proposalJson(state: 'applied'),
        'row': appliedRow,
        'related': related
      };
    } else if (path.endsWith('/cancel')) {
      currentJob = jobJson(status: 'cancelled');
      data = currentJob;
    } else if (path.contains('/proposals?')) {
      final offset = int.parse(Uri.parse(path).queryParameters['offset']!);
      data = pageJson(proposals.skip(offset).take(50).toList(),
          total: proposals.length, offset: offset);
    } else if (method == 'GET' && path.contains('enrichment-jobs?')) {
      data = pageJson([currentJob], limit: 20);
    } else {
      data = currentJob;
    }
    return EnrichmentResponse(
        method == 'POST' && path.endsWith('enrichment-jobs') ? 202 : 200,
        {'data': data});
  }
}
