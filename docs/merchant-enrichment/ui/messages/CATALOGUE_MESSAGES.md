# Catalogue des messages — enrichissement et grille d'import (lot 04, E07)

Fiche versionnée du catalogue pur Dart
[`lib/domain/errors/merchant_enrichment_messages.dart`](../../../../lib/domain/errors/merchant_enrichment_messages.dart).
Les tableaux ci-dessous sont **générés depuis le code** (script jetable appelant le
catalogue réel, 3 novembre 2026) : ils montrent exactement ce que l'utilisateur lit.

## Règles

- Traduction **à la frontière d'affichage uniquement**. Les codes, statuts, versions et
  valeurs restent intacts dans les DTO, comparaisons, en-têtes, clés d'idempotence et
  décisions de contrôle (`EnrichmentException.code/status/row`, `conflict`,
  `MerchantImportIssue.code/message/level`, `candidate.approximate`, etc.).
- Code connu → texte local ; code inconnu → repli neutre. Jamais de code, enum, classe,
  stacktrace, JSON, SQL, description fournisseur ou valeur reçue en guise d'explication.
- Une panne de source n'est jamais présentée comme une absence ; une TVA trouvée dans
  l'extraction DGFiP datée n'est pas une validation VIES ; une précision de géocodage
  ne certifie pas l'emplacement d'une devanture.
- Les reprises proposées renvoient à des actions réelles des dialogues : « Reprendre la
  lecture », « Préciser la recherche » / « Relancer la recherche », nouvelle recherche
  (« Rechercher sur ces N lignes »), reconnexion.
- `reasons()` garde l'ordre reçu, déduplique les libellés identiques et regroupe tous
  les codes inconnus en une seule phrase neutre, placée en dernier.
