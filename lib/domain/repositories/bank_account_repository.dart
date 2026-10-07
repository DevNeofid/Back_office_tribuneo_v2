import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';

class BankAccountRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  /// Comptes bancaires du réseau et verrous de choix du compte.
  Future<BankAccountsModel> getBankAccounts() async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.get('network/bank-accounts',
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException(
          'Impossible de charger les comptes bancaires du réseau.');
    }

    final dynamic data = response.data;
    if (response.statusCode == 200 && data is Map && data['data'] is Map) {
      return BankAccountsModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map));
    }

    if (kDebugMode) {
      print('###DEBUG### ${decodeApiError(data)?['description']}');
    }
    throw ApiException(
        'Impossible de charger les comptes bancaires du réseau.');
  }
}
