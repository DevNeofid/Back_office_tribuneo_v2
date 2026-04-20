import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';

class VoucherRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'voucher';

  Future<List> getVouchers() async {
    List invoices = [];
    // try {
    //   dynamic response = await _remoteData.get(suffixe, queryParams: qs);
    //   if (response.statusCode == 200) {
    //     response = jsonDecode(response.data);
    //     for (var invoice in response) {
    //       invoices.add(InvoiceModel.fromJson(invoice));
    //     }
    //   } else {
    //     invoices = [];
    //   }
    // } catch (e) {
    //   invoices = [];
    // }
    return invoices;
  }

  Future putVoucher(dynamic voucher, dynamic data) async {
    try {
      dynamic response = await _remoteData.put(suffixe, data);
      if (response.statusCode == 200) {
        return response;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
