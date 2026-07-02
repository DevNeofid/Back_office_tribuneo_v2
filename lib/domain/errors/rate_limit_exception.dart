import 'dart:convert';

import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';

/// Réponse HTTP 429 du rate limiter (RateLimitMiddleware côté API).
/// Format spécifique : {"error": "RATE_LIMITED", "reason": ..., "retry_after_seconds": ..., "retry_at": ...}
/// Différent des erreurs API standards — ne pas passer dans le parseur d'erreur habituel.
class RateLimitException extends ApiException {
  /// "QUOTA_EXCEEDED" (limite tout juste dépassée) ou "LOCKED_OUT" (compte déjà gelé).
  final String reason;

  /// Secondes restantes avant déblocage.
  final int retryAfterSeconds;

  /// Date de déblocage (ISO 8601), si fournie par l'API.
  final DateTime? retryAt;

  RateLimitException({
    required this.reason,
    required this.retryAfterSeconds,
    this.retryAt,
  }) : super('Trop de tentatives de connexion');

  /// Construit l'exception depuis le body d'une réponse 429 (Map déjà décodée
  /// par Dio, ou String JSON brute). Tolère un body absent ou malformé.
  factory RateLimitException.fromResponse(dynamic data) {
    Map<String, dynamic>? body;
    if (data is Map) {
      body = Map<String, dynamic>.from(data);
    } else if (data is String && data.isNotEmpty) {
      try {
        body = Map<String, dynamic>.from(jsonDecode(data) as Map);
      } catch (_) {}
    }

    return RateLimitException(
      reason: body?['reason']?.toString() ?? 'QUOTA_EXCEEDED',
      retryAfterSeconds:
          (body?['retry_after_seconds'] as num?)?.toInt() ?? 900,
      retryAt: DateTime.tryParse(body?['retry_at']?.toString() ?? ''),
    );
  }

  /// Message prêt à afficher à l'utilisateur, avec le temps restant.
  String get userMessage {
    if (retryAfterSeconds >= 60) {
      final minutes = (retryAfterSeconds / 60).ceil();
      return 'Trop de tentatives de connexion. '
          'Veuillez réessayer dans $minutes minute${minutes > 1 ? 's' : ''}.';
    }
    return 'Trop de tentatives de connexion. '
        'Veuillez réessayer dans $retryAfterSeconds seconde${retryAfterSeconds > 1 ? 's' : ''}.';
  }
}
