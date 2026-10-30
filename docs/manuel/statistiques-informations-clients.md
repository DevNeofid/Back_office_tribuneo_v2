# Statistiques : Toutes les infos clients

## Objectif

Extraire en un tableau les informations administratives et comptables des
clients du réseau, c'est-à-dire des entités qui passent les commandes. Le
parcours commun est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Toutes les infos clients**.
2. Faites défiler horizontalement : le tableau compte douze colonnes. Il
   affiche dix lignes par page, trié par nom.
3. Cliquez sur **Exporter en CSV** : fichier `toutes_les_infos_clients.csv`.

Ce rapport n'a ni période ni filtre.

## Colonnes

| Écran | En-tête CSV | Contenu |
|---|---|---|
| **Code** | `code` | Code de la fiche. |
| **Nom** | `nom` | Nom du client. |
| **Email** | `email` | E-mail de la fiche. |
| **Siret** | `siret` | SIRET enregistré. |
| **Téléphone** | `tel` | Téléphone de la fiche. |
| **Adresse** | `rue` | Rue de l'adresse enregistrée. |
| **Code postal** | `code_postal` | Code postal. |
| **Ville** | `ville` | Ville. |
| **Pays** | `pays` | Pays. |
| **N° TVA intracommunautaire** | `num_intracom` | Numéro de TVA enregistré avec les coordonnées bancaires. |
| **Code NAF** | `code_naf` | Code NAF enregistré avec les coordonnées bancaires. |
| **N° comptable** | `numero_compta` | Numéro comptable du client dans le réseau. |

L'IBAN et le BIC des clients ne font pas partie de ce rapport.

## Qui figure dans la liste

Un client apparaît si son rattachement au réseau en tant que client est actif
et s'il possède à la fois une adresse, un enregistrement de coordonnées
bancaires, des informations comptables et un code. Une fiche à qui l'un de
ces éléments manque n'apparaît pas, même si l'IBAN n'est pas affiché. Le
nombre total annoncé par la pagination ne tient pas compte de ces
conditions : les dernières pages peuvent être vides ou incomplètes. Une fiche
ayant plusieurs adresses ou coordonnées bancaires peut apparaître plusieurs
fois.

## Lecture et limites

- Ce rapport ne liste pas les bénéficiaires des bons ni les partenaires. Pour
  les bons d'une personne, utilisez
  [Statut des QR codes par client](statistiques-statut-qr-codes-client.md).
- Un client absent n'est pas forcément inconnu : vérifiez-le avec
  [Rechercher un client](rechercher-client.md), puis complétez si nécessaire
  l'[adresse](renseigner-adresse-client.md) ou les
  [coordonnées bancaires](renseigner-coordonnees-bancaires-client.md).
- Le fichier contient des coordonnées : traitez-le comme une donnée
  personnelle ou d'entreprise confidentielle.

## Avec Néo

Demandez : « Pourquoi un client manque-t-il dans Toutes les infos clients ? ».
Néo explique les conditions d'apparition ; il ne lit pas ce rapport.
