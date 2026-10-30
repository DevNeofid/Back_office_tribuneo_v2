# Consulter les paiements d'une commande

## Objectif

Voir les paiements enregistrés pour une commande et les montants affichés dans
sa fenêtre **Paiements**.

## Prérequis

Avoir identifié la commande à consulter, par exemple avec son numéro commercial.
Si nécessaire, utilisez la fiche [Rechercher une commande](rechercher-commande.md).

## Étapes

1. Ouvrez **Commandes** et retrouvez la commande concernée.
2. Sur sa ligne, ouvrez le menu de la colonne **Gestion**, puis choisissez
   **Paiements**.
3. Dans la fenêtre **Paiements**, consultez les lignes du tableau : **Date**,
   **Méthode** et **Montant**. La colonne **Compte** apparaît lorsque plusieurs
   comptes bancaires sont chargés pour le réseau.
4. En bas de la fenêtre, lisez **Montant payé:** : les deux valeurs correspondent
   au cumul affiché des paiements et au montant total de la commande.
5. Cliquez sur **Fermer** pour revenir à la liste des commandes.

## Lire les informations affichées

- **Date** : date du paiement enregistré.
- **Méthode** : moyen de paiement, par exemple **Espèces**, **Chèque**,
  **Virement**, **Paiement en ligne**, **Carte bancaire** ou
  **Mandat administratif**.
- **Montant** : montant du paiement sur cette ligne, affiché avec deux décimales.
- **Compte**, lorsque la colonne est visible : libellé du compte encaisseur.
- **Montant payé:** : cumul des paiements affichés, suivi du total de la commande.
  Il s'agit d'un récapitulatif, pas du montant d'un paiement supplémentaire.

## Règles et limites

- L'ouverture de la fenêtre déclenche le chargement des paiements. Son contenu
  peut se mettre à jour juste après l'ouverture : une liste initialement vide
  ne permet pas de conclure immédiatement à une absence de paiements.
- Les informations de comptes bancaires sont chargées séparément. La colonne
  **Compte** reste masquée lorsqu'un seul compte est disponible ou lorsque la
  liste des comptes n'a pas pu être chargée. Son absence ne signifie pas qu'un
  paiement est dépourvu de compte encaisseur.
- Pour certains anciens paiements, le libellé du compte par défaut peut être
  affiché. Si un code de compte ne correspond plus à la liste des comptes
  disponibles, ce code peut être affiché à la place du libellé.
- Une erreur de chargement des paiements peut se traduire par une liste vide.
  Un tableau vide ou un cumul à zéro ne suffit donc pas à lui seul à établir
  qu'une commande connue n'a reçu aucun paiement.
- Cette fiche couvre uniquement la consultation. La fenêtre contient aussi des
  commandes d'ajout et de suppression ; elles ne sont pas nécessaires pour lire
  les paiements. Pour quitter après consultation, utilisez **Fermer**.
- Consulter les paiements ne génère pas de facture et n'en prouve pas l'existence.

## Si des paiements attendus n'apparaissent pas

1. Vérifiez que vous avez ouvert la bonne commande.
2. Attendez la fin du chargement. Si les informations attendues restent absentes,
   cliquez sur **Fermer**, puis rouvrez **Gestion → Paiements** pour relancer la
   lecture.
3. Si le problème persiste, rechargez la page et recommencez. Signalez ensuite
   l'écart à votre interlocuteur Tribuneo avec le numéro commercial concerné,
   sans communiquer de mot de passe ni de jeton.

## Écran concerné

Menu **Commandes**, écran **Liste des commandes**, colonne **Gestion**, entrée
**Paiements**, fenêtre **Paiements**.

## Avec Néo

Pour obtenir cette procédure, demandez : « Comment consulter les paiements d'une
commande dans le back-office ? »

Pour demander une lecture des données dans le chat, formulez plutôt : « Quels
paiements sont enregistrés pour cette commande ? » après avoir identifié la
commande avec Néo. Cette lecture utilise les données réelles de la commande ; la
présente fiche décrit uniquement l'accès à la fenêtre du back-office.
