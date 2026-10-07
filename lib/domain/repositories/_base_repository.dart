import 'dart:convert';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/domain/models/result.dart';
import 'package:flutter/foundation.dart';
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
    if (idNetwork == null) {
      throw Exception('id_network introuvable dans la session utilisateur');
    }

    final String? savedNetworksJson = await storage.readSecureData('network');
    if (savedNetworksJson == null || savedNetworksJson.isEmpty) {
      throw Exception('Liste des réseaux absente du stockage local');
    }

    final dynamic decoded = jsonDecode(savedNetworksJson);

    final List<dynamic> networks =
        decoded is List ? decoded : (decoded is Map ? [decoded] : []);

    if (networks.isEmpty) {
      throw Exception('Format de la liste des réseaux invalide');
    }

    for (final dynamic network in networks) {
      if (network is! Map) continue;
      final Map<String, dynamic> networkMap =
          Map<String, dynamic>.from(network);
      final int? currentId = int.tryParse(networkMap['id']?.toString() ?? '');
      if (currentId == idNetwork) {
        final String dbName =
            (networkMap['db_name'] ?? networkMap['dbName'] ?? '')
                .toString()
                .trim();
        if (dbName.isNotEmpty) return dbName;
      }
    }

    throw Exception('Aucun tenant trouvé pour id_network $idNetwork');
  }

  /// Décode le corps d'une réponse en erreur et retourne le contenu de la clé `error`.
  /// Accepte un corps déjà décodé (Map), du texte ou des octets (requêtes en
  /// `bytesType`, où le JSON d'erreur arrive en octets et non en Map).
  Map<String, dynamic>? decodeApiError(dynamic data) {
    try {
      dynamic decoded = data;
      if (decoded is List<int>) {
        decoded = utf8.decode(decoded, allowMalformed: true);
      }
      if (decoded is String) {
        if (decoded.trim().isEmpty) return null;
        decoded = jsonDecode(decoded);
      }
      if (decoded is Map && decoded['error'] is Map) {
        return Map<String, dynamic>.from(decoded['error'] as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        print("###DEBUG### Corps d'erreur illisible: $e");
      }
    }
    return null;
  }
}
