import 'dart:convert';

import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/bto_preview_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/downloaded_file.dart';
import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TransferOrderRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'bto';

  Future<PaginatedResult<TransferOrderModel>> getOrders({
    int limit = 10,
    int offset = 0,
  }) async {
    List<TransferOrderModel> transferOrders = [];
    int total = 0;
    String tenant = await getTenantForCurrentNetwork();
    try {
      dynamic response = await _remoteData.get(
        suffixe,
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
        total = _extractTotal(responseMap, items.length);
        for (var transferOrder in items) {
          transferOrders.add(TransferOrderModel.fromJson(transferOrder));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      transferOrders = [];
      total = 0;
    }
    return PaginatedResult<TransferOrderModel>(
        items: transferOrders, total: total);
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
      dynamic response = await _remoteData.get(suffixe,
          id: id, bytesType: true, overrideTenant: tenant);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Aperçu du prochain virement. Ne crée rien, peut être appelé à volonté.
  /// [bankAccountCode] n'est envoyé que si l'écran propose un choix de compte payeur.
  Future<BtoPreviewModel> getPreview({String? bankAccountCode}) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.get('$suffixe/preview',
          queryParams:
              bankAccountCode == null ? null : {'bank_account': bankAccountCode},
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException("Impossible de charger l'aperçu du prochain virement.");
    }

    final dynamic body = response.data;
    if (response.statusCode == 200 && body is Map && body['data'] is Map) {
      return BtoPreviewModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    }

    final Map<String, dynamic>? error = decodeApiError(body);
    final String? code = apiErrorCode(error);
    throw ApiException(
        _btoMessage(code, response.statusCode) ??
            "Impossible de charger l'aperçu du prochain virement.",
        code: code);
  }

  /// Met une demande en attente : elle est écartée des virements jusqu'à sa
  /// libération. [reason] : 255 caractères maximum, facultatif.
  Future<void> holdRefund(String transactionNumber, {String? reason}) async {
    String tenant = await getTenantForCurrentNetwork();
    final String? trimmed = reason?.trim();
    dynamic response;
    try {
      response = await _remoteData.post(
          '$suffixe/refunds/${Uri.encodeComponent(transactionNumber)}/hold',
          jsonEncode({
            if (trimmed != null && trimmed.isNotEmpty) 'reason': trimmed,
          }),
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException('Erreur lors de la mise en attente de la demande.');
    }
    _throwOnHoldError(
        response, 'Erreur lors de la mise en attente de la demande.');
  }

  /// Libère une demande mise en attente (idempotent).
  Future<void> releaseRefund(String transactionNumber) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.delete(
          '$suffixe/refunds/${Uri.encodeComponent(transactionNumber)}/hold',
          null,
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException('Erreur lors de la libération de la demande.');
    }
    _throwOnHoldError(response, 'Erreur lors de la libération de la demande.');
  }

  void _throwOnHoldError(dynamic response, String fallback) {
    if (response.statusCode == 200) return;

    final Map<String, dynamic>? error = decodeApiError(response.data);
    final String? code = apiErrorCode(error);

    if (code == 'REFUND_ALREADY_PAID') {
      throw ApiException('Cette demande a déjà été payée.', code: code);
    }
    if (code == 'VALIDATION_ERROR') {
      throw ApiException('Le motif ne doit pas dépasser 255 caractères.',
          code: code);
    }
    if (response.statusCode == 404) {
      throw ApiException('Demande introuvable.', code: 'NOT_FOUND');
    }
    throw ApiException(_btoMessage(code, response.statusCode) ?? fallback,
        code: code);
  }

  /// Génère l'ordre de virement : l'API crée les justificatifs et factures
  /// manquants (une paire par demande), puis le fichier bancaire.
  /// [bankAccountCode] : le même compte que l'aperçu affiché, `null` sans select.
  ///
  /// Jamais relancé automatiquement : en cas d'expiration, l'état réel se lit en
  /// rechargeant l'aperçu.
  Future<BtoGenerationResult> generate({String? bankAccountCode}) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.get('$suffixe/gen',
          queryParams:
              bankAccountCode == null ? null : {'bank_account': bankAccountCode},
          bytesType: true,
          overrideTenant: tenant);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        throw ApiException(
            "La génération prend plus de temps que prévu. Rechargez l'aperçu "
            "avant de réessayer : le virement a peut-être été enregistré.",
            code: 'TIMEOUT');
      }
      throw ApiException(
          "Erreur réseau pendant la génération de l'ordre de virement. "
          "Rechargez l'aperçu avant de réessayer.");
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException(
          "Erreur lors de la génération de l'ordre de virement.");
    }

    if (response.statusCode == 200) {
      return BtoGenerationResult(
        bytes: (response.data as List).cast<int>(),
        filename: filenameFromHeaders(response),
        requestsPaid: _intHeader(response, 'x-requests-paid'),
        requestsExcluded: _intHeader(response, 'x-requests-excluded'),
      );
    }

    final Map<String, dynamic>? error = decodeApiError(response.data);
    final String? code = apiErrorCode(error);
    if (kDebugMode) {
      print('###DEBUG### ${error?['description']}');
    }
    // Vrai par construction : en cas d'échec, l'API n'enregistre aucun virement et
    // réutilise au prochain essai les documents déjà créés.
    if (response.statusCode >= 500) {
      throw ApiException(
          "La génération a échoué. Aucun virement n'a été enregistré, "
          'vous pouvez réessayer.',
          code: code);
    }
    throw ApiException(
        _btoMessage(code, response.statusCode) ??
            "Erreur lors de la génération de l'ordre de virement.",
        code: code);
  }

  /// Zip des documents (justificatif + facture) des demandes payées par le virement
  /// [id]. 404 pour les virements antérieurs au 14/10/2026.
  Future<DownloadedFile> downloadDocuments(int id) async {
    String tenant = await getTenantForCurrentNetwork();
    dynamic response;
    try {
      response = await _remoteData.get('$suffixe/$id/documents',
          bytesType: true, overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw ApiException(
          'Erreur lors du téléchargement des documents du virement.');
    }

    if (response.statusCode == 200) {
      return DownloadedFile(
        bytes: (response.data as List).cast<int>(),
        filename: filenameFromHeaders(response),
      );
    }

    final String? code = apiErrorCode(decodeApiError(response.data));
    if (response.statusCode == 404 || code == 'NO_DOCUMENTS') {
      throw ApiException('Aucun document disponible pour ce virement.',
          code: 'NO_DOCUMENTS');
    }
    if (response.statusCode == 502) {
      throw ApiException(
          'Le service de génération des PDF ne répond pas. Réessayez plus tard.');
    }
    throw ApiException(_btoMessage(code, response.statusCode) ??
        'Erreur lors du téléchargement des documents du virement.');
  }

  int? _intHeader(dynamic response, String name) {
    try {
      return int.tryParse(response.headers.value(name) ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Messages des refus attendus des routes de virement. `null` pour un code
  /// inconnu : l'appelant choisit son message générique, jamais la description
  /// anglaise de l'API.
  String? _btoMessage(String? code, int? statusCode) {
    switch (code) {
      case 'INSUFFICIENT_PRIVILEGES':
        return "Vous n'avez pas accès à ce réseau.";
      case 'NO_REFUND_TO_PAY':
        return 'Aucune demande à payer.';
      case 'BTO_GENERATION_IN_PROGRESS':
      case 'NUMBERING_BUSY':
        return 'Une génération est déjà en cours, réessayez dans un instant.';
      case 'MISSING_XML_PARAMS':
        return 'Le compte bancaire du réseau est incomplet, contactez le support.';
      case 'ZERO_TOTAL_AMOUNT':
        return 'Le montant total à virer est nul.';
      case 'UNKNOWN_BANK_ACCOUNT':
        return "Le compte bancaire choisi n'existe plus. "
            'La liste des comptes a été rechargée.';
      case 'BANK_ACCOUNT_LOCKED':
        // Ne doit pas arriver si l'écran respecte le verrou du réseau.
        return 'Ce réseau impose le compte payeur des ordres de virement. '
            'La liste des comptes a été rechargée.';
      case 'NO_DEFAULT_BANK_ACCOUNT':
        return "Aucun compte bancaire de remboursement n'est configuré pour ce "
            'réseau, contactez le support.';
      case 'MISSING_SELECTION_CUTOFF':
        return 'Configuration du réseau incomplète, contactez le support.';
    }
    if (statusCode == 403) return "Vous n'avez pas accès à ce réseau.";
    return null;
  }
}
