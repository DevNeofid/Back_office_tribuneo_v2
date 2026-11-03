import '../../models/merchant_enrichment/enrichment_models.dart';
import '../../models/merchant_import_row_model.dart';

class EnrichmentResponse {
  final int status;
  final dynamic body;
  const EnrichmentResponse(this.status, this.body);
}

/// Transport injectable : seuls des chemins relatifs du contrat Tribuneo.
abstract class EnrichmentTransport {
  Future<String> currentTenant();
  Future<EnrichmentResponse> send(String method, String path,
      {required String tenant, Json? body, Map<String, String>? headers});
}

class EnrichmentRepository {
  final EnrichmentTransport transport;
  EnrichmentRepository(this.transport);

  Future<Json> request(String tenant, String method, String path,
      {Json? body, String? key}) async {
    if (tenant.isEmpty) throw const EnrichmentException();
    final EnrichmentResponse response;
    try {
      // Bounds even a stalled adapter; late responses cannot update the caller.
      response = await transport
          .send(method, path,
              tenant: tenant,
              body: body,
              headers: key == null ? null : {'Idempotency-Key': key})
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const EnrichmentException();
    }
    final envelope = response.body;
    if (response.status != 200 && response.status != 202) {
      final error = envelope is Map ? envelope['error'] : null;
      final details = error is Map ? error['details'] : null;
      final row = details is Map ? details['row'] : null;
      throw EnrichmentException(
          status: response.status,
          code: details is Map ? details['code'] as String? : null,
          row: row is Map ? MerchantImportRow.fromJson(object(row)) : null);
    }
    if (envelope is! Map || envelope['data'] is! Map) {
      throw const EnrichmentException();
    }
    return object(envelope['data']);
  }

  Future<EnrichmentCapability> capabilities(String tenant) async =>
      EnrichmentCapability.fromJson(await request(
          tenant, 'GET', 'merchant-import/enrichment-capabilities'));
  String _jobs(int batch) => 'merchant-import/$batch/enrichment-jobs';
  Future<EnrichmentPage<EnrichmentJob>> jobs(String tenant, int batch,
          {int offset = 0}) async =>
      EnrichmentPage.fromJson(
          await request(
              tenant, 'GET', '${_jobs(batch)}?limit=20&offset=$offset'),
          EnrichmentJob.fromJson);
  Future<EnrichmentJob> start(
          String tenant, int batch, Json body, String key) async =>
      EnrichmentJob.fromJson(
          await request(tenant, 'POST', _jobs(batch), body: body, key: key));
  Future<EnrichmentJob> read(String tenant, int batch, String job) async =>
      EnrichmentJob.fromJson(
          await request(tenant, 'GET', '${_jobs(batch)}/$job'));
  Future<EnrichmentJob> cancel(String tenant, int batch, String job) async =>
      EnrichmentJob.fromJson(
          await request(tenant, 'POST', '${_jobs(batch)}/$job/cancel'));
  Future<EnrichmentPage<EnrichmentProposal>> proposals(
          String tenant, int batch, String job, {int offset = 0}) async =>
      EnrichmentPage.fromJson(
          await request(tenant, 'GET',
              '${_jobs(batch)}/$job/proposals?limit=50&offset=$offset'),
          EnrichmentProposal.fromJson);
  Future<EnrichmentApplyResult> apply(String tenant, int batch, String proposal,
          Json body, String key) async =>
      EnrichmentApplyResult.fromJson(await request(tenant, 'POST',
          'merchant-import/$batch/enrichment-proposals/$proposal/apply',
          body: body, key: key));
}
