# Statistiques : Montant total des bons par clients

## Objectif

Connaître, pour chaque client acheteur, le montant restant sur les bons de
ses commandes encore valides, à la date de lecture. Le parcours commun est
décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

Le « client » est l'entité qui a passé la commande, pas le bénéficiaire qui
utilise les bons ni le commerçant qui les encaisse.

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Montant total des bons par clients**.
2. Lisez le tableau, dix lignes par page, trié du montant le plus élevé au
   plus faible puis par nom.
3. Cliquez sur **Exporter en CSV** : fichier `montant_total_bons_clients.csv`.

Ce rapport n'a ni période ni filtre : il reflète l'état au moment de la lecture.

## Colonnes

| Écran | En-tête CSV | Définition |
|---|---|---|
| **Nom** | `nom` | Nom du client de la commande. |
| **Montant** | `montant_total_a_date` | Somme des montants restants supérieurs à zéro des bons de ses commandes non supprimées dont la date d'expiration de commande n'est pas encore passée, arrondie à deux décimales, sans symbole €. |
| **Date d'expiration** | `date_expiration` | Date d'expiration de commande reprise d'une des commandes retenues pour ce client. Affichée au format jj/mm/aaaa, écrite au format brut de la base dans le CSV. |

## Lecture et limites

- La validité retenue est la date d'expiration de la **commande**, pas celle
  de chaque bon. Un bon peut avoir sa propre date : voir
  [Changer l'expiration d'un bon](changer-expiration-bon.md).
- Lorsqu'un client a plusieurs commandes retenues, **Date d'expiration** ne
  correspond qu'à l'une d'elles, sans garantie qu'il s'agisse de la plus
  proche ou de la plus lointaine.
- Les bons de donation ne sont pas exclus, et la requête ne filtre pas les
  bons désactivés.
- Ce montant n'est ni une dette du réseau, ni un solde comptable, ni une
  somme à rembourser. Un client absent peut avoir des bons dont la commande
  est expirée.
- Pour les bons d'une commande précise, utilisez
  [Consulter les bons d'une commande](consulter-bons-commande.md).

## Avec Néo

Demandez : « Le montant total des bons par clients tient-il compte de
l'expiration de chaque bon ? ». Néo explique la définition ; il ne lit pas ce
rapport.
