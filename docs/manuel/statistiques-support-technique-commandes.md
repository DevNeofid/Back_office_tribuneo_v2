# Statistiques : Support technique - commandes

## Objectif

Lister, pour une période de création des commandes, les commandes dont des
bons sont rattachés au compte « support technique » du réseau, avec leur
nombre et leur montant restant. Le parcours commun est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

Le compte « support technique » est un compte technique unique, fixé dans le
code du serveur. Ce n'est ni le client de la commande, ni un bénéficiaire,
ni un commerçant.

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Support technique - commandes**.
2. Réglez **Date de debut** et **Date de fin**, avec deux dates différentes.
3. Lisez le tableau, dix lignes par page. L'ordre des lignes n'est pas imposé.
4. Cliquez sur **Exporter en CSV** : fichier `support_technique_commandes.csv`.

## Période appliquée

Sont retenues les commandes non supprimées créées entre 23:59:59 le jour de
début et 23:59:59 le jour de fin, bornes incluses. Le jour de début n'est
donc couvert que pour sa dernière seconde. Exemple : pour les commandes
d'octobre, choisissez 30/09 en début et 31/10 en fin.

## Colonnes

| Écran | En-tête CSV | Définition |
|---|---|---|
| **N° de commande** | `num_commande` | Numéro de la commande. |
| **Nom** | `entité_emettrice` | Client de la commande. |
| **Montant total** | `montant_total_par_commande` | Somme des **montants restants** des bons de cette commande rattachés au compte support technique. |
| **Nombre de QR codes** | `nombre_qrcode` | Nombre de ces bons. |
| **Date de création** | absent du CSV | Date et heure de création de la commande, au format brut de la base. |

## Lecture et limites

- **Montant total** n'est pas le montant de la commande ni celui des bons à
  leur émission : c'est le reste actuel des seuls bons rattachés au compte
  support technique.
- La requête ne filtre pas les bons désactivés.
- Ces bons n'apparaissent pas dans
  [Consulter les bons d'une commande](consulter-bons-commande.md), qui exclut
  ce compte. Un écart de nombre de bons entre les deux écrans ne constitue
  donc pas à lui seul une anomalie.
- Ce rapport ne génère pas de QR codes : pour cela, voir
  [Générer et télécharger les QR codes d'une commande](generer-qr-codes-commande.md).
- La présence d'une commande dans ce rapport ne dit pas pourquoi ses bons
  sont rattachés à ce compte. Faites vérifier avant toute action sur les bons.

## Avec Néo

Demandez : « Que signifie le rapport Support technique - commandes ? ». Néo
explique les colonnes ; il ne lit pas ce rapport et n'agit pas sur les bons.
