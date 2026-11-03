# Enrichissement commerçants — E02, lot 01

Le bouton « Compléter les informations » est intégré à la grille d’import. Le build normal garde `MERCHANT_ENRICHMENT_ENABLED=false`. Le client consulte les capabilities uniquement si ce flag est activé ; une API ancienne, une capability désactivée ou une erreur réseau ne lance aucune recherche et laisse l’import existant disponible.

## Organisation

- `domain/models/merchant_enrichment/` : jobs, pages, propositions, candidats et provenance ; aucun ajout aux modèles partagés d’import.
- `domain/repositories/merchant_enrichment/` : transport injectable et adaptateur Tribuneo utilisant `ApiClient`, l’authentification humaine et le tenant courant existants.
- `domain/usecases/merchant_enrichment/` : session bornée à un tenant et un lot, idempotence, lecture, annulation et application.
- `presentation/widgets/merchant_enrichment/` : sélection explicite de lignes pending de type partner, lancement confirmé, historique, comparaison et choix humains.

Les requêtes utilisent exclusivement les routes du contrat v1 : capabilities ; liste/création des jobs ; lecture d’un job ; propositions paginées ; annulation du job ; application d’une proposition. Les erreurs utilisent `error.details.code`. Les succès utilisent `data`, notamment `data.items/total/limit/offset` et `data.proposal/row/related`.

Le worker ne touche pas la grille. L’application envoie seulement `candidate_id`, `expected_version`, `fields` et l’accord éventuel pour coordonnées approximatives, avec `PendingIdempotencyKey`. Les valeurs ne sont jamais envoyées par ce parcours. Le serveur reste responsable du CAS, du contexte d’adresse, de l’identité, de la transaction et du recalcul des anomalies/doublons. Les valeurs non vides, dont zéro, ne sont pas sélectionnables. Latitude/longitude se sélectionnent ensemble. Les champs TVA ne sont pas applicables au lot 01.

Après application, `row` et `related` passent par le remplacement existant, qui conserve la version la plus récente. Le statut cible doit rester pending. Les propositions appliquées restent dans l’historique dédié. Un conflit relit les lignes du lot, désactive cette proposition dans la session et ne renvoie jamais l’application automatiquement. Un refus d’idempotence « en cours » reste réessayable avec la même clé.

## Contrat partagé

`CONTRAT_V1.openapi.json` et `REGLES_CONTRAT_V1.md` de ce dossier sont les copies identiques
(même SHA-256) du contrat gelé v1 utilisé par l'API (`docs/specs/api/merchant-enrichment/`
du dépôt API). Toute évolution se fait des deux côtés, par une nouvelle version du contrat.

## Lecture et arrêt

L’ouverture relit la liste persistée des jobs et reprend le plus récent ; l’historique est paginé par 20 jobs. Les propositions sont paginées par 50. La lecture automatique utilise un minuteur après chaque requête, sans chevauchement, toutes les 3 secondes et au plus 100 cycles par reprise. Chaque requête d’enrichissement est bornée à 25 secondes. Une erreur met la lecture automatique en pause. Le temps total dépend donc aussi de la durée des requêtes ; 5 minutes est seulement l’ordre de grandeur sans latence.

Fermer arrête les lectures et invalide leurs réponses tardives ; cela laisse le job serveur continuer. « Annuler la recherche » appelle uniquement l’annulation du job, jamais celle du lot. La destruction de la grille détruit la session. Aucun cache d’écriture n’est partagé entre tenants. Les corrections doivent avoir fini de s’enregistrer avant d’ouvrir le dialogue ; elles restent possibles dans la grille après sa fermeture.

## Vérification locale sans API

Depuis le BO :

```powershell
flutter test --no-pub test/merchant_enrichment
flutter run --no-pub -d chrome -t test/merchant_enrichment/local_ui.dart
```

Le second point d’entrée importe uniquement les widgets, les modèles, le usecase et le faux transport situé sous `test/`. Il n’importe ni `ApiClient`, ni Env, ni l’application habituelle. Il affiche son caractère synthétique et propose des commandes locales pour terminer le job, simuler le réseau absent ou un conflit. Il n’est référencé par aucun code de production. Ne pas publier un build fait avec ce point d’entrée.

Les captures `ui-launch.png`, `ui-proposals.png`, `ui-compare.png` viennent des tests widget à 1280 × 1000, avec données inventées. Leur régénération est explicite et réservée au poste Windows équipé du SDK local et des polices utilisées par le test :

```powershell
flutter test --no-pub --dart-define=E02_CAPTURE_UI=true test/merchant_enrichment/enrichment_panel_test.dart
```

## Vérification locale avec la vraie API (fournisseurs simulés)

Après `scripts/merchant-enrichment/e2e/local-stack.sh up` dans le dépôt API (pile Docker jetable,
données synthétiques, serveurs sur 127.0.0.1 seulement) :

```powershell
flutter test --no-pub test/merchant_enrichment/live_local_api.dart --dart-define=ENRICHMENT_E2E=http://127.0.0.1
```

Ce fichier (sans suffixe `_test`, donc hors de la suite par défaut) utilise le repository, le
usecase et les modèles réels du BO sur HTTP : flag serveur absent et import existant, API sans
enrichissement (404), recherche, application CAS, accord de précision, rejeu idempotent,
proposition périmée après correction humaine, isolation réseau et annulation. Il n'est jamais à
pointer vers une API de préproduction ou de production.

Les tests normaux n’exigent pas ces polices. Aucun flag de mock n’est ajouté au build de production. Aucune dépendance, migration, configuration Env ou activation serveur n’est requise par ces sources BO. La recette connectée et le build complet avec la configuration habituelle du propriétaire restent à faire après intégration.
