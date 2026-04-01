import 'dart:convert';

import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/accounting_entries_model.dart';

class AccountingEntriesRepository {
  final RemoteDataSource _remoteData = RemoteDataSource();

  final String suffixe = 'accounting_entries';

  Future createAccountingEntries() async {
    String suffixe = 'accounting_entries_gen';
    try {
      dynamic response = await _remoteData.get(suffixe, bytesType: true);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // return Result.error(errorMessage: e.toString());
      return null;
    }
  }

  Future<List<AccountingEntriesModel>> getAccountingEntries() async {
    List<AccountingEntriesModel> accountingEntries = [];
    try {
      dynamic response = await _remoteData.get(suffixe);
      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
        for (var transferOrder in response) {
          accountingEntries.add(AccountingEntriesModel.fromJson(transferOrder));
        }
      } else {
        accountingEntries = [];
      }
    } catch (e) {
      accountingEntries = [];
    }
    return accountingEntries;
  }

  Future downloadFile(int id) async {
    try {
      dynamic response =
          await _remoteData.get(suffixe, id: id, bytesType: true);
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
