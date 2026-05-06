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

  // Function to add a new order
  Future addOrders(OrderSendModel order,
      {String? fileName, dynamic file}) async {
    if (file != null) {
      suffixe = "${suffixe}/file";
    }

    OrderSendModel? res;

    if (file != null) {
      try {
        Map<String, dynamic> map = {
          "other_data": order.toJson(),
          "file_name": fileName,
          "file_bytes": file
        };
        dynamic request = await _remoteData.postWithFile(suffixe, map);
        if (request.statusCode == 201) {
          request = jsonDecode(request.body);
          res = OrderSendModel.fromJson(request);
        } else {
          res = null;
        }
      } catch (e) {
        res = null;
      }
    } else {
      try {
        String data = jsonEncode(order);
        dynamic request = await _remoteData.post(suffixe, data);
        if (request.statusCode == 201) {
          request = jsonDecode(request.body);
          res = OrderSendModel.fromJson(request);
        } else {
          res = null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('###DEBUG### Error: $e');
        }
        res = null;
      }
    }
    return res;
  }

  Future updateOrder(OrderSendModel order) async {
    OrderSendModel? res;
    String data = jsonEncode(order.toJson());
    try {
      dynamic request = await _remoteData.put(suffixe, data, id: order.id);
      if (request.statusCode == 200) {
        request = jsonDecode(request.body);
        res = OrderSendModel.fromJson(request);
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      res = null;
    }
    return res;
  }

  Future deleteOrder(int id) async {
    try {
      dynamic request = await _remoteData.softDelete('$suffixe/delete', id: id);
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
        final List<dynamic> urssafJson = jsonDecode(response.data);
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
    try {
      dynamic response =
          await _remoteData.get(suffixeQ, id: idOrder, bytesType: true);

      if (response.statusCode == 200) {
        // var res = json.decode(response.data);
        // return res;
        return response.data;
      }
    } catch (e) {
      return null;
    }
  }

  Future createCsv(int idOrder) async {
    String suffixe = 'qrcode/gen/csv';
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: idOrder, bytesType: true);
      if (response.statusCode == 200) {
        // var res = json.decode(response.data);
        // return res;
        return response.data;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<PaymentModel>> getPayments(int idOrder) async {
    String suffixe = 'payment';
    List<PaymentModel> payments = [];
    try {
      dynamic response = await _remoteData.get(suffixe, id: idOrder);
      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
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
    try {
      return await _remoteData.post(suffixe, data);
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      return http.Response('Error: $e', 500);
    }
  }

  Future getInvoiceInfos(int idOrder) async {
    String suffixe = 'invoice_info';
    try {
      dynamic response = await _remoteData.get(suffixe, id: idOrder);
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
    try {
      dynamic response = await _remoteData.post(suffixe, data, bytesType: true);
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
    String suffixe = 'delivery_note';
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: idOrder, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load delivery note');
      }
    } catch (e) {
      return null;
    }
  }

  Future createSummary(int idOrder) async {
    try {
      dynamic response =
          await _remoteData.get('$suffixe/$idOrder/summary', bytesType: true);
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
