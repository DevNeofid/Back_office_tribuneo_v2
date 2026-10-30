# Générer la facture d'une commande

## Objectif

Établir la première facture d'une commande depuis la liste des commandes et
télécharger son PDF. Pour simplement récupérer le PDF d'une facture déjà créée,
utilisez plutôt la fiche « Retélécharger une facture existante ».

## Prérequis

- La commande existe et vous l'avez retrouvée dans **Commandes**.
- Le client de la commande a une adresse renseignée : dans **Clients**, onglet
  **Adresse** de sa fiche. Si elle manque, ajoutez-la avec **Editer l'adresse**
  avant de facturer. L'adresse est reprise sur la facture et enregistrée avec
  elle lors de sa création.
- Vérifiez les lignes, les montants et l'occasion de la commande : une fois la
  commande facturée, seule sa date de validité reste modifiable.

Il n'est pas nécessaire que la commande soit payée : les paiements déjà
enregistrés figurent sur le document au moment de sa génération.

## Étapes

1. Dans le menu latéral, ouvrez **Commandes**, puis retrouvez la commande avec
   le champ **Rechercher** et la colonne **N°**.
2. Sur la ligne de la commande, cliquez sur l'icône de la colonne **Gestion**.
3. Choisissez **Générer la Facture**.
4. Une fenêtre s'ouvre : **Voulez-vous ajouter des informations
   supplémentaires ?** Le champ, dont l'indication est **Référence commande**,
   est facultatif. Saisissez si besoin la référence ou le texte à faire figurer
   sur la facture, par exemple un numéro de bon de commande du client.
5. Cliquez sur **Générer la facture** pour lancer la création, ou sur
   **Annuler** pour fermer la fenêtre sans rien créer.
6. Le message **Création de la facture...** s'affiche pendant le traitement.
   Le navigateur télécharge ensuite le PDF, nommé à partir du nom du client et
   du numéro de commande : `Facture_<nom du client>_<numéro de commande>.pdf`.
7. Contrôlez le PDF : numéro de facture, client, adresse, référence et
   montants. La facture apparaît ensuite dans **Documents → Factures**.

Aucun message de confirmation n'est affiché en cas de succès : c'est le
téléchargement du PDF qui indique que l'opération a abouti.

## Ce que crée la première génération

- Un numéro de facture, attribué une seule fois pour la commande.
- Le numéro du bon de livraison de la commande, créé en même temps que la
  facture. Il figure sur la facture et permet ensuite de télécharger le bon de
  livraison (voir « Générer le bon de livraison d'une commande »).
- L'enregistrement de la facture avec le montant total de la commande et les
  coordonnées du client à cette date.

Le document reprend notamment le numéro de commande, le numéro du bon de
livraison, la mention « Offert par » au nom du client, l'occasion, la date de
validité des bons, les lignes de coupons et les paiements enregistrés. Le
numéro de TVA intracommunautaire et le SIRET du client y figurent s'ils étaient
renseignés dans sa fiche lors de la première génération.

## Règles et limites

- Une commande ne reçoit qu'une seule facture. Si une facture existe déjà,
  **Générer la Facture** ne crée pas de nouveau numéro : il prépare à nouveau
  le PDF de cette facture.
- Dans ce cas, le champ **Référence commande** est prérempli avec la référence
  déjà enregistrée. Cliquer sur **Générer la facture** remplace cette référence
  par le contenu du champ, même vide. Pour récupérer le PDF sans rien modifier,
  passez par **Documents → Factures → Télécharger**.
- Après facturation, le formulaire **Modifier** de la commande est en lecture
  seule, à l'exception de la date de validité. Il indique : **Cette commande est
  facturée : seule la date de validité peut encore être modifiée (et, pour une
  commande importée, le contact des bénéficiaires non attribués).**
- La colonne **Facturé** de la liste affiche le montant total de la commande.
  Elle ne prouve pas qu'une facture a été générée ; vérifiez dans
  **Documents → Factures**.
- Fermer la fenêtre de saisie ou cliquer sur **Annuler** ne crée aucune facture.

## Si un message d'erreur s'affiche

Le message affiché est **Erreur : Pensez à vérifier que votre client a une
adresse de renseignée ?** Il ne précise pas la cause exacte : une adresse
manquante est une cause possible, mais ce message peut aussi apparaître pour un
autre problème de lecture, de traitement ou de téléchargement.

- **Avant l'ouverture de la fenêtre de saisie** (message sur fond rouge) :
  aucune facture n'a été créée à ce stade, et l'adresse n'a pas encore été
  utilisée. Rechargez la page, vérifiez l'adresse du client par précaution,
  puis réessayez.
- **Après avoir cliqué sur Générer la facture** : la facture peut avoir été
  créée même si le PDF n'a pas été téléchargé. Avant de recommencer,
  ouvrez **Documents → Factures** et recherchez une facture au nom du client
  avec la date du jour.
  - Si elle existe, téléchargez-la depuis **Documents** plutôt que de relancer
    la génération.
  - Si elle n'existe pas, vérifiez l'adresse du client, rechargez la page,
    puis réessayez une seule fois.

Relancer la génération ne crée pas une seconde facture pour la même commande,
mais remplacerait la référence enregistrée par le contenu du champ. Si le
problème persiste, signalez-le à votre interlocuteur Tribuneo avec le numéro de
commande, sans communiquer de mot de passe ni de jeton.

## Écran concerné

Menu **Commandes**, écran **Liste des commandes**, colonne **Gestion**, entrée
**Générer la Facture**, puis fenêtre **Voulez-vous ajouter des informations
supplémentaires ?**

## Avec Néo

Pour obtenir cette procédure, demandez : « Comment générer la facture d'une
commande dans le back-office ? »

Néo peut vérifier si une facture existe déjà pour une commande et en donner les
informations disponibles : numéro, montant, date et référence. Il ne crée pas
de facture et ne joint pas de PDF. La génération est réalisée par vous, depuis
le back-office.
