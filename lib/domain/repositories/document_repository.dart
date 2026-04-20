import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/invoice_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';

class DocumentRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'accounting/invoice';

  Future<List<InvoiceModel>> getInvoices(String type) async {
    List<InvoiceModel> invoices = [];
    String tenant = await getTenantForCurrentNetwork();
    Map<String, String> params = {
      'type': type,
    };
    try {
      dynamic response = await _remoteData.get(suffixe,
          queryParams: params, overrideTenant: tenant);
      if (response.statusCode == 200) {
        List<dynamic> invoicesList = response.data['data'];
        for (var invoice in invoicesList) {
          invoices.add(InvoiceModel.fromJson(invoice));
        }
      } else {
        invoices = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
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
