# Statistiques : Partenaires jamais connectés

## Objectif

Lister les partenaires du réseau dont l'accès de première connexion n'a pas
été utilisé. Le parcours commun est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Partenaires jamais connectés**.
2. Lisez le tableau, dix lignes par page, trié par nom.
3. Cliquez sur **Exporter en CSV** : fichier `partenaires_jamais_connectes.csv`.

Ce rapport n'a ni période ni filtre.

## Colonnes

| Écran | En-tête CSV | Définition |
|---|---|---|
| **Nom** | `nom` | Nom du partenaire. |
| **Email** | `email` | E-mail enregistré sur la fiche partenaire. |
| **Téléphone** | `tel` | Téléphone enregistré sur la fiche partenaire. |
| **Avec QR Code** | `avec_qr_code_première_connexion` | **Oui** : un accès de première connexion est enregistré mais n'a pas été utilisé. **Non** : aucun accès de première connexion n'est enregistré. |

## Définition retenue

Une fiche partenaire non supprimée, de type partenaire dans le réseau,
apparaît si aucun accès de première connexion n'est enregistré pour elle ou
si cet accès n'a pas été utilisé. Le rapport ne lit pas d'historique de
connexion : « jamais connecté » signifie ici « première connexion non
réalisée par cet accès ».

## Lecture et limites

- **Oui** ne prouve pas que le QR code ou le lien a été transmis au
  commerçant. **Non** indique seulement qu'aucun accès n'est enregistré ;
  ce rapport ne dit pas pourquoi.
- Un même partenaire peut apparaître plusieurs fois s'il possède plusieurs
  accès de première connexion enregistrés ; le total annoncé compte les
  partenaires distincts.
- Pour transmettre l'accès, suivez
  [Donner accès à l'application à un partenaire](donner-acces-application-partenaire.md).
  Ce rapport ne génère aucun QR code et n'envoie rien.
- Ces partenaires sont exclus du rapport
  [Partenaires sans transactions](statistiques-partenaires-sans-transactions.md).

## Avec Néo

Demandez : « Que veut dire Avec QR Code dans Partenaires jamais connectés ? ».
Néo explique la colonne et renvoie vers l'accès de première connexion ; il ne
génère aucun accès.
