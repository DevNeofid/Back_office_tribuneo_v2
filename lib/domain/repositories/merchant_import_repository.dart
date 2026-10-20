import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:back_office_tribuneo_v2/data/remote/api_client.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/errors/merchant_import_exceptions.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_batch_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/_base_repository.dart';

/// Import assisté des commerçants (rôle `NETWORK_ADMIN`, `X-Tenant` obligatoire).
class MerchantImportRepository extends BaseRepository {
  final ApiClient _remoteData = ApiClient();

  final String suffixe = 'merchant-import';

  /// Message des erreurs réseau et 5xx d'un `PATCH` : la vue retente seule.
  static const String saveRetryMessage =
      'Enregistrement impossible, nouvel essai…';

  /// Crée un lot depuis un fichier `.csv` (séparateur `;`) ou `.xlsx`. Le lot
  /// revient déjà en relecture.
  Future<MerchantImportBatch> createFromFile({
    required String fileName,
    required String fileBase64,
    String? idempotencyKey,
  }) async {
    const String fallback = 'Erreur lors de la lecture du fichier.';
    final dynamic response = await _send(
      fallback,
      (tenant) => _remoteData.post(
          suffixe,
          jsonEncode({
            'source_type': 'file',
            'file_name': fileName,
            'file_bytes': fileBase64,
          }),
          overrideTenant: tenant,
          headers: idempotencyKey == null
              ? null
              : {'Idempotency-Key': idempotencyKey}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return MerchantImportBatch.fromJson(_dataMap(response));
    }
    throw _error(response, fallback);
  }

  /// Lots du réseau, du plus récent au plus ancien.
  Future<List<MerchantImportBatch>> getBatches(
      {int limit = 20, int offset = 0}) async {
    const String fallback = 'Impossible de charger les lots.';
    final dynamic response = await _send(
      fallback,
      (tenant) => _remoteData.get(suffixe,
          queryParams: {'limit': limit, 'offset': offset},
          overrideTenant: tenant),
    );
    if (response.statusCode == 200) {
      return _dataList(response)
          .map((item) => MerchantImportBatch.fromJson(item))
          .toList();
    }
    throw _error(response, fallback);
  }

  Future<MerchantImportBatch> getBatch(int id) async {
    const String fallback = 'Impossible de charger le lot.';
    final dynamic response = await _send(
      fallback,
      (tenant) => _remoteData.get('$suffixe/$id', overrideTenant: tenant),
    );
    if (response.statusCode == 200) {
      return MerchantImportBatch.fromJson(_dataMap(response));
    }
    throw _error(response, fallback);
  }

  /// Toutes les lignes du lot (2 000 au plus), triées par position. Le filtrage
  /// et la pagination se font côté écran.
  Future<List<MerchantImportRow>> getRows(int id, {String? status}) async {
    const String fallback = 'Impossible de charger les lignes du lot.';
    final dynamic response = await _send(
      fallback,
      (tenant) => _remoteData.get('$suffixe/$id/rows',
          queryParams: status == null ? null : {'status': status},
          overrideTenant: tenant),
    );
    if (response.statusCode == 200) {
      return _dataList(response)
          .map((item) => MerchantImportRow.fromJson(item))
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
    }
    throw _error(response, fallback);
  }

  /// Enregistre une cellule (`version`, `field`, `value`) ou un statut
  /// (`version`, `status`).
  ///
  /// Lève [MerchantImportConflict] pour `VERSION_CONFLICT` et `ROW_HAS_ERRORS`,
  /// [MerchantImportTransientError] pour une erreur réseau ou 5xx (à retenter).
  Future<MerchantImportPatchResult> patchRow(
      int id, int rowId, Map<String, dynamic> body) async {
    dynamic response;
    try {
      final String tenant = await getTenantForCurrentNetwork();
      response = await _remoteData.patch(
          '$suffixe/$id/rows/$rowId', jsonEncode(body),
          overrideTenant: tenant);
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw MerchantImportTransientError(saveRetryMessage);
    }
    if (response.statusCode == 200) {
      return MerchantImportPatchResult.fromJson(_dataMap(response));
    }
    throw _error(response, saveRetryMessage);
  }

  /// Importe les lignes cochées. Peut prendre plusieurs dizaines de secondes.
  Future<MerchantImportResult> importValidated(int id,
      {String? idempotencyKey}) async {
    const String fallback = "Erreur lors de l'import des commerçants.";
    final dynamic response = await _send(
      fallback,
      (tenant) => _remoteData.post('$suffixe/$id/import', jsonEncode({}),
          overrideTenant: tenant,
          headers: idempotencyKey == null
              ? null
              : {'Idempotency-Key': idempotencyKey}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return MerchantImportResult.fromJson(_dataMap(response));
    }
    throw _error(response, fallback);
  }

  /// Abandonne le lot : il passe en `cancelled` et n'est plus modifiable.
  Future<void> cancel(int id) async {
    const String fallback = "Erreur lors de l'abandon du lot.";
    final dynamic response = await _send(
      fallback,
      (tenant) => _remoteData.delete(suffixe, id, overrideTenant: tenant),
    );
    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw _error(response, fallback);
  }

  /// Envoie la requête avec le tenant du réseau courant. Une erreur réseau
  /// devient une [MerchantImportTransientError] sans code : la clé
  /// d'idempotence éventuelle est alors gardée.
  Future<dynamic> _send(
      String fallback, Future<dynamic> Function(String tenant) request) async {
    try {
      return await request(await getTenantForCurrentNetwork());
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### Error: $e');
      }
      throw MerchantImportTransientError(fallback);
    }
  }

  Map<String, dynamic> _dataMap(dynamic response) {
    final dynamic body = response.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }

  /// `data` est une liste, ou un objet paginé `{ items: [...] }`.
  List<Map<String, dynamic>> _dataList(dynamic response) {
    final dynamic body = response.data;
    dynamic data = body is Map ? body['data'] : body;
    if (data is Map) data = data['items'] ?? data['rows'] ?? data['batches'];
    return (data is List ? data : const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Exception à lever pour une réponse en erreur, message français selon le
  /// code (§ 4 de la spec), jamais `description`.
  ApiException _error(dynamic response, String fallback) {
    final Map<String, dynamic>? error = decodeApiError(response.data);
    final String? code = apiErrorCode(error);
    final Map<String, dynamic> details = apiErrorDetails(error);
    final int status = response.statusCode ?? 0;
    if (kDebugMode) {
      print('###DEBUG### [$status] $code ${error?['description']}');
    }

    if (code == 'VERSION_CONFLICT' || code == 'ROW_HAS_ERRORS') {
      final dynamic row = details['row'];
      return MerchantImportConflict(
        code == 'ROW_HAS_ERRORS'
            ? 'Corrigez les anomalies de la ligne avant de la valider.'
            : "Cette cellule vient d'être modifiée par quelqu'un d'autre : sa "
                'valeur a été rechargée.',
        code: code,
        row: row is Map
            ? MerchantImportRow.fromJson(Map<String, dynamic>.from(row))
            : null,
        issues: MerchantImportIssue.listFromJson(details['issues']),
      );
    }

    final String? message = idempotencyMessageForCode(code) ??
        tenantErrorMessageForCode(code) ??
        _messageForCode(code);
    if (message != null) return ApiException(message, code: code);

    if (status >= 500) {
      return MerchantImportTransientError(fallback, code: code);
    }
    return ApiException(fallback, code: code);
  }

  String? _messageForCode(String? code) {
    switch (code) {
      case 'BATCH_NOT_EDITABLE':
        return "Ce lot n'est plus modifiable (import terminé ou lot "
            'abandonné).';
      case 'ROW_IMPORTED':
        return 'Cette ligne est déjà importée : modifiez la fiche du '
            'commerçant.';
      case 'BATCH_NOT_IMPORTABLE':
        return 'Un import est déjà en cours sur ce lot, ou il est terminé.';
      case 'NOTHING_TO_IMPORT':
        return 'Aucune ligne validée à importer.';
      case 'BATCH_NOT_CANCELLABLE':
        return 'Ce lot ne peut plus être abandonné.';
      case 'BATCH_NOT_FOUND':
      case 'ROW_NOT_FOUND':
        return "Ce lot n'existe plus.";
      case 'FILE_INVALID':
        return 'Fichier illisible : seuls les fichiers .csv (séparateur ;) et '
            '.xlsx sont acceptés.';
      case 'EMPTY_SOURCE':
        return 'Le fichier ne contient aucune ligne.';
      case 'TOO_MANY_ROWS':
        return 'Le fichier dépasse 2 000 lignes : découpez-le en plusieurs '
            'fichiers.';
      case 'FIELD_NOT_EDITABLE':
      case 'STATUS_INVALID':
      case 'PATCH_INVALID':
      case 'VERSION_REQUIRED':
      case 'SOURCE_INVALID':
        // Bug front : la requête envoyée ne respecte pas le contrat.
        debugPrint('[MerchantImport] Requête refusée par l\'API : $code');
        return 'Une erreur technique est survenue. Réessayez.';
      default:
        return null;
    }
  }
}
