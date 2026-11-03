# Contrat partagé gelé de préparation — lot 03

Autorité : ce fichier + CONTRAT_V1_2.openapi.json + SCHEMA_BLOC_RELANCE.json. Le socle
v1.1/TVA/chat est conservé. Toute évolution proposée est consignée, pas inventée d'un
côté du frontend. Les contrats actifs restent inchangés sur les branches de mission ;
E05 versionne research/, E06 research/ dans BO et chat-research/ dans API. M12 consolide.

## Périmètre produit

Rechercher à nouveau UNE ligne à partir de critères publics explicitement saisis/confirmés
par l'admin, depuis la grille ou le chat. Seules les API Recherche d'entreprises et IGN
déjà intégrées sont interrogées, avec l'option TVA existante si son propre flag est actif.
Pas d'URL libre, scraping, moteur payant, nouvel outil MCP ou droit au JWT agent.
Le modèle peut expliquer et demander une précision ; aucune de ses sorties ne lance
un job ni ne modifie une cellule. Un formulaire de confirmation reste obligatoire.

## Nouvelle activation

Serveur MERCHANT_ENRICHMENT_RESEARCH_ENABLED=false par défaut. Capability additive
targeted_research = enrichissement actif pour ce tenant ET nouveau flag. Elle ne dépend
pas d'Hermes : le formulaire manuel reste utilisable sans chat. Les anciens BO ignorent
la clé ; les anciens serveurs ne l'ont pas => false côté nouveau BO. Aucun nouveau flag
de build nécessaire en plus des deux flags BO existants. Les autres flags sont indépendants.

## Deux routes humaines

NETWORK_ADMIN, authentification humaine, X-Tenant et adhésion réseau ; aucune ouverture
agent. Les mécanismes existants de CSRF/session/Origin et idempotence sont conservés.

POST /merchant-import/{id_batch}/enrichment-research-jobs, Idempotency-Key obligatoire,
réponse 202 data.Job existant. Corps strict :

```json
{
  "row_id": 34,
  "expected_version": 2,
  "source_proposal_id": "6f1c2d3e-4b5a-4c6d-8e7f-001122334455",
  "search": {
    "name": "Commerce exemple",
    "siret": "",
    "street": "12 rue des Essais",
    "zip": "04000",
    "city": "Digne-les-Bains",
    "country": "FR"
  }
}
```

Les six clés search sont requises et sont des CHAÎNES, vides autorisées. Limites en
caractères : name/street 512, siret 14, zip 20, city 128, country 80 ; sérialisation
UTF-8 de search <=4096 octets. Pas de tableau, null, booléen, caractère de contrôle
ou URL comme critère ; rejet plutôt que troncature. Trim, SIRET vide ou 14 chiffres
Luhn valide. Pays vide/FR/France (casse ignorée) acceptés et normalisés FR pour ce
périmètre ; autre pays => 422 ENRICHMENT_RESEARCH_UNSUPPORTED_COUNTRY.
Il faut soit un SIRET valide, soit name + (zip à cinq chiffres ou city), soit street +
(zip à cinq chiffres ou city). Sinon 422 ENRICHMENT_SEARCH_INSUFFICIENT_INPUT sans job
ni appel fournisseur. Si zip non vide et pas cinq chiffres => 400 INVALID_REQUEST.

Le source_proposal_id appartient au tenant, lot, ligne et job du lot, non appliqué,
base_version et row.version = expected_version. États permis : matched, ambiguous,
address_only, not_found, insufficient_input, provider_unavailable. Refuser applied,
skipped, stale, row non pending partner ou batch non review. Un résultat fournisseur
en panne n'est jamais renommé « non trouvé » dans l'explication ou le formulaire.

Validation et lecture parent/ligne/version puis insertion du job et de son instantané
dans UNE transaction sous verrou batch puis row (ordre du apply existant). Pas de
requête externe dans la transaction. 1 seul job actif par lot, y compris les jobs lot 01.
Le replay idempotent garde le même job ; nouvelle clé en concurrence => ALREADY_RUNNING.
Limiter les créations ciblées à 10/min/utilisateur humain/tenant et 30/min/tenant
avec Redis partagé, refus 429 ENRICHMENT_RESEARCH_RATE_LIMITED + Retry-After ; un replay
déjà enregistré ne recrée rien. Ne pas ajouter le coût d'un message LLM à cette route.

GET /merchant-import/{id_batch}/enrichment-research-jobs/{id_job}, réponse data :
job (forme existante), row_id, base_version, source_proposal_id, criteria (six critères
normalisés effectivement utilisés). Accès humain tenant/batch ; un job ordinaire n'est
pas un job ciblé => 404 générique. Critères historiques lisibles même si la ligne a
changé ; leur application reste bloquée par stale/CAS. Aucun appel fournisseur au GET.

Erreurs dans l'enveloppe existante : INVALID_REQUEST 400, NOT_FOUND 404 générique,
VERSION_CONFLICT/PROPOSAL_STALE/ROW_NOT_EDITABLE/BATCH_NOT_EDITABLE/ALREADY_RUNNING 409,
ENRICHMENT_RESEARCH_DISABLED 503, UNAVAILABLE 503 ; les codes de base portent le préfixe
ENRICHMENT_. Les deux codes 422 et RATE_LIMITED sont définis ci-dessus. Référence d'un
autre tenant/lot/ligne => NOT_FOUND sans détails. Aucun détail sensible dans les logs.

