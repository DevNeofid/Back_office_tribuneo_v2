import 'dart:convert';

import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_informations_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';

class BankInformationsRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();
  final String suffixe = 'bank-information';

  Future addBankInfo(BankInformationsModel bankInfo) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      String data = jsonEncode(bankInfo.toJson());
      final dynamic response =
          await _remoteData.post(suffixe, data, overrideTenant: tenant);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
            "Erreur lors de l'ajout des informations bancaires : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Erreur API addBankInfo: $e');
    }
  }

  Future updateBankInfo(BankInformationsModel bankInfo) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      String data = jsonEncode(bankInfo.toJson());
      final dynamic response = await _remoteData.put(suffixe, data,
          id: bankInfo.idEntity, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
            "Erreur lors de la mise à jour des informations bancaires : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Erreur API updateBankInfo: $e');
    }
  }
}
