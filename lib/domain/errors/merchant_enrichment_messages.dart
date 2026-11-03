/// Catalogue des textes français de l'enrichissement et de la grille d'import
/// (contrat UI lot 04, CONTRAT_UI_ET_MESSAGES.md).
///
/// Dart pur : ni Flutter, ni réseau, ni état mutable. Les codes, statuts et valeurs
/// restent intacts dans les modèles, comparaisons, en-têtes et décisions de contrôle :
/// ce catalogue ne sert qu'à la frontière d'affichage. Un code connu donne un texte
/// local ; un code inconnu donne un repli neutre, jamais la valeur reçue (ni code, ni
/// classe, ni description fournisseur ou SQL, ni stacktrace).
class MerchantEnrichmentMessages {
  const MerchantEnrichmentMessages._();

  // ---------------------------------------------------------------------------
  // Erreurs (EnrichmentException, job.errorCode)
  // ---------------------------------------------------------------------------

  static const _errors = <String, String>{
    // Refus stables ENRICHMENT_* (MerchantEnrichmentException côté API).
    'ENRICHMENT_DISABLED':
        'La recherche d’informations n’est pas activée pour ce réseau.',
    'ENRICHMENT_INVALID_REQUEST':
        'La demande n’a pas pu être traitée. Reprenez la lecture, puis réessayez.',
    'ENRICHMENT_NOT_FOUND':
        'Élément introuvable pour ce lot. Reprenez la lecture pour actualiser la recherche.',
    'ENRICHMENT_ALREADY_RUNNING':
        'Une recherche est déjà en cours sur ce lot. Reprenez la lecture pour suivre son avancement.',
    'ENRICHMENT_BATCH_NOT_EDITABLE':
        'Le lot n’est plus en relecture : aucune modification n’est possible.',
    'ENRICHMENT_ROW_NOT_EDITABLE':
        'Cette ligne n’est plus modifiable (validée, écartée ou importée). Relisez son état dans la grille.',
    'ENRICHMENT_VERSION_CONFLICT':
        'La ligne a été modifiée entre-temps. Relisez les données actualisées avant de continuer.',
    'ENRICHMENT_PROPOSAL_STALE':
        'Cette proposition n’est plus à jour : la ligne a changé ou la proposition a déjà été appliquée. '
            'Relisez la ligne, puis lancez une nouvelle recherche si besoin.',
    'ENRICHMENT_FIELD_NOT_EMPTY':
        'Un champ choisi est déjà renseigné sur la ligne : sa valeur est conservée. Relisez la ligne.',
    'ENRICHMENT_IDENTITY_CONFLICT':
        'Le SIRET proposé diffère de celui de la ligne. Vérifiez le commerçant sélectionné.',
    'ENRICHMENT_ADDRESS_CONTEXT_CONFLICT':
        'Les coordonnées proposées ne correspondent pas à l’adresse retenue. Relisez la ligne avant de choisir.',
    'ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED':
        'Ces coordonnées sont approximatives : cochez l’accord sur leur précision avant d’appliquer.',
    'ENRICHMENT_UNAVAILABLE':
        'Le service de recherche est momentanément indisponible. Réessayez plus tard.',
    'ENRICHMENT_RESEARCH_DISABLED':
        'La recherche ciblée n’est pas activée pour ce réseau.',
    'ENRICHMENT_RESEARCH_UNSUPPORTED_COUNTRY':
        'La recherche ne couvre que la France.',
    'ENRICHMENT_SEARCH_INSUFFICIENT_INPUT':
        'Indiquez un SIRET, ou un nom ou une adresse avec le code postal ou la ville.',
    'ENRICHMENT_RESEARCH_RATE_LIMITED':
        'Trop de recherches ciblées en peu de temps. Patientez quelques minutes avant de relancer.',
    // Idempotence (IdempotencyMiddleware).
    'IDEMPOTENCY_REQUEST_IN_PROGRESS':
        'La demande précédente est encore en cours de traitement. Patientez, puis réessayez.',
    'IDEMPOTENCY_KEY_RETRY':
        'La demande précédente n’a pas abouti. Vous pouvez réessayer.',
    'IDEMPOTENCY_KEY_REUSED':
        'La demande a été refusée par sécurité. Relisez la proposition, puis réessayez.',
    'IDEMPOTENCY_KEY_INVALID':
        'La demande a été refusée par sécurité. Relisez la proposition, puis réessayez.',
    // Réseau (TenantMembershipMiddleware) et droits (RoleMiddleware).
    'UNKNOWN_TENANT':
        'Le réseau sélectionné est introuvable. Changez de réseau ou reconnectez-vous.',
    'TENANT_FORBIDDEN':
        'Vous n’avez pas accès à ce réseau. Sélectionnez un réseau autorisé.',
    'ACCESS_DENIED':
        'Votre compte n’a pas les droits nécessaires pour cette action.',
    // Session (AccessTokenMiddleware / RoleMiddleware).
    'AUTH_REQUIRED': _session,
    'MISSING_TOKEN': _session,
    'SESSION_NOT_FOUND': _session,
    'SESSION_REVOKED': _session,
    // Codes d'arrêt d'un job (EnrichmentJob.errorCode).
    'BATCH_NOT_EDITABLE': 'Recherche arrêtée : le lot n’est plus en relecture.',
    'LEASE_ATTEMPTS_EXHAUSTED':
        'La recherche n’a pas pu aboutir après plusieurs tentatives. Lancez une nouvelle recherche plus tard.',
    'RESEARCH_MARKER_INVALID':
        'Les critères de cette recherche ciblée sont illisibles : lancez une nouvelle recherche.',
  };

