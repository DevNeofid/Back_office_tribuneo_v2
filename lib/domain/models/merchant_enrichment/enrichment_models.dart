import '../merchant_import_row_model.dart';
import 'vat_status.dart';

typedef Json = Map<String, dynamic>;
Json object(dynamic value) => Map<String, dynamic>.from(value as Map);

class EnrichmentCapability {
  final bool enabled, registry, geocoding, chatResolution, targetedResearch;
  // TVA sourcée (contrat v1.1) : absente ou false = TVA ni affichée comme trouvée ni applicable.
  final bool vat;
  final int maxRows;
  EnrichmentCapability.fromJson(Json json)
      : enabled = json['enabled'] == true,
        registry = json['registry'] == true,
        geocoding = json['geocoding'] == true,
        vat = json['enabled'] == true && json['vat'] == true,
        chatResolution = json['enabled'] == true && json['chat_resolution'] == true,
        targetedResearch = json['enabled'] == true && json['targeted_research'] == true,
        maxRows = json['max_rows'] as int;
  bool get available => enabled && (registry || geocoding);
}

class EnrichmentJob {
  final String id, status, updatedAt;
  final int batchId, done, total, matched, ambiguous, unresolved, stale;
  final String? errorCode;
  EnrichmentJob.fromJson(Json json)
      : id = json['id'] as String,
        batchId = json['batch_id'] as int,
        status = json['status'] as String,
        done = json['progress_done'] as int,
        total = json['progress_total'] as int,
        matched = json['matched'] as int,
        ambiguous = json['ambiguous'] as int,
        unresolved = json['unresolved'] as int,
        stale = json['stale'] as int,
        updatedAt = json['updated_at'] as String,
        errorCode = json['error_code'] as String?;
  bool get active => status == 'queued' || status == 'running';
}

class EnrichmentSource {
  final String provider, url, retrievedAt;
  final String? recordId, precision;
  EnrichmentSource.fromJson(Json json)
      : provider = json['provider'] as String,
        url = json['url'] as String,
        retrievedAt = json['retrieved_at'] as String,
        recordId = json['record_id'] as String?,
        precision = json['precision'] as String?;
}

class EnrichmentCandidate {
  final String id, kind, label, matchLevel;
  final String? legalName, siren, siret, establishmentStatus, geoPrecision;
  final Json fields;
  final Map<String, EnrichmentSource> sources;
  final List<String> reasons;
  // Contrat v1.1 ; une valeur absente ou inconnue (ancienne proposition, ancien serveur) = not_checked.
  final String vatStatus;
  EnrichmentCandidate.fromJson(Json json)
      : id = json['id'] as String,
        vatStatus = VatStatus.parse(json['vat_status']),
        kind = json['kind'] as String,
        label = json['label'] as String,
        legalName = json['legal_name'] as String?,
        siren = json['siren'] as String?,
        siret = json['siret'] as String?,
        establishmentStatus = json['establishment_status'] as String?,
        geoPrecision = json['geo_precision'] as String?,
        matchLevel = json['match_level'] as String,
        fields = object(json['fields']),
        sources = object(json['sources'])
            .map((k, v) => MapEntry(k, EnrichmentSource.fromJson(object(v)))),
        reasons = List<String>.from(json['reason_codes'] as List);
  bool get approximate => geoPrecision != 'housenumber';
}

class EnrichmentProposal {
  final String id, jobId, state;
  final int batchId, rowId, baseVersion;
  final List<String> reasons;
  final List<EnrichmentCandidate> candidates;
  EnrichmentProposal.fromJson(Json json)
      : id = json['id'] as String,
        jobId = json['job_id'] as String,
        batchId = json['batch_id'] as int,
        rowId = json['row_id'] as int,
        baseVersion = json['base_version'] as int,
        state = json['state'] as String,
        reasons = List<String>.from(json['reason_codes'] as List),
        candidates = (json['candidates'] as List)
            .map((v) => EnrichmentCandidate.fromJson(object(v)))
            .toList();
}

class EnrichmentPage<T> {
  final List<T> items;
  final int total, limit, offset;
  EnrichmentPage.fromJson(Json json, T Function(Json) decode)
      : items = (json['items'] as List).map((v) => decode(object(v))).toList(),
        total = json['total'] as int,
        limit = json['limit'] as int,
        offset = json['offset'] as int;
  bool get hasNext => offset + items.length < total;
}

class EnrichmentApplyResult {
  final EnrichmentProposal proposal;
  final MerchantImportRow row;
  final List<MerchantImportRow> related;
  EnrichmentApplyResult.fromJson(Json json)
      : proposal = EnrichmentProposal.fromJson(object(json['proposal'])),
        row = MerchantImportRow.fromJson(object(json['row'])),
        related = (json['related'] as List)
            .map((v) => MerchantImportRow.fromJson(object(v)))
            .toList();
}

class EnrichmentException implements Exception {
  final String? code;
  final int status;
  final MerchantImportRow? row;
  const EnrichmentException({this.code, this.status = 0, this.row});
  bool get conflict =>
      status == 409 && !(code?.startsWith('IDEMPOTENCY_') ?? false);
  @override
  String toString() {
    switch (code) {
      case 'ENRICHMENT_RESEARCH_RATE_LIMITED':
        return 'Trop de relances. Patientez avant de réessayer.';
      case 'ENRICHMENT_RESEARCH_DISABLED':
        return 'La recherche ciblée est désactivée pour ce réseau.';
      case 'ENRICHMENT_RESEARCH_UNSUPPORTED_COUNTRY':
        return 'Seule la France est prise en charge.';
      case 'ENRICHMENT_SEARCH_INSUFFICIENT_INPUT':
        return 'Précisez un SIRET, ou un nom/une rue avec code postal ou ville.';
      case 'IDEMPOTENCY_REQUEST_IN_PROGRESS':
        return 'L’application précédente est encore en cours. Patientez puis réessayez.';
      case 'IDEMPOTENCY_KEY_RETRY':
        return 'L’application précédente a échoué. Vous pouvez réessayer.';
      case 'IDEMPOTENCY_KEY_REUSED':
      case 'IDEMPOTENCY_KEY_INVALID':
        return 'La requête a été refusée. Relisez la proposition puis réessayez.';
      case 'ENRICHMENT_ALREADY_RUNNING':
        return 'Une recherche est déjà en cours. Reprenez sa lecture.';
      case 'ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED':
        return 'Confirmez la précision approximative des coordonnées.';
      case 'ENRICHMENT_DISABLED':
        return 'La recherche est désactivée pour ce réseau.';
      case 'ENRICHMENT_IDENTITY_CONFLICT':
        return 'Le SIRET du candidat diffère du SIRET saisi.';
      case 'ENRICHMENT_ADDRESS_CONTEXT_CONFLICT':
        return 'Les coordonnées ne correspondent pas à l’adresse retenue.';
      default:
        if (conflict)
          return 'La ligne ou le lot a changé. Relisez les données actualisées avant toute nouvelle action.';
        if (status == 404) return 'Recherche indisponible sur cette API.';
        return 'Recherche indisponible. Réessayez ou reprenez la lecture plus tard.';
    }
  }
}
