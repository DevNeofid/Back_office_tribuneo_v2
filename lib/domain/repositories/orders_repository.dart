import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:back_office_tribuneo_v2/config/neo_encrypt.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/payment_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';

class OrderRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();
  NeoEncrypt encrypt = NeoEncrypt();

  String suffixe = 'order';
  final String suffixeQ = 'qrcode/gen';

  Future<PaginatedResult<OrderModel>> getOrders({
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    String tenant = await getTenantForCurrentNetwork();
    List<OrderModel> orders = [];
    int total = 0;
    try {
      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'offset': offset,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      dynamic response = await _remoteData.get(
        suffixe,
        overrideTenant: tenant,
        queryParams: queryParams,
      );
      if (response.statusCode == 200) {
        final dynamic responseMap = response.data;
        final List<dynamic> items =
            (responseMap['data']?['items'] as List<dynamic>?) ?? [];
        total = _extractTotal(responseMap, items.length);
        for (var order in items) {
          orders.add(OrderModel.fromJson(order as Map<String, dynamic>));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      orders = [];
      total = 0;
    }
    return PaginatedResult<OrderModel>(items: orders, total: total);
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

    return 0;
  }

  Future<bool> addOrders(OrderSendModel order,
      {String? fileName, dynamic file}) async {
    String tenant = await getTenantForCurrentNetwork();
    String currentSuffix = file != null ? "$suffixe/file" : suffixe;

    if (file != null) {
      try {
        String data = jsonEncode({
          "file_name": fileName,
          "file_bytes": file,
          "other_data": order.toJson(),
        });

        dynamic response =
            await _remoteData.post(currentSuffix, data, overrideTenant: tenant);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      } catch (e) {
        if (kDebugMode) {
          print('###DEBUG### Error: $e');
        }
        return false;
      }
    } else {
      try {
        String data = jsonEncode(order);
        dynamic response =
            await _remoteData.post(currentSuffix, data, overrideTenant: tenant);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      } catch (e) {
        if (kDebugMode) {
          print('###DEBUG### Error: $e');
        }
        return false;
      }
    }
  }

  Future updateOrder(OrderSendModel order) async {
    String data = jsonEncode(order.toJson());
    try {
      dynamic request = await _remoteData.put(suffixe, data, id: order.id);
      if (request.statusCode == 200) {
        request = jsonDecode(request.body);
        return OrderSendModel.fromJson(request);
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteOrder(int id) async {
    String tenant = await getTenantForCurrentNetwork();

    dynamic request =
        await _remoteData.delete(suffixe, id, overrideTenant: tenant);
    if (request.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<List<UrssafModel>> getUrssaf() async {
    try {
      dynamic response = await _remoteData.get('$suffixe/events');
      if (response.statusCode == 200) {
        final List<dynamic> urssafJson = response.data['data'];
        final urssaf =
            urssafJson.map((urssaf) => UrssafModel.fromJson(urssaf)).toList();
        return urssaf;
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      return [];
    }
  }

  Future createQrCode(int idOrder) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response =
          await _remoteData.get(suffixeQ, id: idOrder, overrideTenant: tenant);

      if (response.statusCode == 200 || response.statusCode == 202) {
        String statusUrl = response.data['data']['status_url'];
        String resultUrl = response.data['data']['result_url'];

        if (statusUrl.startsWith('/')) {
          statusUrl = statusUrl.substring(1);
        }
        if (resultUrl.startsWith('/')) {
          resultUrl = resultUrl.substring(1);
        }

        bool isDone = false;

        while (!isDone) {
          await Future.delayed(const Duration(seconds: 2));
          dynamic statusResponse =
              await _remoteData.get(statusUrl, overrideTenant: tenant);

          if (statusResponse.statusCode == 200) {
            Map<String, dynamic> statusData = statusResponse.data['data'];
            if (statusData['status'] == 'done') {
              isDone = true;
            } else if (statusData['status'] == 'failed' ||
                statusData['status'] == 'error') {
              return null;
            }
          } else {
            return null;
          }
        }

        dynamic finalResponse = await _remoteData.get(resultUrl,
            bytesType: true, overrideTenant: tenant);
        if (finalResponse.statusCode == 200) {
          return finalResponse.data;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future createCsv(int idOrder) async {
    String suffixe = 'qrcode/gen/csv';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixe,
          id: idOrder, bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<PaymentModel>> getPayments(int idOrder) async {
    String suffixe = 'payment';
    String tenant = await getTenantForCurrentNetwork();
    List<PaymentModel> payments = [];
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: idOrder, overrideTenant: tenant);
      if (response.statusCode == 200) {
        response = response.data['data'];
        for (var payment in response) {
          payments.add(PaymentModel.fromJson(payment as Map<String, dynamic>));
        }
      } else {
        payments = [];
      }
    } catch (e) {
      payments = [];
    }
    return payments;
  }

  Future addPayment(Map payment) async {
    String suffixe = 'payment';
    String data = jsonEncode(payment);
    String tenant = await getTenantForCurrentNetwork();
    try {
      return await _remoteData.post(suffixe, data, overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      return http.Response('Error: $e', 500);
    }
  }

  Future<void> deletePayment(int idPayment) async {
    String suffixe = 'payment';
    String tenant = await getTenantForCurrentNetwork();

    dynamic response =
        await _remoteData.delete(suffixe, idPayment, overrideTenant: tenant);

    if (response.statusCode == 200) {
      return;
    }

    // Format d'erreur de l'API : {"error": {"type": ..., "description": ...}}
    String description = '';
    final dynamic data = response.data;
    if (data is Map && data['error'] is Map) {
      description = data['error']['description']?.toString() ?? '';
    }

    if (description.contains('accounting entries')) {
      throw ApiException(
          'Impossible de supprimer ce paiement : les écritures comptables ont déjà été générées.');
    }
    if (response.statusCode == 404) {
      throw ApiException('Paiement introuvable.');
    }
    throw ApiException('Erreur lors de la suppression du paiement.');
  }

  Future<String> getInvoiceInfos(int idOrder) async {
    String suffixe = 'accounting/invoice/comment';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: idOrder, overrideTenant: tenant);
      if (response.statusCode == 200) {
        var res = response.data;
        String invoiceInfos = res['data']['comment'] ?? '';
        return invoiceInfos;
      } else {
        throw Exception('Failed to load invoice');
      }
    } catch (e) {
      throw Exception('Failed to load invoice');
    }
  }

  Future createInvoice(Map invoice) async {
    String suffixe = 'accounting/invoice/order';
    String data = jsonEncode(invoice);
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.post(suffixe, data,
          overrideTenant: tenant, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load invoice');
      }
    } catch (e) {
      return null;
    }
  }

  Future createDeliveryNote(int idOrder) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('accounting/delivery-note/',
          id: idOrder, overrideTenant: tenant, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load delivery note');
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future createSummary(int idOrder) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('$suffixe/$idOrder/summary',
          overrideTenant: tenant, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load summary');
      }
    } catch (e) {
      return null;
    }
  }
}
