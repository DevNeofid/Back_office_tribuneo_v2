# Statistiques : Montant total du réseau

## Objectif

Obtenir pour une période trois totaux du réseau : frais de gestion retenus,
total injecté par les commandes et reste des bons expirés. Le parcours commun
est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Montant total du réseau**.
2. Réglez **Date de debut** et **Date de fin**, avec deux dates différentes.
3. Lisez l'unique ligne du tableau. Survolez l'icône d'information de
   **Gain expiré total** pour afficher sa définition.
4. Cliquez sur **Exporter en CSV** : fichier `montant_total_reseau.csv`, une
   ligne d'en-têtes et une ligne de valeurs.

## Colonnes

| Écran | En-tête CSV | Définition | Période appliquée |
|---|---|---|---|
| **Frais de gestion** | `frais_de_gestion` | Somme des montants retenus enregistrés sur les ordres de virement. | Ordres créés à partir de 23:59:59 le jour de début et avant 23:59:59 le jour de fin. |
| **Total injecté** | `montant_total_injecté` | Somme des montants totaux des commandes non supprimées. | Commandes créées avec les mêmes bornes. |
| **Gain expiré total** | `montant_total_expiré` | Somme des montants restants des bons non supprimés, sur des commandes non supprimées, dont l'expiration est déjà passée. | Expiration comprise entre 23:59:59 le jour de début et 23:59:59 le jour de fin, bornes incluses. |

L'infobulle de **Gain expiré total** indique : « Reste des bons dont la date
d'expiration est comprise dans la période choisie. »

À l'écran, les montants sont suivis de €. Dans le CSV, **Total injecté** et
**Gain expiré total** sont écrits avec deux décimales ; **Frais de gestion**
est repris tel que fourni par le serveur.

## Lecture et limites

- Les trois colonnes n'utilisent pas la même date : création de l'ordre de
  virement, création de la commande, expiration du bon. Ne les additionnez
  pas et ne les comparez pas comme s'il s'agissait d'une même population.
- Les bons expirant le jour de début sont inclus dans **Gain expiré total**,
  alors que les commandes et ordres de ce jour sont pratiquement exclus des
  deux autres colonnes.
- **Total injecté** porte sur les commandes créées, sans tenir compte de leur
  paiement. Ce n'est pas un encaissement.
- **Frais de gestion** ne remplace pas les
  [factures de frais de gestion](consulter-telecharger-factures-frais-gestion.md) :
  ce rapport additionne des montants retenus, il ne liste aucune pièce.
- **Gain expiré total** inclut les bons de donation et dépend du montant
  restant au moment de la lecture. Une expiration modifiée après coup change
  le résultat. Ce total n'est pas un produit comptable établi.
- Un tableau réduit à ses en-têtes ou un message commençant par **Error:**
  indique un refus ou un échec de lecture, pas des totaux nuls.

## Avec Néo

Demandez : « Que signifie Gain expiré total ? ». Néo explique les trois
définitions ; il ne calcule pas ces totaux et n'exporte pas le fichier.
