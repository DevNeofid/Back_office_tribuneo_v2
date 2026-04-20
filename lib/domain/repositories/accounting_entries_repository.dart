import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/accounting_entries_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';

class AccountingEntriesRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'accounting';

  Future createAccountingEntries() async {
    String suffixe = 'accounting/entries/gen';
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(suffixe,
          overrideTenant: tenant, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      return null;
    }
  }

  Future<List<AccountingEntriesModel>> getAccountingEntries() async {
    List<AccountingEntriesModel> accountingEntries = [];
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response =
          await _remoteData.get('${suffixe}/entries', overrideTenant: tenant);
      if (response.statusCode == 200) {
        response = response.data['data']['items'];
        for (var transferOrder in response) {
          accountingEntries.add(AccountingEntriesModel.fromJson(transferOrder));
        }
      } else {
        accountingEntries = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      accountingEntries = [];
    }
    return accountingEntries;
  }

  Future downloadFile(int id) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('${suffixe}/entry/$id',
          overrideTenant: tenant, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      return null;
    }
  }
}
