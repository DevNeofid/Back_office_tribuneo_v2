import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/refund_shop_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';

class TransferOrderRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'bto';

  Future<PaginatedResult<TransferOrderModel>> getOrders({
    int limit = 10,
    int offset = 0,
  }) async {
    List<TransferOrderModel> transferOrders = [];
    int total = 0;
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(
        suffixe,
        overrideTenant: tenant,
        queryParams: {
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseMap = response.data;
        final List<dynamic> items =
            (responseMap['data']?['items'] as List<dynamic>?) ?? [];
        total = _extractTotal(responseMap, items.length);
        for (var transferOrder in items) {
          transferOrders.add(TransferOrderModel.fromJson(transferOrder));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      transferOrders = [];
      total = 0;
    }
    return PaginatedResult<TransferOrderModel>(
        items: transferOrders, total: total);
  }

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

  Future downloadFile(int id) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixe,
          id: id, bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<RefundShopModel>> awaitRefund() async {
    String tenant = await getTenantForCurrentNetwork();
    List<RefundShopModel> refunds = [];
    try {
      dynamic response =
          await _remoteData.get('$suffixe/pending', overrideTenant: tenant);
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data['data'];
        for (var refund in jsonResponse) {
          refunds.add(RefundShopModel.fromJson(refund));
        }
      } else {
        refunds = [];
      }
    } catch (e) {
      refunds = [];
      throw Exception('Erreur lors du téléchargement du fichier XML');
    }
    return refunds;
  }

  Future refundShop() async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('$suffixe/gen',
          bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erreur lors du téléchargement du fichier XML');
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement du fichier XML');
    }
  }

  Future editProof(String transactionNumber) async {
    String suffixe = 'accounting/proof-of-receipt';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('$suffixe/$transactionNumber',
          bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erreur lors du téléchargement des documents');
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement des documents');
    }
  }
}
