import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/data/remote/remote_data_source.dart';
import 'package:tribuneo_backoffice/domain/models/partner_account_model.dart';
import 'package:tribuneo_backoffice/domain/models/partner_activated_since_model.dart';
import 'package:tribuneo_backoffice/domain/models/partner_unsettled_balance_model.dart';
import 'package:tribuneo_backoffice/domain/models/user_balance_model.dart';

class StatsRepository {
  final RemoteDataSource _remoteData = RemoteDataSource();

  final String suffixe = 'stats/';

  Future<List<UserBalanceModel>> getUsers() async {
    List<UserBalanceModel> users = [];
    try {
      dynamic response = await _remoteData.get('${suffixe}users/balance');
      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
        for (var user in response) {
          users.add(UserBalanceModel.fromJson(user));
        }
      } else {
        users = [];
      }
    } catch (e) {
      users = [];
    }
    return users;
  }

  Future<List<PartnerAccountModel>> getPartnerAcc() async {
    List<PartnerAccountModel> partners = [];
    try {
      dynamic response = await _remoteData.get('${suffixe}partners_account');
      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
        for (var partner in response) {
          partners.add(PartnerAccountModel.fromJson(partner));
        }
      } else {
        partners = [];
      }
    } catch (e) {
      partners = [];
    }
    return partners;
  }

  Future<List<PartnerUnsettledBalanceModel>> getPartnerUnBalance() async {
    List<PartnerUnsettledBalanceModel> balances = [];
    try {
      dynamic response =
          await _remoteData.get('${suffixe}partners/unsettled_balances');
      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
        for (var balance in response) {
          balances.add(PartnerUnsettledBalanceModel.fromJson(balance));
        }
      } else {
        balances = [];
      }
    } catch (e) {
      balances = [];
    }
    return balances;
  }

  Future<List<PartnerActivatedSinceModel>> getPartnerActivated(
      DateTime? date) async {
    List<PartnerActivatedSinceModel> actives = [];
    try {
      Map<String, String>? queryParams;
      if (date != null) {
        // Format date as a string 'yyyy-MM-dd'
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        // Prepare the query parameters
        queryParams = {'date': formattedDate};
      }

      // Pass the queryParams to the get method
      dynamic response = await _remoteData.get(
        '${suffixe}partners/activated_since',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        response = jsonDecode(response.data);
        for (var active in response) {
          actives.add(PartnerActivatedSinceModel.fromJson(active));
        }
      } else {
        actives = [];
      }
    } catch (e) {
      actives = [];
    }
    return actives;
  }
}
