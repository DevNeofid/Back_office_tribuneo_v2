# Statistiques : Montant total des partenaires

## Objectif

Obtenir, pour une période, le montant des paiements reçus par chaque fonds
destinataire, avec le nom de l'entité qui lui est rattachée. Le parcours
commun est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Montant total des partenaires**.
2. Réglez **Date de debut** et **Date de fin**. Choisissez deux dates
   différentes : avec la même date, le tableau reste vide.
3. Lisez le tableau, dix lignes par page, trié du montant le plus élevé au
   plus faible.
4. Cliquez sur **Exporter en CSV** : fichier `montant_total_partenaires.csv`.

## Période appliquée

Sont retenues les transactions créées à partir de 23:59:59 le jour de début
et avant 23:59:59 le jour de fin. Le jour de début n'est donc couvert que
pour sa dernière seconde, et la dernière seconde du jour de fin est exclue.
Exemple : pour tout le mois d'octobre, choisissez 30/09 en début et 31/10 en
fin. Fuseau : voir la fiche commune.

## Colonnes

| Écran | En-tête CSV | Définition |
|---|---|---|
| **Nom** | `nom` | Nom de l'entité rattachée au fonds qui a reçu les transactions. |
| **Montant total** | `montant_total` | Somme des paiements reçus par ce fonds, diminuée des annulations dont ce même fonds est destinataire, deux décimales, sans symbole €. |

## Lecture et limites

- Une annulation est enregistrée avec le fonds du payeur d'origine comme
  destinataire. Elle n'est donc pas déduite de la ligne du commerçant : ce
  montant correspond, pour un commerçant, aux paiements reçus sans déduction
  des annulations.
- Ce n'est ni un solde du partenaire, ni une somme remboursée, ni un montant
  de virement. Les injections, dons entre consommateurs et remboursements ne
  sont pas comptés.
- La requête ne filtre pas le type d'entité. Les lignes sont regroupées par
  fonds : un même nom peut apparaître sur plusieurs lignes, et le nombre total
  annoncé par la pagination peut différer du nombre de lignes affichées.
- Un partenaire absent n'a pas nécessairement aucune activité : vérifiez la
  période appliquée ci-dessus.

## Avec Néo

Demandez : « Le montant total des partenaires déduit-il les annulations ? ».
Néo explique la définition et les dates à choisir ; il ne lit pas ce rapport.