  static const _session =
      'Votre session a expiré. Reconnectez-vous, puis rouvrez ce dialogue.';
  static const _unavailable =
      'Recherche indisponible pour le moment. Réessayez ou reprenez la lecture plus tard.';

  /// Message d'une erreur d'enrichissement : code connu d'abord, puis statut HTTP,
  /// puis repli neutre (délai, réseau, réponse illisible, changement de réseau).
  static String error({String? code, int status = 0}) {
    final known = code == null ? null : _errors[code];
    if (known != null) return known;
    if (status == 401) return _session;
    if (status == 403) {
      return 'Vous n’avez pas les droits nécessaires pour cette action sur ce réseau.';
    }
    if (status == 404) {
      return 'Recherche indisponible sur ce serveur. Les autres actions du lot restent utilisables.';
    }
    if (status == 409) {
      return 'La ligne ou le lot a changé. Relisez les données actualisées avant toute nouvelle action.';
    }
    if (status == 400 || status == 422) {
      return 'La demande n’a pas pu être traitée. Reprenez la lecture, puis réessayez.';
    }
    if (status == 429) {
      return 'Le service reçoit trop de demandes. Patientez un instant, puis réessayez.';
    }
    if (status >= 500 && status <= 599) {
      return 'Le service est momentanément indisponible. Réessayez dans quelques instants.';
    }
    return _unavailable;
  }

  // ---------------------------------------------------------------------------
  // Raisons des propositions et des candidats (reason_codes)
  // ---------------------------------------------------------------------------

  static const _vatSourceUnavailable =
      'Source TVA indisponible : TVA non vérifiée, ce n’est pas une absence.';

