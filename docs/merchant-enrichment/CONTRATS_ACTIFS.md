# Contrats actifs — M12 lot 03

Le contrat actif est CONTRAT_V1_2.openapi.json : moteur v1.2 et extension
chat-research consolidés, deux blocs serveur distincts possibles. Le contrat chat
seul est CONTRAT_CHAT_RESEARCH.openapi.json ; le bloc à références uniquement est
SCHEMA_BLOC_RELANCE.json. Règles métier : CONTRAT_LOT_03.md.

Les fichiers v1, v1.1 et chat du lot 02 sont des références historiques conservées
octet pour octet, y compris leurs anciens titres. Les copies research/ et
chat-research/ des missions restent figées ; elles ne remplacent pas l'assemblage.
Copies actives identiques API/BO/Néo, vérifiées par PROVENANCE_M12.json.

Capabilities additives : clé targeted_research absente = false pour le BO.
TVA/chat/research restent indépendants et off par défaut. Authentification humaine,
tenant/rôle/session/Origin, idempotence, versions et confirmation humaine restent
obligatoires ; aucun endpoint agent, appel modèle ou critère saisi n'autorise apply.