## Stockage et worker

Réutiliser jobs, job_rows et proposals ; pas de nouvelle migration prévue. Dans le
snapshot JSON, garder les champs et missing/has_coordinates de la ligne actuelle et
ajouter un objet research {source_proposal_id, criteria}. Ce marqueur est construit
uniquement par le serveur, jamais lu depuis un champ/une note du fichier utilisateur.
Les six criteria sont validés/normalisés et complets, pas un patch ambigu à fusionner.
Le worker valide le marqueur et utilise criteria comme entrée de recherche ; missing,
has_coordinates, base_version et liens restent ceux de la ligne originale. Un marqueur
persisté mal formé => échec explicite, pas de repli silencieux sur une recherche différente.

Mode du job missing_only, 1 ligne, cancel/lease/fencing/budget/reprise inchangés. La TVA
suit son propre flag. Le resolver est réutilisé, pas forké ; tout SIRET doit rester
exact (les filtres publics sont ignorés pour une recherche numérique), pas de siège
substitué. Sources/datation/ambiguïtés et garde d'identité/adresse du apply sont conservées.
Les critères ne deviennent pas une source officielle de SIRET/TVA ou un champ du brouillon.
Une autre identité recherchée peut être refusée à l'application si la ligne a déjà un
SIRET différent : ne pas contourner la protection en effaçant ce SIRET automatiquement.

Seules les trois tables d'enrichissement reçoivent des écritures de recherche. Aucun
champ/version/status de merchant_import_row, suggested du fichier, entité, import ou
envoi modifié. Anciennes propositions/historiques conservés. Tous les traitements
partagent les mêmes limites et caches fournisseurs ; pas de boucles automatiques LLM.

## Dialogue et formulaire E06

« Préciser la recherche » disponible dans le panneau pour les états permis ci-dessus
et une version courante, si capability targeted_research. Depuis Néo, la même action
ouvre le MÊME formulaire. L'admin y saisit/corrige les critères puis confirme « Relancer
la recherche » ; message explicite que les cellules restent inchangées. Préremplissage
depuis la ligne autorisée, ou les derniers critères publics du job ciblé via GET metadata.
Ne jamais préremplir depuis des valeurs ou une URL récupérées dans du texte du modèle.
Ne pas analyser automatiquement la réponse en prose pour lancer une requête.

Après confirmation : un POST, clé conservée pour réessai identique, nouvelle clé si le
corps change, progression existante sur le nouveau job, annulation/reprise comme lot 01.
Une réponse tardive, autre tenant ou version changée n'écrase pas l'état courant.
Après nouveaux résultats, rouvrir une comparaison par une session dédiée neuve ; ne
pas réaffecter silencieusement le binding d'une ancienne conversation à une autre proposition.

Le chat lot 02 reste utilisable pour ambiguous quand le nouveau flag est off. Quand
targeted_research ET chat_resolution sont actifs, ContextReader peut aussi accepter
not_found, insufficient_input, provider_unavailable et address_only, avec 0..5 candidats.
Références, contrôles humains, versions et revalidation avant cache/Hermes et après
l'attente conservés. Étendre la projection avec état/raisons serveur pour distinguer
panne, absence et manque de précision. Pas de nouvelles données privées, quota/taille
ou permissions. La projection et le binding sont construits côté serveur, pas par le client.

La réponse peut joindre, uniquement si la proposition revalidée est éligible et le flag
actif, un bloc enrichment_research (SCHEMA_BLOC_RELANCE.json) avec références seulement.
Il est généré côté serveur et jamais extrait du modèle. Le bloc candidats existant n'est
émis que s'il y a des candidats valides ; il reste distinct. Le BO ignore les blocs inconnus.
Ne pas élargir la lecture à matched pour le chat dans CE lot ; matched garde le formulaire
manuel. Le bouton contextuel ne déclenche ni job, ni apply : il ouvre le formulaire.

Préserver la signature resolve() du ContextReader et l'existant ; extension additive
research_block optionnelle dans son retour interne si nécessaire, consommée par Gateway.
E05 ne modifie pas ces classes ; E06 ne modifie pas le moteur de recherche.

## Compatibilité et validation

Contrat v1.2 additif ; les lecteurs BO tolèrent targeted_research absent/false. Tester
ancienne API (404/clé absente), flag off, tout le lot 01, les deux nouveautés lot 02 et
la matrice TVA/chat/research, en conservant les contrats historiques. Aucun endpoint
inventé en faux transport. PHP réutilise vendor en lecture seule avec bootstrap worktree
et preuve Reflection du SUT ; intégrations DB/Redis jetables, HTTP publics/Hermes simulés.
La recette préproduction complète reste pour la fin ; tests locaux et contrôles de
déploiement ne sont pas supprimés. Aucun agent n'active les flags ou n'appelle un vrai lot.
