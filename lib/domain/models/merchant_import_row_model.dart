/// Anomalie d'une ligne d'import, calculée par le serveur.
class MerchantImportIssue {
  static const String levelError = 'error';
  static const String levelWarning = 'warning';
  static const String levelInfo = 'info';

  /// Colonne concernée, `null` pour une anomalie de la ligne entière.
  final String? field;

  /// `error` (bloquant), `warning` ou `info`.
  final String level;
  final String? code;

  /// Texte français destiné à l'utilisateur, affiché tel quel.
  final String message;

  const MerchantImportIssue({
    this.field,
    required this.level,
    this.code,
    required this.message,
  });

  factory MerchantImportIssue.fromJson(Map<String, dynamic> json) {
    final String? field = json['field']?.toString();
    return MerchantImportIssue(
      field: field == null || field.isEmpty ? null : field,
      level: json['level']?.toString() ?? levelInfo,
      code: json['code']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }

  static List<MerchantImportIssue> listFromJson(dynamic json) =>
      (json is List ? json : const [])
          .whereType<Map>()
          .map((item) =>
              MerchantImportIssue.fromJson(Map<String, dynamic>.from(item)))
          .toList();

  bool get isError => level == levelError;
  bool get isWarning => level == levelWarning;
  bool get isInfo => level == levelInfo;
}

/// Une ligne d'un lot d'import (`/merchant-import/{id}/rows`). Immuable : chaque
/// réponse de l'API remplace la ligne entière.
class MerchantImportRow {
  static const String statusPending = 'pending';
  static const String statusValidated = 'validated';
  static const String statusRejected = 'rejected';
  static const String statusImported = 'imported';
  static const String statusFailed = 'failed';

  /// Sources dont les valeurs viennent de l'IA (étapes 2-3).
  static const Set<String> aiSources = {'ia', 'page'};

  final int id;
  final int? idBatch;
  final int position;
  final String status;

  /// Valeurs actuelles. Une valeur absente vaut `null`.
  final Map<String, dynamic> fields;

  /// Valeurs d'origine (fichier, puis IA).
  final Map<String, dynamic> suggestedValues;

  /// Provenance par champ : `fichier`, plus tard `registre`, `geocodage`,
  /// `calcul`, `ia`, `page`.
  final Map<String, String> suggestedSources;
  final List<MerchantImportIssue> issues;
  final int? idEntityMatch;
  final int? idEntityCreated;

  /// Raison de l'échec d'import (statut `failed`).
  final String? error;

  /// Verrou optimiste : à renvoyer à chaque `PATCH`.
  final int version;
  final String? updatedDate;

  const MerchantImportRow({
    required this.id,
    this.idBatch,
    this.position = 0,
    required this.status,
    this.fields = const {},
    this.suggestedValues = const {},
    this.suggestedSources = const {},
    this.issues = const [],
    this.idEntityMatch,
    this.idEntityCreated,
    this.error,
    required this.version,
    this.updatedDate,
  });

  factory MerchantImportRow.fromJson(Map<String, dynamic> json) {
    final dynamic suggested = json['suggested'];
    final Map<String, dynamic> suggestedMap =
        suggested is Map ? Map<String, dynamic>.from(suggested) : {};
    final dynamic sources = suggestedMap['sources'];
    return MerchantImportRow(
      id: _int(json['id']) ?? 0,
      idBatch: _int(json['id_batch']),
      position: _int(json['position']) ?? 0,
      status: json['status']?.toString() ?? statusPending,
      fields: _map(json['fields']),
      suggestedValues: _map(suggestedMap['values']),
      suggestedSources: sources is Map
          ? sources.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''))
          : const {},
      issues: MerchantImportIssue.listFromJson(json['issues']),
      idEntityMatch: _int(json['id_entity_match']),
      idEntityCreated: _int(json['id_entity_created']),
      error: json['error']?.toString(),
      version: _int(json['version']) ?? 0,
      updatedDate: json['updated_date']?.toString(),
    );
  }

  /// Copie avec d'autres anomalies et un autre statut (refus `ROW_HAS_ERRORS`
  /// sans ligne complète dans la réponse).
  MerchantImportRow copyWith(
      {List<MerchantImportIssue>? issues, String? status}) {
    return MerchantImportRow(
      id: id,
      idBatch: idBatch,
      position: position,
      status: status ?? this.status,
      fields: fields,
      suggestedValues: suggestedValues,
      suggestedSources: suggestedSources,
      issues: issues ?? this.issues,
      idEntityMatch: idEntityMatch,
      idEntityCreated: idEntityCreated,
      error: error,
      version: version,
      updatedDate: updatedDate,
    );
  }

  bool get isPending => status == statusPending;
  bool get isValidated => status == statusValidated;
  bool get isRejected => status == statusRejected;
  bool get isImported => status == statusImported;
  bool get isFailed => status == statusFailed;

  /// Ligne non modifiable : importée, ou écartée (seul « Rétablir » reste
  /// possible).
  bool get isLocked => isImported || isRejected;

  /// Au moins une anomalie bloquante : la ligne ne peut pas être cochée.
  bool get hasBlockingIssue => issues.any((issue) => issue.isError);

  List<MerchantImportIssue> get blockingIssues =>
      issues.where((issue) => issue.isError).toList();

  List<MerchantImportIssue> issuesFor(String field) =>
      issues.where((issue) => issue.field == field).toList();

  dynamic valueOf(String field) => fields[field];

  dynamic originalOf(String field) => suggestedValues[field];

  /// Texte affiché pour [field] (chaîne vide si absent).
  String textOf(String field) => displayText(fields[field]);

  /// La valeur actuelle diffère de la valeur d'origine.
  bool isModified(String field) =>
      !sameValue(fields[field], suggestedValues[field]);

  /// Provenance de la valeur d'origine, `null` si inconnue.
  String? sourceOf(String field) {
    final String? source = suggestedSources[field];
    return source == null || source.isEmpty ? null : source;
  }

  /// Valeur venue de l'IA et pas encore modifiée.
  bool isAiValue(String field) =>
      aiSources.contains(sourceOf(field)) && !isModified(field);

  /// Texte d'une valeur de cellule : `null` → chaîne vide, nombres sans
  /// décimales inutiles.
  static String displayText(dynamic value) {
    if (value == null) return '';
    if (value is double && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString().trim();
  }

  /// Deux valeurs de cellule identiques à l'affichage (après `trim`).
  static bool sameValue(dynamic a, dynamic b) =>
      displayText(a) == displayText(b);
}

/// Réponse de `PATCH /merchant-import/{id}/rows/{rowId}`.
class MerchantImportPatchResult {
  /// La ligne à jour (valeur normalisée, anomalies, statut, version).
  final MerchantImportRow row;

  /// Autres lignes dont les anomalies ont changé (doublon apparu ou levé).
  final List<MerchantImportRow> related;

  const MerchantImportPatchResult({required this.row, this.related = const []});

  factory MerchantImportPatchResult.fromJson(Map<String, dynamic> json) {
    final dynamic row = json['row'];
    return MerchantImportPatchResult(
      row: MerchantImportRow.fromJson(
          row is Map ? Map<String, dynamic>.from(row) : {}),
      related: (json['related'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) =>
              MerchantImportRow.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
