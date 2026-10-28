import 'dart:math';
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
  /// Activation explicite à la compilation, sans clé ni JWT dans le navigateur.
  static const bool gatewayReady =
      bool.fromEnvironment('NEO_CHAT_ENABLED', defaultValue: false);
  static const bool demoEnabled =
      kDebugMode && bool.fromEnvironment('NEO_CHAT_DEMO', defaultValue: false);
  static const bool visible = gatewayReady || demoEnabled;

  factory AssistantRepository() => gatewayReady
      ? ApiAssistantRepository()
      : demoEnabled
          ? FakeAssistantRepository()
          : DisabledAssistantRepository();

  /// Crée une session de chat et retourne son identifiant.
  Future<String> createSession();

  Future<AssistantReply> sendMessage(String sessionId, String message);
}

/// Assistant désactivé : aucune réponse métier factice en production.
class DisabledAssistantRepository implements AssistantRepository {
  @override
  Future<String> createSession() async =>
      throw const AssistantException(AssistantErrorKind.unavailable);

  @override
  Future<AssistantReply> sendMessage(String sessionId, String message) async =>
      throw const AssistantException(AssistantErrorKind.unavailable);
}

/// Implémentation sur la passerelle authentifiée Tribuneo :
/// - `POST chat/sessions` → `{ "data": { "id": "…" } }`
/// - `POST chat/sessions/{id}/messages` `{ "message": "…", "request_id": "…" }` →
///   `{ "data": { "reply": { "text": "…", "blocks": [ … ] } } }`
class ApiAssistantRepository extends BaseRepository
    implements AssistantRepository {
  ApiAssistantRepository({
    Future<String> Function()? tenantResolver,
    Future<Response> Function(String, dynamic, String, Duration?)? post,
  })  : _tenantResolver = tenantResolver,
        _postOverride = post;

  final Future<String> Function()? _tenantResolver;
  final Future<Response> Function(String, dynamic, String, Duration?)?
      _postOverride;
  String? _requestKey;
  String? _requestId;

  static final RegExp _opaqueId = RegExp(r'^[a-f0-9]{32}$');

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
    if (id == null || !_opaqueId.hasMatch(id)) {
      throw const AssistantException(AssistantErrorKind.other);
    }
    return id;
  }

  @override
  Future<AssistantReply> sendMessage(String sessionId, String message) async {
    if (!_opaqueId.hasMatch(sessionId) ||
        message.trim().isEmpty ||
        message.runes.length > 1000) {
      throw const AssistantException(AssistantErrorKind.other);
    }
    final String key = '$sessionId\u0000$message';
    if (_requestKey != key) {
      final Random random = Random.secure();
      _requestId = List.generate(
              16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();
      _requestKey = key;
    }
    final Response response = await _post(
      'chat/sessions/$sessionId/messages',
      {'message': message, 'request_id': _requestId},
      receiveTimeout: _messageTimeout,
    );
    final dynamic data = response.data is Map ? response.data['data'] : null;
    final dynamic reply = data is Map ? data['reply'] : null;
    if (reply is! Map) {
      throw const AssistantException(AssistantErrorKind.other);
    }
    final AssistantReply result =
        AssistantReply.fromJson(Map<String, dynamic>.from(reply));
    _requestKey = null;
    _requestId = null;
    return result;
  }

  Future<Response> _post(String path, dynamic body,
      {Duration? receiveTimeout}) async {
    final Response response;
    try {
      final String tenant =
          await (_tenantResolver?.call() ?? getTenantForCurrentNetwork());
      if (tenant != 'tribuneo_cci04') {
        throw const AssistantException(AssistantErrorKind.unavailable);
      }
      response = _postOverride != null
          ? await _postOverride!(path, body, tenant, receiveTimeout)
          : await apiClient.post(path, body,
              overrideTenant: tenant, receiveTimeout: receiveTimeout);
    } on AssistantException {
      rethrow;
    } on DioException catch (e) {
      throw AssistantException(_kindForDioException(e));
    } catch (e) {
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
