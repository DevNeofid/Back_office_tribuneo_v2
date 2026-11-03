# Règles partagées E01/E02 — contrat gelé v1

Les agents lisent ce fichier et CONTRAT_V1.openapi.json avant d'écrire. Ils ne
modifient pas la passation externe ni le contrat en parallèle. Un blocage est
consigné dans ECARTS, aucune divergence d'endpoint/JSON unilatérale. M12 arbitre
sur une preuve et actualise les deux côtés, avec contrôle de compatibilité.

## Séparation des étapes

Recherche en tâche de fond = propositions séparées des lignes. Aucun champ,
version ou statut de merchant_import_row n'est changé par le worker. Appliquer
est un POST explicite de l'admin ; il remplit uniquement les champs manquants,
recalcule les anomalies/doublons et laisse la ligne pending. Puis validation
humaine ligne par ligne et import existant, jamais déclenchés par cette feature.
Ne pas utiliser la case « ligne validée » comme sélection d'enrichissement.

Batch en review uniquement ; row_ids explicites, au plus 2 000, sans doublon.
Seules les lignes pending de type partner au démarrage sont prises, autres états
et lignes customer signalés/skipped sans requête fournisseur. Le type ne change pas.
Une ligne unknown/hors batch/tenant est refusée sans révéler un autre réseau.
Le job conserve snapshot minimal public (nom, SIRET, adresse) et version, jamais
IBAN/BIC, compte, e-mail, téléphone, notes ou fichier complet dans les requêtes.
Un seul job actif par lot ; le même Idempotency-Key/body rend le même job.
Les champs JSON et enveloppes existants de l'import ne changent pas.

## Identité, adresse et provenance

Un établissement local est distinct du siège et du SIREN/unité légale. Une recherche
par SIRET fourni exige un résultat exact ; les filtres de l'API publique ne prouvent
pas la localisation lors d'une recherche d'identifiant. Un nom seul ne suffit
jamais à marquer matched. matched = identifiant exact, ou candidat actif unique
corroboré par nom ET adresse suffisamment précise. Conserver raisons factuelles ;
pas de pourcentage de confiance inventé. Fermeture, diffusion limitée et conflit
d'adresse restent des raisons de relecture, jamais un choix silencieux du siège.

Au plus cinq candidats par proposition, classés de façon déterministe. Si la liste
fournisseur n'est pas exhaustive, ne pas affirmer unicité ; garder ambiguous.
Une réponse en erreur/429/timeout n'est pas not_found. Un géocodage seul peut
produire address_only, sans attribuer une entreprise/SIRET à l'adresse.

Valeurs conservées avec provider/URL/date/record/precision par champ. lat/lng sont
une paire valide, provenant de la même adresse, jamais mixées avec une ancienne
coordonnée. Une valeur numérique nulle (0) n'est pas un champ vide.
Application des coordonnées seulement si leur adresse correspond aux champs
actuels ou acceptés dans la même opération. Sinon ADDRESS_CONTEXT_CONFLICT.
Une précision street/locality/unknown exige acknowledgement humain explicite ;
elle ne devient jamais un emplacement de devanture certifié.
Un candidat d'un autre SIRET que celui déjà saisi ne peut pas être appliqué,
même pour récupérer sa TVA ou ses coordonnées (IDENTITY_CONFLICT).
Le nom commercial saisi n'est pas remplacé par la raison sociale du registre.
Si name est réellement vide, un nom d'établissement ou d'unité légale sourcé
peut être proposé pour ce champ, avec provenance et acceptation humaine.

## Application et concurrence

Le client envoie id_proposal, candidate_id, fields et expected_version, pas des
valeurs inventées. Le serveur relit la proposition stockée et la ligne du même
tenant/batch. expected_version ET base_version doivent correspondre à la version
actuelle. Tout changement de ligne rend la proposition stale : ne pas écraser une
correction manuelle. Champs cibles déjà renseignés : refus FIELD_NOT_EMPTY.
Seules les valeurs réellement proposées et non vides sont applicables ; champ
absent/null du candidat = INVALID_REQUEST. La TVA désactivée ne peut être appliquée.
Appliquer les champs d'un candidat en une transaction CAS, une seule incrémentation
de version. Réutiliser le validateur et le rafraîchissement des doublons existants.
Une nouvelle anomalie interdit la validation habituelle, pas une création forcée.
Réponse row + related actualise la grille. Les propositions restent dans leur
stockage séparé ; ne pas écraser suggested du fichier d'origine pour les stocker.
POST apply rejouable avec Idempotency-Key, sans double version ni double écriture.
Le BO n'applique pas une réponse tardive dont la version est inférieure à celle
déjà affichée (notamment rejeu idempotent) ; il relit si nécessaire.
Une ligne importée, validée entre-temps, rejetée ou un batch annulé/importing ne
peut pas être modifié par une proposition. Pas de cache d'écriture inter-tenant.

