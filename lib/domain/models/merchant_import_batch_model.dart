/// Un lot d'import assisté de commerçants (`/merchant-import`).
class MerchantImportBatch {
  static const String statusQueued = 'queued';
  static const String statusRunning = 'running';
  static const String statusReview = 'review';
  static const String statusImporting = 'importing';
  static const String statusDone = 'done';
  static const String statusFailed = 'failed';
  static const String statusCancelled = 'cancelled';

  final int id;

  /// `file` aujourd'hui ; plus tard `names` et `url` (recherche par l'IA).
  final String sourceType;

  /// Nom du fichier pour la source `file`.
  final String? source;
  final String status;
  final int progressDone;
  final int progressTotal;
  final String? error;
  final int? idUser;
  final String? createdDate;
  final String? updatedDate;
  final int rowsPending;
  final int rowsValidated;
  final int rowsRejected;
  final int rowsImported;
  final int rowsFailed;
  final int rowsWithErrors;

  const MerchantImportBatch({
    required this.id,
    this.sourceType = 'file',
    this.source,
    required this.status,
    this.progressDone = 0,
    this.progressTotal = 0,
    this.error,
    this.idUser,
    this.createdDate,
    this.updatedDate,
    this.rowsPending = 0,
    this.rowsValidated = 0,
    this.rowsRejected = 0,
    this.rowsImported = 0,
    this.rowsFailed = 0,
    this.rowsWithErrors = 0,
  });

  factory MerchantImportBatch.fromJson(Map<String, dynamic> json) {
    return MerchantImportBatch(
      id: _int(json['id']) ?? 0,
      sourceType: json['source_type']?.toString() ?? 'file',
      source: json['source']?.toString(),
      status: json['status']?.toString() ?? '',
      progressDone: _int(json['progress_done']) ?? 0,
      progressTotal: _int(json['progress_total']) ?? 0,
      error: json['error']?.toString(),
      idUser: _int(json['id_user']),
      createdDate: json['created_date']?.toString(),
      updatedDate: json['updated_date']?.toString(),
      rowsPending: _int(json['rows_pending']) ?? 0,
      rowsValidated: _int(json['rows_validated']) ?? 0,
      rowsRejected: _int(json['rows_rejected']) ?? 0,
      rowsImported: _int(json['rows_imported']) ?? 0,
      rowsFailed: _int(json['rows_failed']) ?? 0,
      rowsWithErrors: _int(json['rows_with_errors']) ?? 0,
    );
  }

  /// Seul un lot en relecture peut être modifié ou importé.
  bool get isEditable => status == statusReview;

  /// Recherche en cours (sources IA, étapes 2-3) : grille en lecture seule.
  bool get isProcessing => status == statusQueued || status == statusRunning;

  bool get isDone => status == statusDone;
  bool get isCancelled => status == statusCancelled;

  String get statusLabel {
    switch (status) {
      case statusReview:
        return 'En relecture';
      case statusImporting:
        return 'Import en cours';
      case statusDone:
        return 'Terminé';
      case statusCancelled:
        return 'Abandonné';
      case statusQueued:
      case statusRunning:
        return 'Recherche en cours';
      case statusFailed:
        return 'Échec';
      default:
        return status;
    }
  }

  /// « 15 validées · 31 en anomalie · 120 à relire · 0 importées ».
  String get progressLabel => '$rowsValidated validées · $rowsWithErrors en '
      'anomalie · $rowsPending à relire · $rowsImported importées';
}

/// Une ligne en échec renvoyée par `POST /merchant-import/{id}/import`.
class MerchantImportFailure {
  final int id;
  final String error;

  const MerchantImportFailure({required this.id, required this.error});
}

/// Réponse de `POST /merchant-import/{id}/import`.
class MerchantImportResult {
  /// Lot à jour, `null` si l'API ne l'a pas renvoyé.
  final MerchantImportBatch? batch;

  /// Lignes importées.
  final int imported;

  /// Parmi elles, entités créées (les autres ont été rattachées à une entité
  /// existante de même SIRET).
  final int created;
  final List<MerchantImportFailure> failed;

  /// Lignes cochées devenues bloquantes depuis : l'API les a décochées.
  final List<int> skipped;

  const MerchantImportResult({
    this.batch,
    this.imported = 0,
    this.created = 0,
    this.failed = const [],
    this.skipped = const [],
  });

  factory MerchantImportResult.fromJson(Map<String, dynamic> json) {
    final dynamic batch = json['batch'];
    return MerchantImportResult(
      batch: batch is Map
          ? MerchantImportBatch.fromJson(Map<String, dynamic>.from(batch))
          : null,
      imported: _int(json['imported']) ?? 0,
      created: _int(json['created']) ?? 0,
      failed: (json['failed'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => MerchantImportFailure(
                id: _int(item['id']) ?? 0,
                error: item['error']?.toString() ?? '',
              ))
          .toList(),
      skipped: (json['skipped'] as List<dynamic>? ?? [])
          .map(_int)
          .whereType<int>()
          .toList(),
    );
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
