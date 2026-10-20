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

  /// Code machine d'une erreur décodée par [decodeApiError] : `error.details.code`,
  /// à défaut `error.type`. C'est sur lui que s'appuie le front, jamais sur
  /// `description` (texte anglais destiné aux logs).
  String? apiErrorCode(Map<String, dynamic>? error) {
    final dynamic details = error?['details'];
    final String? code = details is Map ? details['code']?.toString() : null;
    if (code != null && code.isNotEmpty) return code;
    final String? type = error?['type']?.toString();
    return type == null || type.isEmpty ? null : type;
  }

  /// Message des refus d'accès au réseau (`X-Tenant` d'un réseau auquel
  /// l'utilisateur n'est pas rattaché), `null` pour tout autre code.
  ///
  /// Ce 403 n'est pas une session expirée : on ne déconnecte pas, on invite
  /// l'utilisateur à le faire.
  String? tenantErrorMessageForCode(String? code) {
    switch (code) {
      case 'TENANT_FORBIDDEN':
      case 'UNKNOWN_TENANT':
        return "Vous n'avez pas accès à ce réseau. "
            'Déconnectez-vous puis reconnectez-vous.';
      default:
        return null;
    }
  }

  /// Messages des refus liés à l'en-tête `Idempotency-Key`, `null` pour tout
  /// autre code.
  String? idempotencyMessageForCode(String? code) {
    switch (code) {
      case 'IDEMPOTENCY_REQUEST_IN_PROGRESS':
        return "L'enregistrement précédent est encore en cours. "
            'Patientez quelques secondes.';
      case 'IDEMPOTENCY_KEY_RETRY':
        return "L'enregistrement précédent a échoué. Réessayez.";
      case 'IDEMPOTENCY_KEY_REUSED':
      case 'IDEMPOTENCY_KEY_INVALID':
        return 'Une erreur technique est survenue. Réessayez.';
      default:
        return null;
    }
  }

  /// [tenantErrorMessageForCode] appliqué au corps d'une réponse en erreur.
  String? tenantErrorMessage(dynamic response) =>
      tenantErrorMessageForCode(apiErrorCode(decodeApiError(response.data)));

  /// `error.details` sous forme de Map (vide si absent).
  Map<String, dynamic> apiErrorDetails(Map<String, dynamic>? error) {
    final dynamic details = error?['details'];
    return details is Map ? Map<String, dynamic>.from(details) : {};
  }

  /// Nom de fichier annoncé par l'en-tête `Content-Disposition`, s'il est lisible.
  String? filenameFromHeaders(dynamic response) {
    try {
      final String? contentDisposition =
          response.headers.value('content-disposition');
      if (contentDisposition == null) return null;
      final RegExpMatch? match =
          RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
              .firstMatch(contentDisposition);
      final String? filename = match?.group(1)?.trim();
      return filename == null || filename.isEmpty ? null : filename;
    } catch (_) {
      return null;
    }
  }
}