## Jobs, arrêt et consommation

Stockage durable par tenant et worker CLI dédié. Reprise par bail expirant et
jeton de possession/fencing ; pas de traitement double, perte silencieuse ou
écriture tardive après perte du bail. Budget/timeout configurables et bornés.
Annuler arrête ce job de recherche, jamais le batch d'import. Les propositions
déjà publiées restent consultables/applicables si leurs versions sont valides ;
aucun nouveau résultat après annulation. Progression monotone en lignes traitées.
Le BO peut continuer l'édition pendant le job ; une ligne modifiée produit stale.
Pagination de propositions stable par position de ligne puis identifiant.
GET de la liste des jobs, ordonnée par création descendante puis id, permet de
reprendre le dernier job/actif à réouverture, sans dépendre de la mémoire du navigateur.
Les propositions appliquées et leur provenance restent consultables dans l'historique.

HTTP serveur vers fournisseurs fixes seulement, requêtes encodées, timeout,
taille de réponse bornée, redirections non autorisées vers d'autres hôtes.
User-Agent descriptif, limite partagée entre workers/tenants pour le même
fournisseur/IP (défaut conservateur 3 requêtes/s), Retry-After/backoff borné.
Cache des lectures publiques avec TTL et provenance datée, tenant-aware pour
les requêtes qui révèlent l'entrée d'un lot ; une indisponibilité n'est pas
mise en cache comme absence. Pas de requête dans la transaction de sauvegarde.

## Activation, TVA et chat

Feature flag serveur MERCHANT_ENRICHMENT_ENABLED=false par défaut et allowlist
tenant explicite ; activation préproduction CCI04 uniquement au premier déploiement.
capabilities reste accessible au rôle humain pour renvoyer enabled=false.
Autres routes désactivées : 503 ENRICHMENT_DISABLED. Jamais d'agent JWT habilité
à importer ou d'accès anonymous. Tests de rôle/tenant/batch et chemins d'auth existants.
Le bouton BO a aussi son flag de build MERCHANT_ENRICHMENT_ENABLED=false par défaut,
et consulte capabilities. 404 d'une ancienne API = fonction indisponible, pas succès.

Premier lot : registry/geocoding, vat=false, chat_resolution=false, vat_status
not_checked et aucune intracommunity_vat_number proposée. Le champ est réservé
au lot suivant, pas rempli par calcul. Les secteurs, banque, contacts, website,
recherche HTML et appels LLM ne font pas partie d'E01/E02.
Les ambiguïtés se choisissent déjà manuellement dans une modale. Aucun bouton
« Résoudre avec Néo » actif ou promesse de chat branché avant E04.

## Codes de refus stables

ENRICHMENT_DISABLED (503), ENRICHMENT_INVALID_REQUEST (400),
ENRICHMENT_NOT_FOUND (404, générique), ENRICHMENT_ALREADY_RUNNING (409),
ENRICHMENT_BATCH_NOT_EDITABLE (409), ENRICHMENT_ROW_NOT_EDITABLE (409),
ENRICHMENT_VERSION_CONFLICT (409, row courante), ENRICHMENT_PROPOSAL_STALE (409),
ENRICHMENT_FIELD_NOT_EMPTY (409), ENRICHMENT_IDENTITY_CONFLICT (409),
ENRICHMENT_ADDRESS_CONTEXT_CONFLICT (409),
ENRICHMENT_PRECISION_CONFIRMATION_REQUIRED (422), ENRICHMENT_UNAVAILABLE (503).
Les erreurs fournisseur restent des raisons de proposition/job, pas du HTML brut.
Réutiliser les refus existants du validateur et de l'idempotence sans les masquer.
