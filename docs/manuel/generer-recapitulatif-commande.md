# Générer le récapitulatif d'une commande

## Objectif

Télécharger un fichier CSV qui liste les bons d'une commande, avec leur montant
et, lorsqu'ils sont renseignés, les coordonnées des bénéficiaires.

## Prérequis

- La commande existe et vous l'avez retrouvée dans **Commandes**.
- La commande comporte des bons. Ils sont créés avec la commande : il n'est pas
  nécessaire de générer la facture ni les QR Codes au préalable.

## Étapes

1. Dans le menu latéral, ouvrez **Commandes**, puis retrouvez la commande avec
   le champ **Rechercher** et la colonne **N°**.
2. Sur la ligne de la commande, cliquez sur l'icône de la colonne **Gestion**.
3. Choisissez **Générer le récapitulatif**. Aucune fenêtre de saisie ni
   confirmation ne s'affiche.
4. Le message **Téléchargement du fichier récapitulatif...** s'affiche pendant
   la préparation. Le navigateur télécharge ensuite un fichier CSV nommé
   `<nom du client>_<numéro de commande>_summary.csv`.
5. Ouvrez le fichier avec un tableur. Les colonnes sont séparées par des
   points-virgules.

## Lire le fichier

Le fichier contient une ligne par bon de la commande, avec ces colonnes :

| Colonne | Contenu |
|---|---|
| **N° Coupon** | Identifiant du bon, composé par le système. Il ne correspond pas au numéro commercial de la commande. |
| **Montant** | Montant du bon. Ce n'est pas le solde restant : le fichier n'indique pas si le bon a été utilisé. |
| **Email**, **Mobile**, **Prenom**, **Nom** | Coordonnées du bénéficiaire lorsqu'elles sont enregistrées sur le bon, par exemple pour une commande importée avec ses bénéficiaires. Sinon, ces colonnes restent vides. |

Les bons supprimés n'y figurent pas.

## Règles et limites

- Cette action produit uniquement un fichier : elle ne crée ni facture ni bon,
  n'envoie aucun e-mail et ne modifie pas la commande. Vous pouvez la répéter.
- Le récapitulatif ne remplace ni la facture ni le bon de livraison.
- **Générer le CSV** est une autre entrée du même menu ; elle n'est pas décrite
  dans cette fiche.
- Le fichier peut contenir des coordonnées personnelles de bénéficiaires.
  Conservez-le et transmettez-le avec les précautions habituelles.

## Si un message d'erreur s'affiche

Le message affiché est **Erreur lors de la génération du récapitulatif.** Il ne
précise pas la cause. Ce message apparaît notamment si la commande ne comporte
aucun bon.

1. Vérifiez que vous avez choisi la bonne ligne dans **Commandes**.
2. Rechargez la page et réessayez.
3. Si le problème persiste, signalez-le à votre interlocuteur Tribuneo avec le
   numéro de commande, sans communiquer de mot de passe ni de jeton.

## Écran concerné

Menu **Commandes**, écran **Liste des commandes**, colonne **Gestion**, entrée
**Générer le récapitulatif**.

## Avec Néo

Pour obtenir cette procédure, demandez : « Comment générer le récapitulatif
d'une commande ? »

Néo peut consulter les informations d'une commande, mais il ne génère pas ce
fichier et ne le joint pas. Le téléchargement est réalisé depuis le
back-office.
