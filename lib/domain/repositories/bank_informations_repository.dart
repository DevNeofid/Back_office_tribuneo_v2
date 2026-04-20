import 'dart:convert';

import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_informations_model.dart';

class BankInformationsRepository {
  final ApiClient _remoteData = ApiClient();
  final String suffixe = 'bank-information';

  Future addBankInfo(BankInformationsModel bankInfo) async {
    String data = jsonEncode(bankInfo.toJson());
    await _remoteData.post(suffixe, data);
    return;
  }

  Future updateBankInfo(BankInformationsModel bankInfo) async {
    String data = jsonEncode(bankInfo.toJson());
    await _remoteData.put(suffixe, data, id: bankInfo.idEntity);
    return;
  }
}
