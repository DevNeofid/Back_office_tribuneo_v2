import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:tribuneo_backoffice/config/neo_encrypt.dart';
import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/order_model.dart';
import 'package:tribuneo_backoffice/domain/models/payment_model.dart';
import 'package:tribuneo_backoffice/domain/models/urssaf_model.dart';

class OrderRepository {
  LocalDataHelper localDataHelper = LocalDataHelper();
  final RemoteDataSource _remoteData = RemoteDataSource();
  NeoEncrypt encrypt = NeoEncrypt();

  String suffixeO = 'order';
  final String suffixeQ = 'qrcgen';

  Future<List<OrderRecModel>> getOrders() async {
    List<OrderRecModel> orders = [];
    try {
      dynamic response = await _remoteData.get(suffixeO);
      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
        for (var order in response) {
          orders.add(OrderRecModel.fromJson(order));
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
      suffixeO = "${suffixeO}_file";
    }

    OrderSendModel? res;

    if (file != null) {
      try {
        Map<String, dynamic> map = {
          "other_data": order.toJson(),
          "file_name": fileName,
          "file_bytes": file
        };
        dynamic request = await _remoteData.postWithFile(suffixeO, map);
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
        dynamic request = await _remoteData.post(suffixeO, data);
        if (request.statusCode == 201) {
          request = jsonDecode(request.body);
          res = OrderSendModel.fromJson(request);
        } else {
          res = null;
        }
      } catch (e) {
        res = null;
      }
    }
    return res;
  }

  Future updateOrder(OrderSendModel order) async {
    OrderSendModel? res;
    String data = jsonEncode(order.toJson());
    try {
      dynamic request = await _remoteData.put(suffixeO, data, id: order.id);
      if (request.statusCode == 200) {
        request = jsonDecode(request.body);
        res = OrderSendModel.fromJson(request);
      }
    } catch (e) {
      res = null;
    }
    return res;
  }

  Future deleteOrder(int id) async {
    String suffixe = 'order_delete';
    try {
      dynamic request = await _remoteData.softDelete(suffixe, id);
      if (request.statusCode == 200) {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<UrssafModel>> getUrssaf() async {
    String suffixe = 'urssaf_events';
    try {
      dynamic response = await _remoteData.get(suffixe);
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
    String suffixe = 'qrcgen_csv';
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
    String suffixe = 'order';
    String urlAdd = 'summary';
    try {
      dynamic response = await _remoteData.get(suffixe,
          id: idOrder, urlAdd: urlAdd, bytesType: true);
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
