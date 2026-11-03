# Règles du contrat v1.1 — TVA intracommunautaire sourcée (lot 02, E03)

Extension de [CONTRAT_V1.openapi.json](../CONTRAT_V1.openapi.json) et
[REGLES_CONTRAT_V1.md](../REGLES_CONTRAT_V1.md), qui restent gelés et inchangés. Ces deux
fichiers v1.1 sont copiés à l'identique dans le BO (`docs/merchant-enrichment/v1.1/`).
La consolidation des copies actives du contrat revient à M12.

## Ce qui change (et seulement cela)

| Schéma | v1.0.0 | v1.1.0 |
|---|---|---|
| `Candidate.vat_status` | `const: not_checked` | `enum: not_checked, found, not_found, unavailable, ambiguous` |
| `FieldSource.provider` | `recherche_entreprises, ign_geocodage` | + `dgfip_tva` |
| `ProposedFields.intracommunity_vat_number` | `string|null` | `string|null`, motif `^FR[0-9A-Z]{2}[0-9]{9}$` |

Aucune route, aucun champ requis, aucune enveloppe, aucun code d'erreur nouveau. Une réponse
v1.0.0 (TVA `not_checked`, valeur null) est une réponse v1.1 valide : les anciennes
propositions restent lisibles. Un client v1.1 lit un `vat_status` absent ou inconnu comme
`not_checked`.

## Activation

- Serveur : `MERCHANT_ENRICHMENT_VAT_ENABLED=false` par défaut, indépendant des autres flags.
- `capabilities.vat = true` seulement si l'enrichissement est actif pour le tenant (flag +
  allowlist) ET le flag TVA est actif. La source est publique et anonyme : aucune clé.
- Flag TVA éteint : aucun appel TVA, et les propositions sont rendues dans la forme exacte du
  lot 01 (`vat_status: not_checked`, TVA null, pas de source TVA), même si une recherche faite
  flag allumé a stocké une TVA. L'application de la TVA est alors refusée (400).

## Statuts

| `vat_status` | Sens | Valeur proposée |
|---|---|---|
| `not_checked` | pas de recherche TVA (flag éteint, ancienne proposition, adresse seule, TVA déjà saisie, candidat non éligible) | null |
| `found` | réponse réussie et exhaustive, UN seul numéro distinct pour ce SIREN dans la source datée | numéro normalisé |
| `not_found` | réponse réussie et exhaustive, aucun numéro pour ce SIREN dans la source | null |
| `ambiguous` | plusieurs numéros distincts pour ce SIREN : aucun n'est choisi | null |
| `unavailable` | 401/403/429, délai, 5xx, redirection, réponse illisible/incomplète, budget épuisé | null |

`found` = « présent dans la source publique datée », jamais une validation VIES en temps réel
ni une garantie d'assujettissement. `not_found` n'est pas la preuve qu'aucun numéro n'existe
hors de cette source. Une panne n'est jamais une absence.

## Recherche (worker)

- Seulement après un candidat `kind: establishment` français (pays France, non étranger), au
  SIRET valide (Luhn) qui commence par son SIREN ; jamais pour `kind: address`, un identifiant
  invalide ou une ligne dont la TVA est déjà renseignée (`VAT_ALREADY_PRESENT`).
- Un appel par SIREN distinct d'une proposition ; le cache daté partagé (tenant + URL) évite
  de répéter le même SIREN entre lignes pendant `MERCHANT_ENRICHMENT_CACHE_TTL_SECONDS`.
- Le numéro vient de la source : `FR` + clé de deux caractères (chiffres OU lettres) + SIREN.
  La clé n'est jamais calculée ; une clé alphanumérique n'est jamais écartée.
- Un échec TVA ne change ni l'état de la proposition, ni les autres champs, sources ou
  candidats (registre, adresse, coordonnées).

## Source d'un champ TVA (`sources.intracommunity_vat_number`)

`provider: dgfip_tva` ; `url` : URL publique de l'enregistrement retenu
(`…/numeros-de-tva-intracommunautaires-francais/records?where=vat_no="<valeur publiée>"`) ;
`retrieved_at` : date réelle de lecture, conservée par le cache ; `record_id` : valeur `vat_no`
telle que publiée ; `precision: null`.

## Codes de raison ajoutés

Candidat : `VAT_FOUND_IN_SOURCE`, `VAT_NOT_FOUND_IN_SOURCE`, `VAT_MULTIPLE_NUMBERS`,
`VAT_UNAVAILABLE`, `VAT_RATE_LIMITED`, `VAT_RESULTS_INCOMPLETE`, `VAT_INVALID_RESPONSE`,
`VAT_BUDGET_EXHAUSTED`, `VAT_NOT_ELIGIBLE`.

Proposition : `VAT_ALREADY_PRESENT`, et les codes de panne (`VAT_UNAVAILABLE`,
`VAT_RATE_LIMITED`, `VAT_RESULTS_INCOMPLETE`, `VAT_INVALID_RESPONSE`, `VAT_BUDGET_EXHAUSTED`).

## Application (POST …/apply, inchangé dans sa forme)

`fields` peut contenir `intracommunity_vat_number` seulement si, dans l'ordre :

1. flag TVA actif pour le tenant, sinon `400 ENRICHMENT_INVALID_REQUEST` ;
2. candidat `found`, numéro au motif, rattaché au SIREN du candidat, source `dgfip_tva`,
   sinon `400 ENRICHMENT_INVALID_REQUEST` ;
3. dans la transaction CAS existante : mêmes contrôles qu'au lot 01 (version, base_version,
   statut, SIRET de la ligne égal à celui du candidat, champs vides → `FIELD_NOT_EMPTY`), puis
   SIRET EFFECTIF de la ligne après l'opération = SIRET déjà saisi, ou SIRET du candidat accepté
   dans la même opération ; vide ou d'un autre SIREN → `409 ENRICHMENT_IDENTITY_CONFLICT`.
   La TVA seule sur une ligne sans SIRET est donc refusée.

SIRET + TVA s'appliquent en une seule écriture et une seule incrémentation de version ;
validateur, doublons et idempotence existants inchangés. `missing_only` : une TVA déjà
renseignée n'est jamais remplacée.
