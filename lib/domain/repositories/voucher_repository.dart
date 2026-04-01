
import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';

class VoucherRepository {
  LocalDataHelper localDataHelper = LocalDataHelper();
  final RemoteDataSource _remoteData = RemoteDataSource();

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
