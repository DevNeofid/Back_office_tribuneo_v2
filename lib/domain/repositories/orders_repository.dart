import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:back_office_tribuneo_v2/config/neo_encrypt.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/payment_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/urssaf_model.dart';

class OrderRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();
  NeoEncrypt encrypt = NeoEncrypt();

  String suffixe = 'order';
  final String suffixeQ = 'qrcode/gen';

  Future<List<OrderModel>> getOrders() async {
    String tenant = await getTenantForCurrentNetwork();
    List<OrderModel> orders = [];
    try {
      dynamic response = await _remoteData.get(suffixe, overrideTenant: tenant);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;

        if (responseBody.containsKey('data') &&
            responseBody['data'] is Map &&
            responseBody['data'].containsKey('items')) {
          final List<dynamic> itemsList = responseBody['data']['items'];

          for (var order in itemsList) {
            orders.add(OrderModel.fromJson(order as Map<String, dynamic>));
          }
        }
      } else {
        orders = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      orders = [];
    }
    return orders;
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

  Future deleteOrder(int id) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic request =
          await _remoteData.delete(suffixe, id, overrideTenant: tenant);
      if (request.statusCode == 200) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      return false;
    }
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

  Future getInvoiceInfos(int idOrder) async {
    String suffixe = 'invoice_info';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: idOrder, overrideTenant: tenant);
      if (response.statusCode == 200) {
        var res = jsonDecode(response.data);
        Map<String, dynamic> invoiceInfos = {
          'comment': res['comment'],
        };
        return invoiceInfos;
      } else {
        throw Exception('Failed to load invoice');
      }
    } catch (e) {
      throw Exception('Failed to load invoice');
    }
  }

  Future createInvoice(Map invoice) async {
    String suffixe = 'invoice_purchase';
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
