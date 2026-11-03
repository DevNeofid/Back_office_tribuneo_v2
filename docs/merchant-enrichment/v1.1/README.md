# Enrichissement commerçants — extension v1.1 : TVA sourcée (lot 02, E03, BO)

[CONTRAT_V1_1.openapi.json](CONTRAT_V1_1.openapi.json) et [REGLES_CONTRAT_V1_1.md](REGLES_CONTRAT_V1_1.md)
sont les copies identiques (même SHA-256) de `docs/specs/api/merchant-enrichment/v1.1/` du
dépôt API. Le contrat v1 du dossier parent reste inchangé ; M12 consolide les copies actives.

## Comportement

- Aucun nouveau flag de build : la TVA dépend de `capabilities.vat` renvoyé par le serveur
  (`MERCHANT_ENRICHMENT_VAT_ENABLED` côté API). Absente (ancienne API) ou `false` : affichage du
  lot 01 (« TVA non vérifiée »), aucune valeur ni case TVA.
- `vat_status` absent ou inconnu (ancienne proposition, ancien serveur) est lu `not_checked`.
- Dans « Comparer / choisir », une section TVA par établissement : statut, valeur, source DGFiP
  avec URL, référence et date de lecture, et la mention « présence dans le jeu public DGFiP à la
  date indiquée, ni vérification VIES en temps réel ni garantie d’assujettissement ».
- Case de choix seulement pour une TVA `found`, bien formée, de source `dgfip_tva`, rattachée au
  SIREN du candidat. `not_found`, `ambiguous` et `unavailable` s’affichent sans case ; une panne
  est libellée « ce n’est pas une absence ». Aucun bouton de vérification.
- Ligne sans SIRET : cocher la TVA coche aussi le SIRET du candidat, décocher le SIRET retire la
  TVA ; le usecase refuse d’envoyer une TVA seule. Ligne avec le même SIRET : TVA seule possible.
  Autre SIRET ou TVA déjà saisie : rien d’applicable (valeur actuelle affichée, conservée).
- L’application garde le parcours du lot 01 : `candidate_id`, `expected_version`, `fields`,
  clé d’idempotence ; jamais de valeur envoyée. Le serveur reste juge (flag, SIRET effectif,
  version, champs vides).

## Code

- `lib/domain/models/merchant_enrichment/vat_status.dart` : statuts, numéro proposé, règles de
  sélection SIRET/TVA ;
- `enrichment_models.dart` : `EnrichmentCapability.vat`, `EnrichmentCandidate.vatStatus` ;
- `enrichment_usecase.dart` : TVA ajoutée à `applicable()` sous ces règles, refus d’une TVA seule ;
- `lib/presentation/widgets/merchant_enrichment/vat_presentation.dart` et `enrichment_panel.dart`.

## Tests

```powershell
flutter test --no-pub test/merchant_enrichment
```

`test/merchant_enrichment/vat_usecase_test.dart` (faux transport v1.1, décodage ancien/nouveau,
règles d’applicabilité, envoi, copie du contrat) et `vat_panel_test.dart` (widget : valeur,
source datée, mention, case liée au SIRET, statuts sans case, capability éteinte, TVA existante).
