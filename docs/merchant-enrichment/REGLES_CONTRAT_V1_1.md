# Contrat actif M12 — v1.1 et comparaison chat

3 novembre 2026. Copie identique API/BO/Néo. `CONTRAT_V1_1.openapi.json` consolide les
routes d'enrichissement v1.1 et `/chat/sessions`, `/chat/sessions/{id}/messages`.
Les schémas chat y portent le préfixe `Chat` pour éviter les collisions de `Error`.
`CONTRAT_CHAT.openapi.json` reste aussi disponible séparément. Les extensions de
mission sous `v1.1/` et `chat/` et les références `CONTRAT_V1`/`REGLES_CONTRAT_V1`
restent conservées ; les tests historiques continuent à contrôler v1.

## Compatibilité et activation

Les règles v1 s'appliquent, sauf les extensions explicitement décrites ici et dans
`REGLES_CHAT.md`. Les booléens `vat` et `chat_resolution` sont indépendants :

| TVA / chat serveur | TVA affichable/applicable | Comparaison |
|---|---|---|
| 00 | Non | Non |
| 10 | Oui, si trouvée et cohérente | Non |
| 01 | Non | Oui |
| 11 | Oui, si trouvée et cohérente | Oui |

Ils exigent aussi l'enrichissement et son allowlist de tenants. Le chat exige
CCI04 et une configuration ChatConfig utilisable (ceci n'est pas un healthcheck).
Flags absents = false. Le BO conserve ses deux flags de compilation existants,
`MERCHANT_ENRICHMENT_ENABLED` et `NEO_CHAT_ENABLED`, false par défaut.

Une ancienne proposition sans résultat TVA reste lisible (`not_checked`, numéro
null). L'extinction du flag TVA masque la TVA stockée et refuse son apply : les
propositions sans TVA sont conformes au schéma v1 gelé. Une réponse avec TVA
`found` relève de v1.1, pas du schéma v1. Un BO ancien tolère les nouvelles valeurs
et sources et conserve son choix manuel des champs v1 ; il n'offre pas d'apply TVA.
Un BO ancien ignore les blocs chat inconnus. Le BO actuel traite les capacités
absentes comme false ; une ancienne API 404 désactive la recherche. Le refus d'un
contexte par un ancien serveur ne doit jamais relancer ce message en chat ordinaire.
Une panne de comparaison conserve recherche, comparaison manuelle et apply humain.

## TVA sourcée

Fournisseur `dgfip_tva`, jeu public DGFiP qualifié dans
`v1.1/QUALIFICATION_SOURCE_TVA.md`. L'accès fonctionnel anonyme et le filtre exact
ont été rejoués depuis le poste ; l'accès depuis le VPS reste un préalable à toute
activation. Le champ disponible dans un catalogue ne suffirait pas à cette preuve.
Pas d'API Entreprise présumée accessible, formule de clé, VIES ni garantie fiscale.

`found` exige une réponse fournisseur réussie et exhaustive, un unique numéro
distinct rattaché au SIREN corroboré. Clés numériques et alphanumériques conservées.
Plusieurs numéros : `ambiguous`, valeur null. Zéro résultat exhaustif : `not_found`
dans cette source seulement. Erreur, quota, délai, réponse incomplète ou illisible :
`unavailable`, jamais une absence. Le registre, le SIRET, l'adresse et le GPS valides
restent disponibles. Aucun appel pour `kind=address`, identifiant invalide, TVA
déjà saisie ou hors périmètre ; déduplication par SIREN, budget partagé inchangé.

Provenance du champ : URL HTTPS exacte de l'enregistrement DGFiP, `record_id`
correspondant au numéro, `retrieved_at` RFC3339 réel conservé par le cache,
`precision: null`. Les métadonnées et le SIRET du candidat sont revérifiés avant
présentation et apply. La TVA ne s'applique qu'avec un SIRET effectif valide portant
le même SIREN : SIRET déjà présent ou accepté dans la même opération atomique.
Sans SIRET, la TVA seule est refusée. `missing_only`, CAS et idempotence existants
restent obligatoires ; aucun écrasement d'une TVA saisie ni validation/import.

Les deux dates métier de la source ne sont pas qualifiées et ne sont pas utilisées.
Le filtre exact énumère 1 296 clés, URL ~26 Ko ; si le format de publication change,
requalifier avant activation. Pire cas : jusqu'à cinq appels TVA supplémentaires
par ligne, sans relever le plafond de 12 000 requêtes/job.

## Chat contextualisé

Référence client strictement limitée à batch/row/proposal/version. Ni tenant JSON,
champs, candidats, URL ni contenu du navigateur ne deviennent une autorité.
Contrôles humains et contexte serveur avant cache/LLM et après LLM ; après l'attente,
relecture session humaine, expiration du jeton, rôle et appartenance au réseau.
Révocation : réponse refusée, aucun bloc ni cache de réponse publié.

Session dédiée neuve, owner tenant:user:session, binding Redis atomique immuable,
TTL 3 600 s et verrou 100 s pour un appel Hermes borné à 75 s. Chaque message
contextuel renvoie sa référence ; session ordinaire/historique non convertible.
Digest : message, référence/version, empreinte du contenu serveur ; même request_id
avec contenu différent : conflit. Revalidation avant tout rejeu du cache.

Lecture du tenant autorisé seulement : batch review, ligne pending partner,
proposition liée au batch/row/job, non appliquée, ambiguous, versions concordantes,
1 à 5 candidats. Projection publique au plus 16 Kio avec chaînes bornées : nom,
SIRET, adresse, raisons et sources registre/IGN autorisées. Pas de TVA ajoutée au
contexte par cette intégration, ni email/téléphone/banque/compte/fichier/secret.
Les noms, libellés et sources sont des données non fiables, jamais des instructions.
Pas de lecture libre d'URL, de navigateur ou de nouvelle recherche Internet.

Le serveur reconstruit `enrichment_candidates` depuis les candidats persistés et
revalidés ; aucune sortie du modèle ne crée d'action. La liste n'est pas présentée
comme un classement LLM. Le clic relit ligne/proposition/version/appartenance puis
ouvre la comparaison existante. Seule la confirmation humaine appelle le apply
existant avec Idempotency-Key et version. Stale, tenant changé, logout, fermeture
ou réponse tardive invalident le contexte. Aucun outil JWT agent supplémentaire.

Erreurs, formes et limites détaillées : `REGLES_CHAT.md` et contrats OpenAPI actifs.
Les routes et protections de chat ordinaire restent disponibles sans contexte.
