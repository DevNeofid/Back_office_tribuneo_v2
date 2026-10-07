import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/errors/accounting_entries_config_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/accounting_entries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:flutter/foundation.dart';

class AccountingEntriesRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'accounting';

  Future createAccountingEntries() async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.get('$suffixe/entries/gen',
          overrideTenant: tenant, bytesType: true);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      return null;
    }

    if (response.statusCode == 200) {
      return response.data;
    }

    final Map<String, dynamic>? error = decodeApiError(response.data);
    final dynamic details = error?['details'];

    // Un compte bancaire utilisé sur la période n'a pas de journal ou de compte 512 :
    // l'API donne la liste des manques, on la remonte pour l'afficher.
    if (details is Map && details['errors'] is List) {
      final List<String> errors = (details['errors'] as List<dynamic>)
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
      if (errors.isNotEmpty) {
        throw AccountingEntriesConfigException(errors);
      }
    }

    if (kDebugMode) {
      print('###DEBUG### ${error?['description']}');
    }
    return null;
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
