# Statistiques : Somme des coupons expirés par client

## Objectif

Compter, pour chaque client acheteur, les bons expirés qui gardent un montant
restant, et en faire la somme, pour les commandes créées sur une période. Le
parcours commun est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

Le « client » est l'entité qui a passé la commande, pas le bénéficiaire du
bon ni le commerçant.

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Somme des coupons expirés par client**.
2. Réglez **Date de debut** et **Date de fin**, avec deux dates différentes.
3. Lisez le tableau, dix lignes par page, trié de la somme la plus élevée à la
   plus faible puis par nom.
4. Cliquez sur **Exporter en CSV** : fichier `somme_coupons_expires.csv`.

## Période appliquée

La période porte sur la **date de création de la commande**, pas sur la date
d'expiration des bons. Sont retenues les commandes créées à partir de 00:00:00
le jour de début et avant 00:00:00 le jour de fin : le jour de fin est exclu.
Exemple : pour les commandes d'octobre, choisissez 01/10 en début et 01/11 en
fin. L'expiration est comparée à l'instant de la lecture.

## Colonnes

| Écran | En-tête CSV | Définition |
|---|---|---|
| **Nom** | `nom` | Nom du client de la commande. |
| **Nombre de coupons** | `nombre_bon_expiré` | Nombre de bons retenus pour ce client. |
| **Somme non dépensée** | `montant_total_non_remboursé` | Somme de leurs montants restants, arrondie à deux décimales, sans symbole €. |

Sont retenus les bons non supprimés, hors donation, de commandes non
supprimées, dont la date d'expiration est passée et dont le montant restant
est supérieur à zéro.

## Lecture et limites

- L'en-tête CSV parle de montant « non remboursé » : il s'agit seulement du
  montant restant des bons. Ce rapport ne lit aucune demande de remboursement.
- Les bons de donation sont exclus ici, alors qu'ils sont inclus dans
  **Gain expiré total** du
  [Montant total du réseau](statistiques-montant-total-reseau.md), qui filtre
  en outre sur la date d'expiration. Les deux chiffres ne sont pas comparables.
- Le résultat dépend du jour de lecture : une même période peut donner plus
  de lignes plus tard, à mesure que des bons expirent, et une expiration
  modifiée change le résultat.
- Ce total n'est ni une perte, ni un gain comptable établi.

## Avec Néo

Demandez : « La période des coupons expirés porte-t-elle sur l'expiration ? ».
Néo explique la définition et les dates à choisir ; il ne lit pas ce rapport.
