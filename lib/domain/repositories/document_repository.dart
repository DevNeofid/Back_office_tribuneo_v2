import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/invoice_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';

class DocumentRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'accounting/invoice';

  int _extractTotal(dynamic response, int fallback) {
    if (response is! Map) return fallback;

    int? parse(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final dynamic data = response['data'];
    if (data is Map) {
      final dynamic pagination = data['pagination'];
      final dynamic meta = data['meta'];
      final candidates = [
        data['total'],
        data['count'],
        data['total_items'],
        if (pagination is Map) pagination['total'],
        if (pagination is Map) pagination['count'],
        if (meta is Map) meta['total'],
        if (meta is Map) meta['count'],
      ];

      for (final candidate in candidates) {
        final parsed = parse(candidate);
        if (parsed != null) return parsed;
      }
    }

    return fallback;
  }

  Future<PaginatedResult<InvoiceModel>> getInvoices(
    String type, {
    int limit = 10,
    int offset = 0,
  }) async {
    List<InvoiceModel> invoices = [];
    int total = 0;
    String tenant = await getTenantForCurrentNetwork();

    try {
      dynamic response = await _remoteData.get(
        suffixe,
        queryParams: {
          'type': type,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
        overrideTenant: tenant,
      );

      if (response.statusCode == 200) {
        final dynamic responseMap = response.data;
        final dynamic data = responseMap['data'];
        final dynamic totalInvoices = data['total'];
        final List<dynamic> items =
            (data is Map ? data['invoices'] as List<dynamic>? : null) ??
                (data as List<dynamic>? ?? []);

        total = _extractTotal(responseMap, totalInvoices ?? items.length);

        for (final invoice in items) {
          invoices.add(InvoiceModel.fromJson(invoice));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      invoices = [];
      total = 0;
    }

    return PaginatedResult<InvoiceModel>(items: invoices, total: total);
  }

  Future downloadFileInvoice(int id, {String? prefixe}) async {
    prefixe ??= suffixe;
    try {
      dynamic response = await _remoteData.post(
          prefixe, '{"id_order": $id, "justDownload": 1}',
          bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future downloadFileFees(String transactionNumber, {String? prefixe}) async {
    prefixe ??= suffixe;
    try {
      dynamic response = await _remoteData.get(prefixe,
          queryParams: {'transaction_number': transactionNumber},
          bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
