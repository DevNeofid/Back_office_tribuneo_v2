# Générer le bon de livraison d'une commande

## Objectif

Télécharger le bon de livraison PDF d'une commande déjà facturée, depuis la
liste des commandes.

## Prérequis

- La commande a déjà une facture. Le numéro du bon de livraison est créé en
  même temps que la facture, lors de la première génération de celle-ci (voir
  « Générer la facture d'une commande »).
- Vous avez retrouvé la commande dans **Commandes**.

Sans facture, le bon de livraison ne peut pas être produit : le back-office
affiche un message d'erreur.

## Étapes

1. Dans le menu latéral, ouvrez **Commandes**, puis retrouvez la commande avec
   le champ **Rechercher** et la colonne **N°**.
2. Sur la ligne de la commande, cliquez sur l'icône de la colonne **Gestion**.
3. Choisissez **Générer le bon de livraison**. Aucune fenêtre de saisie ni
   confirmation ne s'affiche.
4. Le message **Génération du bon de livraison...** s'affiche pendant la
   préparation. Le navigateur télécharge ensuite le PDF, nommé
   `BL_<nom du client>_<numéro de commande>.pdf`.
5. Contrôlez le numéro du bon de livraison, le client et la commande dans le
   document.

## Contenu du bon de livraison

Le document reprend notamment le numéro du bon de livraison, le numéro de
commande, le client, la mention « Offert par », l'occasion, la date de validité
des bons et les lignes de coupons.

Les coordonnées du client et la date de validité sont celles enregistrées lors
de la création de la facture. Si l'adresse du client ou la date de validité de
la commande a été modifiée depuis, le bon de livraison peut afficher les
anciennes valeurs.

## Règles et limites

- Cette action ne crée ni facture ni nouveau numéro. Vous pouvez la répéter :
  le même numéro de bon de livraison est repris à chaque téléchargement.
- Le bon de livraison n'apparaît pas dans **Documents**. Il se télécharge
  uniquement depuis **Commandes → Gestion → Générer le bon de livraison**.
- Pour une commande non facturée, ne générez pas la facture uniquement pour
  obtenir le bon de livraison sans avoir vérifié la commande : la facturation
  crée un numéro de facture définitif et limite ensuite les modifications de la
  commande.

## Si un message d'erreur s'affiche

Le message affiché est **Erreur lors de la génération du PDF.** Il ne précise
pas la cause.

1. Vérifiez que la commande a bien une facture : ouvrez **Documents →
   Factures** et recherchez la facture au nom du client, ou demandez à Néo si
   une facture existe pour cette commande.
2. Si aucune facture n'existe, c'est la cause attendue : le bon de livraison
   sera disponible après la facturation de la commande.
3. Si la facture existe, rechargez la page et réessayez.
4. Si le problème persiste, signalez-le à votre interlocuteur Tribuneo avec le
   numéro de commande, sans communiquer de mot de passe ni de jeton.

## Écran concerné

Menu **Commandes**, écran **Liste des commandes**, colonne **Gestion**, entrée
**Générer le bon de livraison**.

## Avec Néo

Pour obtenir cette procédure, demandez : « Comment générer le bon de livraison
d'une commande ? »

Néo peut vérifier si une facture existe pour la commande, ce qui conditionne la
disponibilité du bon de livraison. Il ne fournit pas le numéro du bon de
livraison, ne génère pas le document et ne joint pas de PDF.
