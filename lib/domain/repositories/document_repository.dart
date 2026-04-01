import 'dart:convert';

import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/invoice_model.dart';

class DocumentRepository {
  LocalDataHelper localDataHelper = LocalDataHelper();
  final RemoteDataSource _remoteData = RemoteDataSource();

  final String suffixe = 'invoice';

  Future<List<InvoiceModel>> getInvoices(String type) async {
    List<InvoiceModel> invoices = [];
    Map<String, String> qs = {
      'type': type,
    };
    try {
      dynamic response = await _remoteData.get(suffixe, queryParams: qs);
      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
        for (var invoice in response) {
          invoices.add(InvoiceModel.fromJson(invoice));
        }
      } else {
        invoices = [];
      }
    } catch (e) {
      invoices = [];
    }
    return invoices;
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