  static const _reasons = <String, String>{
    // Recherche dans le registre.
    'SEARCH_SIRET': 'Recherche effectuée à partir du SIRET.',
    'SEARCH_NAME': 'Recherche effectuée à partir du nom et de l’adresse.',
    'SIRET_EXACT': 'Le SIRET correspond exactement.',
    'SIRET_INVALID':
        'Le SIRET de la ligne n’est pas valide : la recherche s’est faite sans lui.',
    'SIRET_NOT_FOUND': 'Aucun établissement trouvé pour ce SIRET.',
    'ESTABLISHMENT_NOT_FOUND':
        'L’entreprise existe, mais cet établissement n’a pas été trouvé.',
    'NO_CANDIDATE': 'Aucun établissement correspondant trouvé.',
    'PROVIDER_RESULTS_NOT_EXHAUSTIVE':
        'Le registre n’a renvoyé qu’une partie des résultats : d’autres établissements peuvent exister.',
    'INPUT_INSUFFICIENT_FOR_REGISTRY':
        'Informations insuffisantes pour la recherche : indiquez un SIRET, ou un nom avec le code postal ou la ville.',
    'MULTIPLE_CANDIDATES':
        'Plusieurs établissements sont possibles. Comparez les propositions.',
    'CANDIDATES_TRUNCATED': 'Seuls les premiers établissements sont présentés.',
    // Pannes de source : jamais une absence.
    'REGISTRY_UNAVAILABLE':
        'Le registre des entreprises était indisponible : ce n’est pas une absence. Relancez plus tard.',
    'REGISTRY_RATE_LIMITED':
        'Le service de recherche reçoit trop de demandes. Réessayez dans un instant.',
    'GEOCODING_UNAVAILABLE':
        'Les coordonnées n’ont pas pu être recherchées pour le moment.',
    'GEOCODING_RATE_LIMITED':
        'Le service de géocodage reçoit trop de demandes : coordonnées non recherchées pour le moment.',
    'BUDGET_EXHAUSTED':
        'Limite de requêtes atteinte : certaines vérifications n’ont pas été faites. Relancez plus tard.',
    'INTERNAL_ERROR':
        'Cette ligne n’a pas pu être traitée. Relancez la recherche plus tard.',
    // Concordance.
    'NAME_MATCH': 'Le nom correspond à la recherche.',
    'NAME_NOT_CORROBORATED': 'Le nom reste à vérifier.',
    'ADDRESS_MATCH': 'L’adresse correspond à la recherche.',
    'ADDRESS_NOT_CORROBORATED': 'L’adresse reste à vérifier.',
    'ADDRESS_CONFLICT': 'L’adresse trouvée diffère de celle de la ligne.',
    'ADDRESS_IMPRECISE_INPUT':
        'L’adresse de la ligne n’a pas de numéro : comparaison limitée.',
    'ADDRESS_FROM_ROW': 'Position calculée à partir de l’adresse de la ligne.',
    'ESTABLISHMENT_CLOSED': 'Établissement fermé selon le registre.',
    'DIFFUSION_PARTIAL':
        'Diffusion partielle : certaines informations ne sont pas publiques.',
    'HEADQUARTERS':
        'Il s’agit du siège de l’entreprise, pas forcément du commerce.',
    // Coordonnées.
    'COORDINATES_ALREADY_PRESENT':
        'Les coordonnées de la ligne sont déjà renseignées : elles sont conservées.',
    'GEOCODE_NOT_FOUND': 'Aucune position trouvée pour cette adresse.',
    'GEOCODE_ADDRESS_MISMATCH':
        'La position trouvée ne correspond pas exactement à l’adresse.',
    'GEOCODE_IMPRECISE':
        'Position approximative (rue ou commune), pas l’adresse exacte.',
    // TVA sourcée.
    'VAT_ALREADY_PRESENT':
        'La TVA de la ligne est déjà renseignée : elle est conservée.',
    'VAT_NOT_ELIGIBLE': 'TVA non recherchée pour cet établissement.',
    'VAT_FOUND_IN_SOURCE':
        'TVA trouvée dans la source DGFiP datée (ce n’est pas une vérification VIES).',
    'VAT_NOT_FOUND_IN_SOURCE':
        'TVA absente de la source DGFiP (n’exclut pas un numéro hors de cette source).',
    'VAT_MULTIPLE_NUMBERS':
        'Plusieurs numéros de TVA dans la source : aucun n’est proposé.',
    'VAT_UNAVAILABLE': _vatSourceUnavailable,
    'VAT_RATE_LIMITED': _vatSourceUnavailable,
    'VAT_BUDGET_EXHAUSTED': _vatSourceUnavailable,
    'VAT_INVALID_RESPONSE': _vatSourceUnavailable,
    'VAT_RESULTS_INCOMPLETE': _vatSourceUnavailable,
    // État de la ligne et de la proposition.
    'ROW_VERSION_CHANGED':
        'La ligne a été modifiée depuis la recherche : lancez une nouvelle recherche avant de choisir.',
    'ROW_NOT_PENDING':
        'Ligne déjà validée, écartée ou importée : elle n’a pas été recherchée.',
    'ROW_NOT_PARTNER':
        'Ligne client et non commerçant : elle n’a pas été recherchée.',
    'APPLIED': 'Proposition appliquée au brouillon.',
  };

  static const _unknownReason =
      'Une vérification complémentaire est nécessaire.';
  static const _appliedField = 'APPLIED_FIELD_';

  /// Texte d'un code de raison. `APPLIED_FIELD_<CHAMP>` seulement pour un champ connu.
  static String reason(String code) {
    final known = _reasons[code];
    if (known != null) return known;
    if (code.startsWith(_appliedField)) {
      final key = code.substring(_appliedField.length).toLowerCase();
      final label = _fields[key];
      if (label != null) return 'Champ appliqué au brouillon : $label.';
    }
    return _unknownReason;
  }

  /// Raisons dans l'ordre reçu, libellés identiques dédupliqués ; un ou plusieurs
  /// codes inconnus donnent une seule phrase neutre, placée en dernier.
  static List<String> reasons(Iterable<String> codes) {
    final out = <String>[];
    var unknown = false;
    for (final code in codes) {
      final text = reason(code);
      if (text == _unknownReason) {
        unknown = true;
      } else if (!out.contains(text)) {
        out.add(text);
      }
    }
    if (unknown) out.add(_unknownReason);
    return out;
  }

