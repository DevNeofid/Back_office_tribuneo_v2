import 'dart:convert';

import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/bank_informations_model.dart';

class BankInformationsRepository {
  final RemoteDataSource _remoteData = RemoteDataSource();
  LocalDataHelper localDataHelper = LocalDataHelper();
  final String suffixe = 'bank_infos';

  // Function to add a new customer
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
