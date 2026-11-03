# Comparaison contextualisée — contrat chat 1.0.0

Extension du lot 01 ; les contrats v1 actifs sont inchangés. Le chat ordinaire et sa
documentation provisoire sont conservés. Pas de nouvelle route, outil MCP, clé ou migration.

## Activation et autorisation

`MERCHANT_ENRICHMENT_CHAT_ENABLED=false` par défaut. La capability `chat_resolution` exige
ce flag, l’enrichissement actif pour le tenant autorisé, CCI04 et ChatConfig disponible
(flag NEO_CHAT_ENABLED, destination privée fixe, clé protégée configurée). Cette disponibilité
est celle de la configuration, pas une sonde de santé Hermes. Une panne à l’appel retourne
CHAT_UNAVAILABLE ; le choix manuel du lot 01 reste accessible.

Authentification humaine, rôle NETWORK_ADMIN, réseau, Origin web autorisé et session inchangés.
Aucun accès au brouillon par JWT agent. Le corps contextualisé contient seulement quatre
références : entiers JSON positifs et UUID minuscule, sans clé supplémentaire. Le serveur relit
dans ce tenant le lot review, row pending partner, proposition ambiguous non appliquée, job
du même lot et version courante = expected_version = base_version. Absence/référence croisée :
404 générique sans détails d’une autre ligne. Version/statut changé : 409. Flag/dépendance/
taille/source indisponible : 503. Forme invalide : 400. Voir les codes du fichier OpenAPI.

## Session et cache

Chaque comparaison crée une session neuve. Chaque message dédié exige le même contexte.
Le Lua vérifie atomiquement l’owner et le jeton du verrou avant de lier le contexte canonique
ou le marqueur ordinary. Une session utilisée en chat ordinaire ne devient pas contextualisée.
Les anciennes sessions sans marqueur peuvent continuer en chat ordinaire ; la comparaison
exige une session neuve munie du marqueur fresh. Un changement de contexte est refusé.
TTL session/binding/cache 3600 s, verrou 100 s, appel Hermes borné à 75 s, réponse ≤1 Mio.
La relecture autorisée précède tout accès au cache ; l’owner/lease et le contexte sont relus
après Hermes avant tout retour de boutons. Digest : message, références/version et empreinte
de la projection publique relue. Même request_id avec digest différent : CHAT_REQUEST_CONFLICT
avant modification du binding. Les blocs renvoyés par le modèle sont ignorés.

## Données et budget

Hermes reçoit les champs name/siret/street/zip/city/country de la ligne et des candidats,
identifiants/libellés candidats, sources de ces champs et reason_codes. Aucun email, téléphone,
IBAN/BIC, compte, fichier, note privée, ligne complète, session humaine ou secret du BO.
Pas de SIREN/TVA/GPS ajouté à la projection. Les noms et libellés restent des données non
fiables dans du JSON distinct des instructions. Rien n’est extrait du texte du modèle comme
commande ou bloc d’action. La lecture seule repose aussi sur le service de projection sans
méthode d’écriture et sur le profil existant à neuf outils métier en lecture.
Les tests vérifient zéro appel apply/import avant la confirmation humaine.

1 à 5 candidats uniques, contexte JSON public ≤16384 octets. Bornes par chaîne en octets :
champs/label 512 (SIRET 14), URL 2048, record_id 128, précision 40, date ISO 40 ; ≤20 raisons
de 80 ASCII. Dépassement refusé, sans troncature. Source HTTPS sur fournisseur/hôte exact :
recherche_entreprises/recherche-entreprises.api.gouv.fr ou ign_geocodage/data.geopf.fr.
Credentials, port explicite, fragment, caractères de contrôle et antislash interdits.
Aucune URL n’est visitée. Une future source nécessite sa qualification explicite.
Quotas existants inchangés : 10 créations/min/owner, 8 messages/min/owner, 60/min/tenant.
Aucun appel fournisseur ajouté aux jobs ni hausse de leur plafond. Une comparaison consomme
une création et ses messages ; la reprise d’un cache ne consomme pas de message supplémentaire.

## Retour humain et compatibilité

Réponse data.reply.text, blocks et tools conservée. Au plus un bloc enrichment_candidates,
reconstruit depuis la proposition revalidée, dans l’ordre stocké ; ce n’est pas le classement
du modèle. Le BO ignore tout bloc inconnu ou mal formé. Les boutons candidats sont rendus
uniquement dans le contrôleur dédié. Au clic : relecture des lignes, du job et des propositions
(au plus 40 pages de 50), contrôle tenant/version/statut/appartenance, puis dialogue existant.
Aucun champ n’est présélectionné. Seule la confirmation humaine appelle le apply missing_only
lot 01 avec expected_version et Idempotency-Key existants. Bouton périmé : comparaison invalidée.

Fermer/réduire/nouvelle conversation quitte la comparaison ; rouvrir crée une session neuve.
Le contrôleur ordinaire reste séparé. Fermeture et destruction ignorent les réponses tardives.
La disparition du bouton/grille invalide immédiatement le scope. Le tenant local est contrôlé
avant/après chaque échange et toutes les secondes pendant le dialogue. Le serveur fait autorité.
Un ancien BO ignore le nouveau bloc ; une ancienne API refuse enrichment_context sans réessai
qui supprimerait ce contexte. Une absence de candidat demande une précision puis une relance
de la recherche existante ; aucune prétention de recherche Internet supplémentaire.