  // ---------------------------------------------------------------------------
  // Champs
  // ---------------------------------------------------------------------------

  static const _fields = <String, String>{
    'name': 'Nom',
    'type': 'Type',
    'siret': 'SIRET',
    'siren': 'SIREN',
    'legal_name': 'Raison sociale',
    'email': 'Email',
    'phone': 'Téléphone',
    'street': 'Adresse',
    'zip': 'Code postal',
    'city': 'Ville',
    'country': 'Pays',
    'lat': 'Latitude',
    'lng': 'Longitude',
    'activity_sectors': 'Secteurs d’activité',
    'code': 'Code',
    'intracommunity_vat_number': 'TVA intracommunautaire',
    'iban': 'IBAN',
    'bic': 'BIC',
    'bank_key': 'Clé RIB',
    'account_number': 'Numéro comptable',
    'naf': 'Code NAF',
    'website': 'Site web',
  };

  /// Libellé français d'un champ ; clé inconnue : libellé neutre, jamais la clé.
  static String field(String key) => _fields[key] ?? 'Autre information';

  // ---------------------------------------------------------------------------
  // États et niveaux
  // ---------------------------------------------------------------------------

  static String proposalState(String state) =>
      const {
        'matched': 'Correspondance trouvée',
        'ambiguous': 'Choix manuel requis',
        'address_only': 'Adresse seule',
        'not_found': 'Aucun résultat',
        'insufficient_input': 'Informations insuffisantes',
        'provider_unavailable': 'Source indisponible',
        'stale': 'Ligne modifiée depuis la recherche',
        'skipped': 'Non recherchée',
        'applied': 'Appliquée au brouillon',
      }[state] ??
      'État à vérifier';

  static String jobStatus(String status) =>
      const {
        'queued': 'En attente',
        'running': 'En cours',
        'completed': 'Terminée',
        'completed_with_errors': 'Terminée, sources parfois indisponibles',
        'failed': 'Échec',
        'cancelled': 'Annulée',
      }[status] ??
      'État inconnu';

  static String matchLevel(String level) =>
      const {
        'exact_identifier': 'SIRET identique',
        'name_address': 'Nom et adresse concordants',
        'ambiguous': 'Correspondance à confirmer',
        'address_only': 'Adresse seule',
      }[level] ??
      'Correspondance à vérifier';

  static String establishmentStatus(String? status) =>
      const {
        'active': 'Établissement actif',
        'closed': 'Établissement fermé',
      }[status] ??
      'État de l’établissement non renseigné';

  /// Attribution d'une source : ce n'est pas la preuve que chaque champ a été retrouvé.
  static String provider(String provider) =>
      const {
        'recherche_entreprises': 'Recherche d’entreprises',
        'ign_geocodage': 'Géocodage IGN',
        'dgfip_tva': 'DGFiP',
      }[provider] ??
      'Source publique';

  /// Précision du géocodage ; ne certifie jamais l'emplacement d'une devanture.
  static String geoPrecision(String? precision) =>
      const {
        'housenumber': 'Adresse précise',
        'street': 'Rue',
        'locality': 'Lieu-dit',
        'municipality': 'Commune',
      }[precision] ??
      'Précision non renseignée';

  /// Statut TVA. Sans capability `vat`, toujours « Non vérifiée ». `found` = présent
  /// dans une extraction datée, jamais une validation VIES en temps réel.
  static String vatStatus(String status, {required bool capability}) {
    if (!capability) return 'Non vérifiée';
    return const {
          'found': 'Trouvée dans la source DGFiP datée',
          'not_found':
              'Absente de la source DGFiP (n’exclut pas un numéro hors de cette source)',
          'ambiguous':
              'Plusieurs numéros dans la source : aucun proposé, choix manuel hors outil',
          'unavailable':
              'Source indisponible : non vérifiée, ce n’est pas une absence',
        }[status] ??
        'Non vérifiée';
  }

