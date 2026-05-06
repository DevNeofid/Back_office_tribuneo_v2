import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/models/accounting_entries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';

class AccountingEntriesRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'accounting';

  Future createAccountingEntries() async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('$suffixe/entries/gen',
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

  Future<PaginatedResult<AccountingEntriesModel>> getAccountingEntries({
    int limit = 10,
    int offset = 0,
  }) async {
    List<AccountingEntriesModel> accountingEntries = [];
    int total = 0;
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(
        '${suffixe}/entries',
        overrideTenant: tenant,
        queryParams: {
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseMap = response.data;
        final List<dynamic> items =
            (responseMap['data']?['items'] as List<dynamic>?) ?? [];
        total = _extractTotal(responseMap, 0);
        for (var transferOrder in items) {
          accountingEntries.add(AccountingEntriesModel.fromJson(transferOrder));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      accountingEntries = [];
      total = 0;
    }
    return PaginatedResult<AccountingEntriesModel>(
      items: accountingEntries,
      total: total,
    );
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

  Future downloadFile(int id) async {
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get('$suffixe/entry/$id',
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
