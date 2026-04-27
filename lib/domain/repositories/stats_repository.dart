import 'dart:convert';

import 'package:back_office_tribuneo_v2/domain/models/network_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_activated_since_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_unsettled_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_total_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_balance_model.dart';
import 'package:flutter/foundation.dart';

class StatsRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'stats';

  int _extractTotal(dynamic response, int fallback) {
    if (response is! Map) return fallback;

    int? parse(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final dynamic data = response['data'];
    if (data is Map) {
      final dynamic pagination = data['pagination'];
      final dynamic meta = data['meta'];
      final candidates = [
        data['total'],
        data['count'],
        data['total_items'],
        if (pagination is Map) pagination['total'],
        if (pagination is Map) pagination['count'],
        if (meta is Map) meta['total'],
        if (meta is Map) meta['count'],
      ];

      for (final candidate in candidates) {
        final parsed = parse(candidate);
        if (parsed != null) return parsed;
      }
    }

    return fallback;
  }

  Future<PaginatedResult<UserBalanceModel>> getUsersPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    List<UserBalanceModel> users = [];
    int total = 0;
    try {
      dynamic response = await _remoteData.get(
        '$suffixe/users/balance',
        queryParams: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = response.data;
        final List<dynamic> items =
            (responseBody['data']?['items'] as List<dynamic>?) ??
                (responseBody['data'] as List<dynamic>? ?? []);
        total = _extractTotal(responseBody, items.length);
        for (var user in items) {
          users.add(UserBalanceModel.fromJson(user));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
    }

    return PaginatedResult<UserBalanceModel>(items: users, total: total);
  }

  Future<List<UserBalanceModel>> getUsers() async {
    final result = await getUsersPaginated(limit: 1000, offset: 0);
    return result.items;
  }

  Future<List<PartnerAccountModel>> getPartnerAcc() async {
    List<PartnerAccountModel> partners = [];
    try {
      dynamic response = await _remoteData.get('${suffixe}/partners_account');
      if (response.statusCode == 200) {
        response = response.data;
        for (var partner in response) {
          partners.add(PartnerAccountModel.fromJson(partner));
        }
      } else {
        partners = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      partners = [];
    }
    return partners;
  }

  Future<List<PartnerUnsettledBalanceModel>> getPartnerUnBalance() async {
    List<PartnerUnsettledBalanceModel> balances = [];
    try {
      dynamic response =
          await _remoteData.get('${suffixe}/partners/unsettled_balances');
      if (response.statusCode == 200) {
        response = response.data;
        for (var balance in response) {
          balances.add(PartnerUnsettledBalanceModel.fromJson(balance));
        }
      } else {
        balances = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
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
        '${suffixe}/partners/activated_since',
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
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      actives = [];
    }
    return actives;
  }

  Future<List<PartnerTotalAmountModel>> getPartnerTotalBalances(
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    List<PartnerTotalAmountModel> totals = [];
    try {
      final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
      final DateTime effectiveEndDate = dateTo ?? DateTime.now();

      final Map<String, String> body = {
        'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
        'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
      };

      dynamic response = await _remoteData.post(
        '$suffixe/entity/amount',
        body,
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = response.data['data'] ?? [];
        for (var item in responseBody) {
          totals.add(PartnerTotalAmountModel.fromJson(item));
        }
      } else {
        totals = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      totals = [];
    }

    return totals;
  }

  Future<PaginatedResult<PartnerTotalAmountModel>>
      getPartnerTotalBalancesPaginated(
    DateTime? dateFrom,
    DateTime? dateTo, {
    int limit = 10,
    int offset = 0,
  }) async {
    List<PartnerTotalAmountModel> totals = [];
    int total = 0;
    try {
      final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
      final DateTime effectiveEndDate = dateTo ?? DateTime.now();

      final Map<String, String> body = {
        'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
        'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
      };

      dynamic response = await _remoteData.post(
        '$suffixe/entity/amount',
        body,
        queryParams: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = response.data;
        final List<dynamic> items =
            (responseBody['data']?['items'] as List<dynamic>?) ??
                (responseBody['data'] as List<dynamic>? ?? []);
        total = _extractTotal(responseBody, items.length);
        for (var item in items) {
          totals.add(PartnerTotalAmountModel.fromJson(item));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
    }

    return PaginatedResult<PartnerTotalAmountModel>(
        items: totals, total: total);
  }

  Future<List<NetworkTotalAmountModel>> getNetworkTotalAmounts(
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    List<NetworkTotalAmountModel> totals = [];
    try {
      final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
      final DateTime effectiveEndDate = dateTo ?? DateTime.now();

      final Map<String, String> body = {
        'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
        'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
      };

      dynamic response = await _remoteData.post(
        '$suffixe/network', // Correspond à stats/network
        body,
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = response.data['data'] ?? [];
        for (var item in responseBody) {
          totals.add(NetworkTotalAmountModel.fromJson(item));
        }
      } else {
        totals = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      totals = [];
    }

    return totals;
  }
}