  // ---------------------------------------------------------------------------
  // Dates de source
  // ---------------------------------------------------------------------------

  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre'
  ];
  static final _iso = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d{1,9})?)?(Z|[+-]\d{2}:?\d{2})?)?$');

  /// Date ISO lisible (« 3 novembre 2026 à 09:00 », heure locale si une heure est
  /// fournie). Absente ou invalide : « Date non disponible », jamais la valeur reçue.
  static String sourceDate(String? isoDate) {
    const missing = 'Date non disponible';
    final value = isoDate?.trim() ?? '';
    final match = _iso.firstMatch(value);
    if (match == null) return missing;
    final year = int.parse(match[1]!), month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final calendar = DateTime.utc(year, month, day);
    if (month < 1 ||
        month > 12 ||
        calendar.year != year ||
        calendar.month != month ||
        calendar.day != day) return missing;
    if (match[4] == null) return _date(day, month, year);
    final hour = int.parse(match[4]!), minute = int.parse(match[5]!);
    final second = match[6] == null ? 0 : int.parse(match[6]!);
    if (hour > 23 || minute > 59 || second > 59) return missing;
    final zone = match[7];
    if (zone != null && zone != 'Z') {
      final digits = zone.replaceAll(':', '');
      if (int.parse(digits.substring(1, 3)) > 23 ||
          int.parse(digits.substring(3, 5)) > 59) return missing;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return missing;
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${_date(local.day, local.month, local.year)} à '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _date(int day, int month, int year) =>
      '${day == 1 ? '1er' : day} ${_months[month - 1]} $year';

  // ---------------------------------------------------------------------------
  // Grille d'import : anomalies du validateur et échecs d'import
  // ---------------------------------------------------------------------------

  static const _issues = <String, String>{
    'NAME_REQUIRED': 'Le nom est obligatoire.',
    'TYPE_INVALID': 'Type à choisir : commerçant ou client.',
    'EMAIL_REQUIRED': 'L’email est obligatoire.',
    'EMAIL_INVALID':
        'L’email n’est pas valide (exemple : contact@commerce.fr).',
    'SIRET_REQUIRED': 'Le SIRET est obligatoire pour un commerçant.',
    'SIRET_INVALID': 'Le SIRET n’est pas valide : vérifiez ses 14 chiffres.',
    'SIRET_DUPLICATE': 'Ce SIRET figure sur une autre ligne du lot.',
    'REMOVED_FROM_NETWORK':
        'Ce SIRET correspond à une fiche retirée du réseau : restaurez-la depuis les entités supprimées.',
    'ALREADY_IN_NETWORK':
        'Ce SIRET est déjà présent dans le réseau : l’import complétera la fiche existante.',
    'EXISTS_ELSEWHERE':
        'Ce SIRET existe déjà dans Tribuneo : l’import rattachera la fiche à ce réseau.',
    'PHONE_MISSING': 'Téléphone absent.',
    'ADDRESS_INCOMPLETE':
        'Adresse incomplète : rue, code postal et ville attendus.',
    'LAT_INVALID': 'Latitude invalide : nombre entre -90 et 90 attendu.',
    'LNG_INVALID': 'Longitude invalide : nombre entre -180 et 180 attendu.',
    'COORDINATES_INCOMPLETE':
        'Latitude et longitude vont ensemble : renseignez les deux.',
    'COORDINATES_MISSING':
        'Sans coordonnées, le commerçant n’apparaîtra pas sur la carte.',
    'IBAN_INVALID': 'IBAN invalide : vérifiez son format.',
    'VAT_INVALID':
        'Numéro de TVA intracommunautaire invalide (exemple : FR03552081317).',
    'SECTOR_UNKNOWN': 'Secteur d’activité inconnu : il sera créé à l’import.',
  };

  /// Anomalie du validateur. Le message libre de l'API n'est jamais affiché ; un code
  /// inconnu sur un champ connu invite à vérifier ce champ, sans information inventée.
  static String importIssue(String code, {String? field}) {
    final known = _issues[code];
    if (known != null) return known;
    final label = field == null ? null : _fields[field];
    if (label != null) return 'Vérifiez le champ « $label ».';
    return 'Vérifiez les informations de cette ligne.';
  }

  static const _failures = <String, String>{
    'ROW_IMPORTED': 'Cette ligne a déjà été importée.',
    'ROW_NOT_FOUND':
        'Cette ligne n’existe plus dans le lot. Actualisez la grille.',
    'BATCH_NOT_IMPORTABLE':
        'Le lot n’est pas prêt pour l’import. Actualisez la grille.',
    'NOTHING_TO_IMPORT': 'Aucune ligne validée à importer.',
  };

  /// Échec d'import d'une ligne. Peut recevoir l'erreur brute historique : seuls les
  /// codes exacts de la liste locale sont traduits, sinon une phrase sûre. Aucun
  /// diagnostic n'est reconstruit à partir d'un texte anglais ou SQL.
  static String importFailure(String? code) =>
      _failures[code?.trim()] ??
      'Impossible d’importer cette ligne. Vérifiez ses informations puis relancez l’import ; '
          'si l’échec persiste, contactez le support.';
}
