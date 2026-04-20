import 'dart:convert';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/domain/models/result.dart';
import 'package:http/http.dart';

abstract class BaseRepository {
  final ApiClient apiClient = ApiClient();
  final StorageService storage = StorageService();
  final StorageFunction storageFunction = StorageFunction();

  Future<Result<T>> handleResponse<T>(
    Response response, {
    T Function(dynamic)? parser,
  }) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Result.success(data: parser != null ? parser(data) : data);
    } else {
      return Result.error(
        errorMessage:
            'Erreur ${response.statusCode} : ${response.reasonPhrase}',
      );
    }
  }

  Future<String?> getToken() async => await storage.readSecureData('token');

  Future<String> getTenantForCurrentNetwork() async {
    String? tmpIdNetwork = await storage.readSecureData('user_id_network');
    int? idNetwork = int.tryParse(tmpIdNetwork ?? '');
    return await getTenantByNetworkId(idNetwork);
  }

  Future<String> getTenantByNetworkId(int? idNetwork) async {
    const String fallbackTenant = 'tribuneo_cci04';

    try {
      final String? savedNetworksJson = await storage.readSecureData(
        'network',
      );
      if (savedNetworksJson == null || savedNetworksJson.isEmpty) {
        return fallbackTenant;
      }

      final dynamic decoded = jsonDecode(savedNetworksJson);
      if (decoded is! List) {
        return fallbackTenant;
      }

      for (final dynamic network in decoded) {
        if (network is! Map) continue;

        final Map<String, dynamic> networkMap = Map<String, dynamic>.from(
          network,
        );
        final int? currentId = int.tryParse(networkMap['id']?.toString() ?? '');

        if (currentId == idNetwork) {
          final String dbName =
              (networkMap['db_name'] ?? networkMap['dbName'] ?? '')
                  .toString()
                  .trim();
          if (dbName.isNotEmpty) {
            return dbName;
          }
          break;
        }
      }
    } catch (_) {
      // Fallback si le stockage est absent/corrompu.
    }

    return fallbackTenant;
  }
}
