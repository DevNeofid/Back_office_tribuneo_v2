import 'dart:convert';

import 'package:back_office_tribuneo_v2/domain/models/all_infos_customer_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/all_infos_partner_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/digital_partner_no_activity_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/network_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/qr_code_status_by_user_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/technical_support_order_model.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_account_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_activated_since_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_digital_never_open_session_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_unsettled_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/partner_total_amount_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/voucher_total_balance_per_customer_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/user_balance_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/sum_expired_vouchers_consumer_model.dart';
import 'package:flutter/foundation.dart';

class StatsRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'stats';

  Map<String, dynamic> _withCsvDownload(Map<String, dynamic>? queryParams) {
    final merged = <String, dynamic>{
      if (queryParams != null) ...queryParams,
      'download': 1,
    };
    return merged;
  }

  Future<String?> _downloadCsvData(
    String suffix, {
    Map<String, dynamic>? queryParams,
    dynamic body,
    bool usePost = false,
  }) async {
    final mergedQueryParams = _withCsvDownload(queryParams);

    try {
      final response = usePost
          ? await _remoteData.post(
              suffix,
              body,
              queryParams: mergedQueryParams,
              bytesType: true,
            )
          : await _remoteData.get(
              suffix,
              queryParams: mergedQueryParams,
              bytesType: true,
            );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List<int>) {
          return utf8.decode(response.data);
        }
        return response.data.toString();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return null;
  }

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
        print(e);
      }
    }

    return PaginatedResult<UserBalanceModel>(items: users, total: total);
  }

  Future<String?> getUsersPaginatedCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return _downloadCsvData(
      '$suffixe/users/balance',
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<List<UserBalanceModel>> getUsers() async {
    final result = await getUsersPaginated(limit: 1000, offset: 0);
    return result.items;
  }

  Future<List<PartnerAccountModel>> getPartnerAcc() async {
    List<PartnerAccountModel> partners = [];
    try {
      dynamic response = await _remoteData.get('$suffixe/partners_account');
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
        print(e);
      }
      partners = [];
    }
    return partners;
  }

  Future<List<PartnerUnsettledBalanceModel>> getPartnerUnBalance() async {
    List<PartnerUnsettledBalanceModel> balances = [];
    try {
      dynamic response =
          await _remoteData.get('$suffixe/partners/unsettled_balances');
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
        print(e);
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
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        queryParams = {'date': formattedDate};
      }

      dynamic response = await _remoteData.get(
        '$suffixe/partners/activated_since',
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
        print(e);
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
        print(e);
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
        print(e);
      }
    }

    return PaginatedResult<PartnerTotalAmountModel>(
        items: totals, total: total);
  }

  Future<String?> getPartnerTotalBalancesCsv(
    DateTime? dateFrom,
    DateTime? dateTo, {
    int limit = 10,
    int offset = 0,
  }) async {
    final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
    final DateTime effectiveEndDate = dateTo ?? DateTime.now();

    final Map<String, String> body = {
      'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
      'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
    };

    return _downloadCsvData(
      '$suffixe/entity/amount',
      body: body,
      usePost: true,
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
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
        '$suffixe/network',
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
        print(e);
      }
      totals = [];
    }

    return totals;
  }

  Future<String?> getNetworkTotalAmountsCsv(
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
    final DateTime effectiveEndDate = dateTo ?? DateTime.now();

    final Map<String, String> body = {
      'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
      'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
    };

    return _downloadCsvData(
      '$suffixe/network',
      body: body,
      usePost: true,
    );
  }

  Future<PaginatedResult<VoucherTotalBalancePerCustomerModel>>
      getVoucherTotalBalancesPerCustomerPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    List<VoucherTotalBalancePerCustomerModel> vouchers = [];
    int total = 0;

    try {
      dynamic response = await _remoteData.get(
        '$suffixe/total-balance-vouchers-per-customer',
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

        for (final item in items) {
          vouchers.add(VoucherTotalBalancePerCustomerModel.fromJson(
              Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return PaginatedResult<VoucherTotalBalancePerCustomerModel>(
      items: vouchers,
      total: total,
    );
  }

  Future<String?> getVoucherTotalBalancesPerCustomerCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return _downloadCsvData(
      '$suffixe/total-balance-vouchers-per-customer',
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<PaginatedResult<PartnerDigitalNeverOpenSessionModel>>
      getPartnerDigitalNeverOpenSessionPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    List<PartnerDigitalNeverOpenSessionModel> partners = [];
    int total = 0;

    try {
      dynamic response = await _remoteData.get(
        '$suffixe/partner-digital-never-open-session',
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

        for (final item in items) {
          partners.add(PartnerDigitalNeverOpenSessionModel.fromJson(
              Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return PaginatedResult<PartnerDigitalNeverOpenSessionModel>(
      items: partners,
      total: total,
    );
  }

  Future<String?> getPartnerDigitalNeverOpenSessionCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return _downloadCsvData(
      '$suffixe/partner-digital-never-open-session',
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<PaginatedResult<SumExpiredVouchersConsumerModel>>
      getSumExpiredVouchersConsumerPaginated({
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 10,
    int offset = 0,
  }) async {
    List<SumExpiredVouchersConsumerModel> consumers = [];
    int total = 0;

    try {
      final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
      final DateTime effectiveEndDate = dateTo ?? DateTime.now();

      final Map<String, String> body = {
        'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
        'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
      };

      dynamic response = await _remoteData.post(
        '$suffixe/sum-expired-vouchers-consumer',
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

        for (final item in items) {
          consumers.add(SumExpiredVouchersConsumerModel.fromJson(
              Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return PaginatedResult<SumExpiredVouchersConsumerModel>(
      items: consumers,
      total: total,
    );
  }

  Future<String?> getSumExpiredVouchersConsumerCsv({
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 10,
    int offset = 0,
  }) async {
    final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
    final DateTime effectiveEndDate = dateTo ?? DateTime.now();

    final Map<String, String> body = {
      'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
      'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
    };

    return _downloadCsvData(
      '$suffixe/sum-expired-vouchers-consumer',
      body: body,
      usePost: true,
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<PaginatedResult<DigitalPartnerNoActivityModel>>
      getDigitalPartnerNoActivityPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    List<DigitalPartnerNoActivityModel> partners = [];
    int total = 0;

    try {
      dynamic response = await _remoteData.get(
        '$suffixe/digital-partner-no-activity',
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

        for (final item in items) {
          partners.add(DigitalPartnerNoActivityModel.fromJson(
              Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return PaginatedResult<DigitalPartnerNoActivityModel>(
      items: partners,
      total: total,
    );
  }

  Future<String?> getDigitalPartnerNoActivityCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return _downloadCsvData(
      '$suffixe/digital-partner-no-activity',
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<PaginatedResult<AllInfosPartnerModel>> getAllInfosPartnersPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    List<AllInfosPartnerModel> partners = [];
    int total = 0;

    try {
      dynamic response = await _remoteData.get(
        '$suffixe/all-infos-partners',
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

        for (final item in items) {
          partners.add(AllInfosPartnerModel.fromJson(
              Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return PaginatedResult<AllInfosPartnerModel>(
      items: partners,
      total: total,
    );
  }

  Future<String?> getAllInfosPartnersCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return _downloadCsvData(
      '$suffixe/all-infos-partners',
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<PaginatedResult<AllInfosCustomerModel>>
      getAllInfosCustomersPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    List<AllInfosCustomerModel> customers = [];
    int total = 0;

    try {
      dynamic response = await _remoteData.get(
        '$suffixe/all-infos-customers',
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

        for (final item in items) {
          customers.add(AllInfosCustomerModel.fromJson(
              Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return PaginatedResult<AllInfosCustomerModel>(
      items: customers,
      total: total,
    );
  }

  Future<String?> getAllInfosCustomersCsv({
    int limit = 10,
    int offset = 0,
  }) async {
    return _downloadCsvData(
      '$suffixe/all-infos-customers',
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<PaginatedResult<TechnicalSupportOrderModel>>
      getTechnicalSupportOrdersPaginated(
    DateTime? dateFrom,
    DateTime? dateTo, {
    int limit = 10,
    int offset = 0,
  }) async {
    List<TechnicalSupportOrderModel> orders = [];
    int total = 0;

    try {
      final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
      final DateTime effectiveEndDate = dateTo ?? DateTime.now();

      final Map<String, String> body = {
        'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
        'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
      };

      dynamic response = await _remoteData.post(
        '$suffixe/all-order-on-technical-support',
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

        for (final item in items) {
          orders.add(TechnicalSupportOrderModel.fromJson(
              Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return PaginatedResult<TechnicalSupportOrderModel>(
      items: orders,
      total: total,
    );
  }

  Future<String?> getTechnicalSupportOrdersCsv(
    DateTime? dateFrom,
    DateTime? dateTo, {
    int limit = 10,
    int offset = 0,
  }) async {
    final DateTime effectiveStartDate = dateFrom ?? DateTime(2023, 1, 1);
    final DateTime effectiveEndDate = dateTo ?? DateTime.now();

    final Map<String, String> body = {
      'date_from': DateFormat('yyyy-MM-dd').format(effectiveStartDate),
      'date_to': DateFormat('yyyy-MM-dd').format(effectiveEndDate),
    };

    return _downloadCsvData(
      '$suffixe/all-order-on-technical-support',
      body: body,
      usePost: true,
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<PaginatedResult<QrCodeStatusByUserModel>>
      getAllQrCodeStatusByUserInfosPaginated({
    String? email,
    String? firstname,
    String? lastname,
    String? mobile,
    int limit = 10,
    int offset = 0,
  }) async {
    List<QrCodeStatusByUserModel> qrCodes = [];
    int total = 0;

    try {
      dynamic response = await _remoteData.post(
        '$suffixe/all-qrcode-status-by-user-infos',
        _qrCodeStatusByUserInfosBody(
          email: email,
          firstname: firstname,
          lastname: lastname,
          mobile: mobile,
        ),
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

        for (final item in items) {
          qrCodes.add(QrCodeStatusByUserModel.fromJson(
              Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    return PaginatedResult<QrCodeStatusByUserModel>(
      items: qrCodes,
      total: total,
    );
  }

  Future<String?> getAllQrCodeStatusByUserInfosCsv({
    String? email,
    String? firstname,
    String? lastname,
    String? mobile,
    int limit = 10,
    int offset = 0,
  }) async {
    return _downloadCsvData(
      '$suffixe/all-qrcode-status-by-user-infos',
      body: _qrCodeStatusByUserInfosBody(
        email: email,
        firstname: firstname,
        lastname: lastname,
        mobile: mobile,
      ),
      usePost: true,
      queryParams: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  /// L'API attend systématiquement les 4 clés de recherche : une chaîne vide
  /// signifie "pas de filtre sur ce champ".
  Map<String, String> _qrCodeStatusByUserInfosBody({
    String? email,
    String? firstname,
    String? lastname,
    String? mobile,
  }) {
    return {
      'email': email?.trim() ?? '',
      'firstname': firstname?.trim() ?? '',
      'lastname': lastname?.trim() ?? '',
      'mobile': normalizeMobileToE164(mobile),
    };
  }

  /// Les mobiles sont stockés au format international (+33...), alors que la
  /// saisie se fait le plus souvent au format national (06..., 06 12 34 ...).
  /// On normalise donc avant d'envoyer le filtre à l'API, sinon la recherche
  /// ne remonte rien. La saisie partielle est supportée (`061` -> `+3361`).
  static String normalizeMobileToE164(String? mobile) {
    if (mobile == null) return '';

    final String raw = mobile.trim();
    if (raw.isEmpty) return '';

    final bool hasPlus = raw.startsWith('+');
    final String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    if (hasPlus) return '+$digits';
    // 0033... : préfixe international "long"
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    // 06... : format national français
    if (digits.startsWith('0')) return '+33${digits.substring(1)}';
    // 336... : indicatif pays sans prefixe
    if (digits.startsWith('33')) return '+$digits';
    // 6... : numéro national sans le 0 initial
    return '+33$digits';
  }
}
