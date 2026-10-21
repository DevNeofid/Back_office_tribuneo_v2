import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:back_office_tribuneo_v2/domain/errors/assistant_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/fake_assistant_repository.dart';

/// Passerelle `/chat` de l'assistant.
///
/// Toute erreur est levée en [AssistantException], déjà classée pour l'affichage.
abstract class AssistantRepository {
  /// La passerelle `/chat` (prérequis P2) n'est pas encore développée : tant
  /// que ce drapeau est faux, l'assistant répond avec [FakeAssistantRepository].
  static const bool gatewayReady = false;

  factory AssistantRepository() =>
      gatewayReady ? ApiAssistantRepository() : FakeAssistantRepository();

  /// Crée une session de chat et retourne son identifiant.
  Future<String> createSession();

  Future<AssistantReply> sendMessage(String sessionId, String message);
}

/// Implémentation sur le contrat **provisoire** du § 7 de la spec (à aligner
/// avec P2) :
/// - `POST chat/sessions` → `{ "data": { "id": "…" } }`
/// - `POST chat/sessions/{id}/messages` `{ "message": "…" }` →
///   `{ "data": { "reply": { "text": "…", "blocks": [ … ] } } }`
class ApiAssistantRepository extends BaseRepository
    implements AssistantRepository {
  /// La réponse passe par la boucle d'outils de l'agent : elle peut être longue.
  static const Duration _messageTimeout = Duration(seconds: 90);

  /// Codes provisoires du quota mensuel atteint (§ 10.1 de la spec Hermes).
  static const Set<String> _quotaCodes = {
    'ASSISTANT_QUOTA_EXCEEDED',
    'CHAT_QUOTA_EXCEEDED',
  };

  @override
  Future<String> createSession() async {
    final Response response = await _post('chat/sessions', null);
    final dynamic data = response.data is Map ? response.data['data'] : null;
    final String? id = data is Map ? data['id']?.toString() : null;
    if (id == null || id.isEmpty) {
      throw const AssistantException(AssistantErrorKind.other);
    }
    return id;
  }

  @override
  Future<AssistantReply> sendMessage(String sessionId, String message) async {
    final Response response = await _post(
      'chat/sessions/$sessionId/messages',
      {'message': message},
      receiveTimeout: _messageTimeout,
    );
    final dynamic data = response.data is Map ? response.data['data'] : null;
    final dynamic reply = data is Map ? data['reply'] : null;
    if (reply is! Map) {
      throw const AssistantException(AssistantErrorKind.other);
    }
    return AssistantReply.fromJson(Map<String, dynamic>.from(reply));
  }

  Future<Response> _post(String path, dynamic body,
      {Duration? receiveTimeout}) async {
    final Response response;
    try {
      final String tenant = await getTenantForCurrentNetwork();
      response = await apiClient.post(path, body,
          overrideTenant: tenant, receiveTimeout: receiveTimeout);
    } on DioException catch (e) {
      throw AssistantException(_kindForDioException(e));
    } catch (e) {
      if (kDebugMode) print('###DEBUG### Assistant $path : $e');
      throw const AssistantException(AssistantErrorKind.other);
    }
    final int status = response.statusCode ?? 0;
    if (status == 200 || status == 201) return response;
    throw AssistantException(_kindForResponse(response));
  }

  AssistantErrorKind _kindForResponse(Response response) {
    final int status = response.statusCode ?? 0;
    // Le 401 a déjà été traité par l'ApiClient (refresh, ou retour à la
    // connexion si la session est morte).
    if (status == 401) return AssistantErrorKind.sessionExpired;
    if (_quotaCodes.contains(apiErrorCode(decodeApiError(response.data)))) {
      return AssistantErrorKind.quota;
    }
    if (status == 429 || status == 502 || status == 503) {
      return AssistantErrorKind.unavailable;
    }
    return AssistantErrorKind.other;
  }

  AssistantErrorKind _kindForDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AssistantErrorKind.unavailable;
      case DioExceptionType.cancel:
        // Annulée par l'ApiClient quand la session a expiré.
        return AssistantErrorKind.sessionExpired;
      case DioExceptionType.badResponse:
        // 504 : rejeté par validateStatus.
        return AssistantErrorKind.unavailable;
      default:
        return AssistantErrorKind.other;
    }
  }
}