- `importFailure()` ne traduit que des codes exacts ; tout texte libre (SQL, anglais,
  message d'exception) devient une phrase sûre, sans diagnostic reconstruit.
- `sourceDate()` : date ISO réelle → date française, heure **locale** si une heure est
  fournie, « 1er » pour le premier du mois ; invalide ou absente → « Date non
  disponible ». Aucune dépendance (pas d'`intl`), l'instant du modèle n'est pas modifié.

## Points d'affichage raccordés

| Fichier | Point d'affichage |
|---|---|
| `domain/models/merchant_enrichment/enrichment_models.dart` | `EnrichmentException.toString()` → `error(code, status)` (donc `session.message`, infobulle du bouton, messages des dialogues) |
| `domain/models/merchant_enrichment/research_models.dart` | textes de `ResearchCriteria.error` (conditions inchangées) |
| `presentation/widgets/merchant_enrichment/enrichment_panel.dart` | statut et `errorCode` du job, historique (statut · date au lieu de l'UUID), état et raisons des propositions, statut d'établissement, niveau, raisons et précision des candidats, sources (fournisseur, date, précision), accord GPS, texte « application indisponible » |
| `presentation/widgets/merchant_enrichment/research_form.dart` | libellés des six champs, contexte « Ligne N · nom » |
| `presentation/widgets/merchant_enrichment/research_metadata_view.dart` | clés des critères historiques → noms de champ, position de ligne |
| `presentation/widgets/merchant_enrichment/chat_comparison.dart` | en-tête : position de ligne, sans version technique |
| `presentation/widgets/merchant_enrichment/vat_presentation.dart` | `vatStatusLabel` délègue à `vatStatus()`, date de lecture DGFiP |
| `presentation/widgets/merchant_import/merchant_import_grid.dart` | infobulles d'anomalies (case, statut, cellule) → `importIssue()`, échec d'import de la ligne et liste `failure.error` → `importFailure()` |

Les helpers privés `_jobLabel`, `_stateLabel`, `_fieldLabel` et la fonction publique
`vatStatusLabel` sont conservés comme **délégués** du catalogue (aucune seconde copie
des textes) afin que les appels existants, y compris ceux d'une branche voisine,
restent traduits après fusion.

## Sorties du catalogue

Running build hooks...Running build hooks...### error(code:) — codes connus

| Code | Texte affiché |
|---|---|
| `ENRICHMENT_DISABLED` | La recherche d’informations n’est pas activée pour ce réseau. |
| `ENRICHMENT_INVALID_REQUEST` | La demande n’a pas pu être traitée. Reprenez la lecture, puis réessayez. |
| `ENRICHMENT_NOT_FOUND` | Élément introuvable pour ce lot. Reprenez la lecture pour actualiser la recherche. |
| `ENRICHMENT_ALREADY_RUNNING` | Une recherche est déjà en cours sur ce lot. Reprenez la lecture pour suivre son avancement. |
| `ENRICHMENT_BATCH_NOT_EDITABLE` | Le lot n’est plus en relecture : aucune modification n’est possible. |
| `ENRICHMENT_ROW_NOT_EDITABLE` | Cette ligne n’est plus modifiable (validée, écartée ou importée). Relisez son état dans la grille. |
| `ENRICHMENT_VERSION_CONFLICT` | La ligne a été modifiée entre-temps. Relisez les données actualisées avant de continuer. |
| `ENRICHMENT_PROPOSAL_STALE` | Cette proposition n’est plus à jour : la ligne a changé ou la proposition a déjà été appliquée. Relisez la ligne, puis lancez une nouvelle recherche si besoin. |
| `ENRICHMENT_FIELD_NOT_EMPTY` | Un champ choisi est déjà renseigné sur la ligne : sa valeur est conservée. Relisez la ligne. |
| `ENRICHMENT_IDENTITY_CONFLICT` | Le SIRET proposé diffère de celui de la ligne. Vérifiez le commerçant sélectionné. |
| `ENRICHMENT_ADDRESS_CONTEXT_CONFLICT` | Les coordonnées proposées ne correspondent pas à l’adresse retenue. Relisez la ligne avant de choisir. |
| `ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED` | Ces coordonnées sont approximatives : cochez l’accord sur leur précision avant d’appliquer. |
| `ENRICHMENT_UNAVAILABLE` | Le service de recherche est momentanément indisponible. Réessayez plus tard. |
| `ENRICHMENT_RESEARCH_DISABLED` | La recherche ciblée n’est pas activée pour ce réseau. |
| `ENRICHMENT_RESEARCH_UNSUPPORTED_COUNTRY` | La recherche ne couvre que la France. |
| `ENRICHMENT_SEARCH_INSUFFICIENT_INPUT` | Indiquez un SIRET, ou un nom ou une adresse avec le code postal ou la ville. |
| `ENRICHMENT_RESEARCH_RATE_LIMITED` | Trop de recherches ciblées en peu de temps. Patientez quelques minutes avant de relancer. |
| `IDEMPOTENCY_REQUEST_IN_PROGRESS` | La demande précédente est encore en cours de traitement. Patientez, puis réessayez. |
| `IDEMPOTENCY_KEY_RETRY` | La demande précédente n’a pas abouti. Vous pouvez réessayer. |
| `IDEMPOTENCY_KEY_REUSED` | La demande a été refusée par sécurité. Relisez la proposition, puis réessayez. |
| `IDEMPOTENCY_KEY_INVALID` | La demande a été refusée par sécurité. Relisez la proposition, puis réessayez. |
| `UNKNOWN_TENANT` | Le réseau sélectionné est introuvable. Changez de réseau ou reconnectez-vous. |
| `TENANT_FORBIDDEN` | Vous n’avez pas accès à ce réseau. Sélectionnez un réseau autorisé. |
| `ACCESS_DENIED` | Votre compte n’a pas les droits nécessaires pour cette action. |
| `AUTH_REQUIRED` | Votre session a expiré. Reconnectez-vous, puis rouvrez ce dialogue. |
| `MISSING_TOKEN` | Votre session a expiré. Reconnectez-vous, puis rouvrez ce dialogue. |
| `SESSION_NOT_FOUND` | Votre session a expiré. Reconnectez-vous, puis rouvrez ce dialogue. |
| `SESSION_REVOKED` | Votre session a expiré. Reconnectez-vous, puis rouvrez ce dialogue. |
| `BATCH_NOT_EDITABLE` | Recherche arrêtée : le lot n’est plus en relecture. |
| `LEASE_ATTEMPTS_EXHAUSTED` | La recherche n’a pas pu aboutir après plusieurs tentatives. Lancez une nouvelle recherche plus tard. |
| `RESEARCH_MARKER_INVALID` | Les critères de cette recherche ciblée sont illisibles : lancez une nouvelle recherche. |

### error(status:) — sans code connu

| Statut | Texte affiché |
|---|---|
| `401` | Votre session a expiré. Reconnectez-vous, puis rouvrez ce dialogue. |
| `403` | Vous n’avez pas les droits nécessaires pour cette action sur ce réseau. |
| `404` | Recherche indisponible sur ce serveur. Les autres actions du lot restent utilisables. |
| `409` | La ligne ou le lot a changé. Relisez les données actualisées avant toute nouvelle action. |
| `400` | La demande n’a pas pu être traitée. Reprenez la lecture, puis réessayez. |
| `422` | La demande n’a pas pu être traitée. Reprenez la lecture, puis réessayez. |
| `429` | Le service reçoit trop de demandes. Patientez un instant, puis réessayez. |
| `500` | Le service est momentanément indisponible. Réessayez dans quelques instants. |
| `503` | Le service est momentanément indisponible. Réessayez dans quelques instants. |
| `0 (délai, réseau, réponse illisible, réseau changé)` | Recherche indisponible pour le moment. Réessayez ou reprenez la lecture plus tard. |

### reason()

| Code | Texte affiché |
|---|---|
| `SEARCH_SIRET` | Recherche effectuée à partir du SIRET. |
| `SEARCH_NAME` | Recherche effectuée à partir du nom et de l’adresse. |
| `SIRET_EXACT` | Le SIRET correspond exactement. |
| `SIRET_INVALID` | Le SIRET de la ligne n’est pas valide : la recherche s’est faite sans lui. |
| `SIRET_NOT_FOUND` | Aucun établissement trouvé pour ce SIRET. |
| `ESTABLISHMENT_NOT_FOUND` | L’entreprise existe, mais cet établissement n’a pas été trouvé. |
| `NO_CANDIDATE` | Aucun établissement correspondant trouvé. |
| `PROVIDER_RESULTS_NOT_EXHAUSTIVE` | Le registre n’a renvoyé qu’une partie des résultats : d’autres établissements peuvent exister. |
| `INPUT_INSUFFICIENT_FOR_REGISTRY` | Informations insuffisantes pour la recherche : indiquez un SIRET, ou un nom avec le code postal ou la ville. |
| `MULTIPLE_CANDIDATES` | Plusieurs établissements sont possibles. Comparez les propositions. |
| `CANDIDATES_TRUNCATED` | Seuls les premiers établissements sont présentés. |
| `REGISTRY_UNAVAILABLE` | Le registre des entreprises était indisponible : ce n’est pas une absence. Relancez plus tard. |
| `REGISTRY_RATE_LIMITED` | Le service de recherche reçoit trop de demandes. Réessayez dans un instant. |
| `GEOCODING_UNAVAILABLE` | Les coordonnées n’ont pas pu être recherchées pour le moment. |
| `GEOCODING_RATE_LIMITED` | Le service de géocodage reçoit trop de demandes : coordonnées non recherchées pour le moment. |
| `BUDGET_EXHAUSTED` | Limite de requêtes atteinte : certaines vérifications n’ont pas été faites. Relancez plus tard. |
| `INTERNAL_ERROR` | Cette ligne n’a pas pu être traitée. Relancez la recherche plus tard. |
| `NAME_MATCH` | Le nom correspond à la recherche. |
| `NAME_NOT_CORROBORATED` | Le nom reste à vérifier. |
| `ADDRESS_MATCH` | L’adresse correspond à la recherche. |
| `ADDRESS_NOT_CORROBORATED` | L’adresse reste à vérifier. |
| `ADDRESS_CONFLICT` | L’adresse trouvée diffère de celle de la ligne. |
| `ADDRESS_IMPRECISE_INPUT` | L’adresse de la ligne n’a pas de numéro : comparaison limitée. |
| `ADDRESS_FROM_ROW` | Position calculée à partir de l’adresse de la ligne. |
| `ESTABLISHMENT_CLOSED` | Établissement fermé selon le registre. |
| `DIFFUSION_PARTIAL` | Diffusion partielle : certaines informations ne sont pas publiques. |
| `HEADQUARTERS` | Il s’agit du siège de l’entreprise, pas forcément du commerce. |
| `COORDINATES_ALREADY_PRESENT` | Les coordonnées de la ligne sont déjà renseignées : elles sont conservées. |
| `GEOCODE_NOT_FOUND` | Aucune position trouvée pour cette adresse. |
| `GEOCODE_ADDRESS_MISMATCH` | La position trouvée ne correspond pas exactement à l’adresse. |
| `GEOCODE_IMPRECISE` | Position approximative (rue ou commune), pas l’adresse exacte. |
| `VAT_ALREADY_PRESENT` | La TVA de la ligne est déjà renseignée : elle est conservée. |
| `VAT_NOT_ELIGIBLE` | TVA non recherchée pour cet établissement. |
| `VAT_FOUND_IN_SOURCE` | TVA trouvée dans la source DGFiP datée (ce n’est pas une vérification VIES). |
| `VAT_NOT_FOUND_IN_SOURCE` | TVA absente de la source DGFiP (n’exclut pas un numéro hors de cette source). |
| `VAT_MULTIPLE_NUMBERS` | Plusieurs numéros de TVA dans la source : aucun n’est proposé. |
| `VAT_UNAVAILABLE` | Source TVA indisponible : TVA non vérifiée, ce n’est pas une absence. |
| `VAT_RATE_LIMITED` | Source TVA indisponible : TVA non vérifiée, ce n’est pas une absence. |
| `VAT_BUDGET_EXHAUSTED` | Source TVA indisponible : TVA non vérifiée, ce n’est pas une absence. |
| `VAT_INVALID_RESPONSE` | Source TVA indisponible : TVA non vérifiée, ce n’est pas une absence. |
| `VAT_RESULTS_INCOMPLETE` | Source TVA indisponible : TVA non vérifiée, ce n’est pas une absence. |
| `ROW_VERSION_CHANGED` | La ligne a été modifiée depuis la recherche : lancez une nouvelle recherche avant de choisir. |
| `ROW_NOT_PENDING` | Ligne déjà validée, écartée ou importée : elle n’a pas été recherchée. |
| `ROW_NOT_PARTNER` | Ligne client et non commerçant : elle n’a pas été recherchée. |
| `APPLIED` | Proposition appliquée au brouillon. |
| `APPLIED_FIELD_SIRET` | Champ appliqué au brouillon : SIRET. |
| `APPLIED_FIELD_LAT` | Champ appliqué au brouillon : Latitude. |
| `APPLIED_FIELD_ZZZ` | Une vérification complémentaire est nécessaire. |
| `CODE_INCONNU` | Une vérification complémentaire est nécessaire. |

### field()

| Clé | Texte affiché |
|---|---|
| `name` | Nom |
| `type` | Type |
| `siret` | SIRET |
| `siren` | SIREN |
| `legal_name` | Raison sociale |
| `email` | Email |
| `phone` | Téléphone |
| `street` | Adresse |
| `zip` | Code postal |
| `city` | Ville |
| `country` | Pays |
| `lat` | Latitude |
| `lng` | Longitude |
| `activity_sectors` | Secteurs d’activité |
| `code` | Code |
| `intracommunity_vat_number` | TVA intracommunautaire |
| `iban` | IBAN |
| `bic` | BIC |
| `bank_key` | Clé RIB |
| `account_number` | Numéro comptable |
| `naf` | Code NAF |
| `website` | Site web |
| `cle_inconnue` | Autre information |

### proposalState()

| État | Texte affiché |
|---|---|
| `matched` | Correspondance trouvée |
| `ambiguous` | Choix manuel requis |
| `address_only` | Adresse seule |
| `not_found` | Aucun résultat |
| `insufficient_input` | Informations insuffisantes |
| `provider_unavailable` | Source indisponible |
| `stale` | Ligne modifiée depuis la recherche |
| `skipped` | Non recherchée |
| `applied` | Appliquée au brouillon |
| `inconnu` | État à vérifier |

### jobStatus()

| Statut | Texte affiché |
|---|---|
| `queued` | En attente |
| `running` | En cours |
| `completed` | Terminée |
| `completed_with_errors` | Terminée, sources parfois indisponibles |
| `failed` | Échec |
| `cancelled` | Annulée |
| `inconnu` | État inconnu |

### matchLevel()

| Niveau | Texte affiché |
|---|---|
| `exact_identifier` | SIRET identique |
| `name_address` | Nom et adresse concordants |
| `ambiguous` | Correspondance à confirmer |
| `address_only` | Adresse seule |
| `inconnu` | Correspondance à vérifier |

### establishmentStatus()

| Statut | Texte affiché |
|---|---|
| `active` | Établissement actif |
| `closed` | Établissement fermé |
| `null` | État de l’établissement non renseigné |

### provider()

| Fournisseur | Texte affiché |
|---|---|
| `recherche_entreprises` | Recherche d’entreprises |
| `ign_geocodage` | Géocodage IGN |
| `dgfip_tva` | DGFiP |
| `inconnu` | Source publique |

### geoPrecision()

| Précision | Texte affiché |
|---|---|
| `housenumber` | Adresse précise |
| `street` | Rue |
| `locality` | Lieu-dit |
| `municipality` | Commune |
| `null` | Précision non renseignée |

### vatStatus()

| Statut (capability) | Texte affiché |
|---|---|
| `found (true)` | Trouvée dans la source DGFiP datée |
| `not_found (true)` | Absente de la source DGFiP (n’exclut pas un numéro hors de cette source) |
| `ambiguous (true)` | Plusieurs numéros dans la source : aucun proposé, choix manuel hors outil |
| `unavailable (true)` | Source indisponible : non vérifiée, ce n’est pas une absence |
| `not_checked (true)` | Non vérifiée |
| `tout statut (false)` | Non vérifiée |

### sourceDate()

| Entrée | Texte affiché |
|---|---|
| `2026-11-03` | 3 novembre 2026 |
| `2026-11-01` | 1er novembre 2026 |
| `2026-11-03T08:00:00Z (heure locale du poste)` | 3 novembre 2026 à 09:00 |
| `2026-02-30` | Date non disponible |
| `null / vide / texte` | Date non disponible |

### importIssue()

| Code | Texte affiché |
|---|---|
| `NAME_REQUIRED` | Le nom est obligatoire. |
| `TYPE_INVALID` | Type à choisir : commerçant ou client. |
| `EMAIL_REQUIRED` | L’email est obligatoire. |
| `EMAIL_INVALID` | L’email n’est pas valide (exemple : contact@commerce.fr). |
| `SIRET_REQUIRED` | Le SIRET est obligatoire pour un commerçant. |
| `SIRET_INVALID` | Le SIRET n’est pas valide : vérifiez ses 14 chiffres. |
| `SIRET_DUPLICATE` | Ce SIRET figure sur une autre ligne du lot. |
| `REMOVED_FROM_NETWORK` | Ce SIRET correspond à une fiche retirée du réseau : restaurez-la depuis les entités supprimées. |
| `ALREADY_IN_NETWORK` | Ce SIRET est déjà présent dans le réseau : l’import complétera la fiche existante. |
| `EXISTS_ELSEWHERE` | Ce SIRET existe déjà dans Tribuneo : l’import rattachera la fiche à ce réseau. |
| `PHONE_MISSING` | Téléphone absent. |
| `ADDRESS_INCOMPLETE` | Adresse incomplète : rue, code postal et ville attendus. |
| `LAT_INVALID` | Latitude invalide : nombre entre -90 et 90 attendu. |
| `LNG_INVALID` | Longitude invalide : nombre entre -180 et 180 attendu. |
| `COORDINATES_INCOMPLETE` | Latitude et longitude vont ensemble : renseignez les deux. |
| `COORDINATES_MISSING` | Sans coordonnées, le commerçant n’apparaîtra pas sur la carte. |
| `IBAN_INVALID` | IBAN invalide : vérifiez son format. |
| `VAT_INVALID` | Numéro de TVA intracommunautaire invalide (exemple : FR03552081317). |
| `SECTOR_UNKNOWN` | Secteur d’activité inconnu : il sera créé à l’import. |
| `CODE_INCONNU, field: zip` | Vérifiez le champ « Code postal ». |
| `CODE_INCONNU, sans champ` | Vérifiez les informations de cette ligne. |

### importFailure()

| Entrée | Texte affiché |
|---|---|
| `ROW_IMPORTED` | Cette ligne a déjà été importée. |
| `ROW_NOT_FOUND` | Cette ligne n’existe plus dans le lot. Actualisez la grille. |
| `BATCH_NOT_IMPORTABLE` | Le lot n’est pas prêt pour l’import. Actualisez la grille. |
| `NOTHING_TO_IMPORT` | Aucune ligne validée à importer. |
| `texte libre / SQL / anglais / null` | Impossible d’importer cette ligne. Vérifiez ses informations puis relancez l’import ; si l’échec persiste, contactez le support. |
