import 'dart:convert';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import '../_base_repository.dart';
import '../../models/merchant_enrichment/enrichment_models.dart';
import 'enrichment_repository.dart';

/// Uses the existing human session and current network. No alternative auth.
class TribuneoEnrichmentTransport extends BaseRepository
    implements EnrichmentTransport {
  @override
  Future<String> currentTenant() => getTenantForCurrentNetwork();

  @override
  Future<EnrichmentResponse> send(String method, String path,
      {required String tenant,
      Json? body,
      Map<String, String>? headers}) async {
    final uri = Uri.parse(path);
    final response = method == 'GET'
        ? await ApiClient().get(uri.path,
            queryParams: uri.queryParameters, overrideTenant: tenant)
        : await ApiClient().post(uri.path, jsonEncode(body ?? {}),
            overrideTenant: tenant, headers: headers);
    return EnrichmentResponse(response.statusCode ?? 0, response.data);
  }
}
