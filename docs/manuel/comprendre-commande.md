# Comprendre les informations d'une commande

## Objectif

Lire correctement une commande dans le back-office : distinguer son numéro
commercial de son identifiant interne, son montant total d'une facture, et son
montant payé de son statut de paiement.

## Où lire une commande

Ouvrez **Commandes** dans le menu latéral : l'écran **Liste des commandes**
présente une ligne par commande. Pour retrouver une commande précise, suivez la
fiche [Rechercher une commande](rechercher-commande.md).

La liste est chargée de la commande la plus récente à la plus ancienne. Elle ne
charge qu'un nombre limité de commandes : une commande ancienne peut ne pas y
apparaître, sans que cela prouve qu'elle n'existe pas.

## Les colonnes de la liste

| Colonne | Ce qu'elle indique |
|---|---|
| **N°** | Numéro commercial de la commande. C'est le numéro à communiquer et à rechercher ; il peut être sélectionné pour être copié. |
| **Offert par** | Texte « Offert par » enregistré sur la commande. Il reprend en général le nom du client, mais il a pu être remplacé à la création par **Personnalisation offert par (optionnel)**. Il ne désigne donc pas toujours le nom de la fiche client. |
| **Occasion** | Occasion de la commande, choisie dans **Pour l'occasion de**. Au survol, l'infobulle affiche les messages personnalisés des lignes. |
| **Qté** | Nombre total de chèques (bons) de la commande. |
| **Payé** | Cumul des paiements enregistrés sur la commande. |
| **Facturé** | Montant total de la commande. Malgré son titre, cette colonne n'indique ni le montant d'une facture ni l'existence d'une facture. |
| **Création** | Date de création de la commande. |
| **Expiration** | Date de validité de la commande. |
| **Gestion** | Menu des actions de gestion : **Paiements**, **Générer les QR Code**, **Générer le CSV**, **Générer le bon de livraison**, **Générer la Facture**, **Générer le récapitulatif**, **Gestion des bons**, **Bénéficiaires (commande importée)**. |
| **Edition** | Menu **Modifier**, **Changer la date de validité** et **Supprimer**. |

Les montants **Payé** et **Facturé** sont verts lorsque le cumul payé est égal
au total de la commande, rouges dans tous les autres cas. La lecture du solde
est détaillée dans [Vérifier le solde d'une commande](verifier-solde-commande.md).

## Numéro commercial et identifiant interne

- Le **numéro commercial** est celui de la colonne **N°**. On le retrouve dans
  le titre **Modifier la commande** suivi du numéro, dans le titre de la
  fenêtre **Gestion des bons** et dans le nom des fichiers générés.
- L'**identifiant interne** est un numéro technique attribué par le système.
  Il n'est pas affiché dans la liste des commandes et ne remplace pas le
  numéro commercial. Ne saisissez pas l'un à la place de l'autre.
- Dans **Gestion des bons**, la colonne **ID** identifie chaque bon. Ce n'est
  pas le numéro commercial de la commande.

## Lignes, chèques et total

Une commande comporte une ou plusieurs lignes. Chaque ligne indique un
**Montant par chèque**, un **Nombre de chèque** et, si besoin, un **Message
personnalisé** ; sans message, le nom de l'occasion est utilisé.

- Chaque chèque de la commande correspond à un bon.
- La colonne **Qté** est la somme des quantités des lignes.
- Le total affiché dans **Facturé** est la somme, pour chaque ligne, du montant
  par chèque multiplié par le nombre de chèques.

Les lignes se lisent dans **Edition → Modifier**. Pour une simple lecture,
quittez ce formulaire avec **Fermer**, sans cliquer sur **Enregistrer**. La
liste des bons, avec leur montant, leur montant restant et leur date
d'expiration, se lit dans **Gestion → Gestion des bons**, que l'on quitte avec
**Fermer**.

## Date de validité de la commande et des bons

La colonne **Expiration** indique la date de validité de la commande. Chaque bon
porte aussi sa propre date, visible dans **Gestion des bons**. Un bon peut avoir
reçu individuellement une autre date que celle de la commande. Le changement de
date pour toute la commande est décrit dans la fiche
[Changer la date de validité d'une commande](changer-validite-commande.md).

## Paiement et facture

- **Payé** est le cumul des paiements enregistrés. Le détail des paiements se
  lit dans **Gestion → Paiements** : voir
  [Consulter les paiements d'une commande](consulter-paiements-commande.md).
- Une commande peut être entièrement payée sans être facturée, et facturée sans
  être payée.
- La liste n'a pas de colonne indiquant qu'une facture existe. Lorsque
  la commande est facturée, le formulaire **Edition → Modifier** affiche le
  bandeau **Cette commande est facturée : seule la date de validité peut encore
  être modifiée** suivi d'une précision sur les commandes importées. Fermez-le
  ensuite avec **Fermer**.
- **Générer la Facture** n'est pas une action de consultation. Pour récupérer
  le PDF d'une facture déjà créée, suivez
  [Retélécharger une facture existante](retelecharger-facture-existante.md).

## Origine de la commande

Une commande peut avoir été saisie à la main, importée par fichier ou passée
sur la boutique en ligne. La liste ne l'indique pas. Lorsque son état a pu être
lu, le formulaire **Modifier** affiche un bandeau pour une commande importée par
fichier ou issue de la boutique en ligne : ses lignes n'y sont pas modifiables.

## Bons attribués

Un bon est **attribué** lorsqu'il est rattaché à un consommateur, en
particulier après avoir été scanné ou utilisé. Un bon attribué :

- n'est jamais retiré lors d'une modification de la commande ;
- ne peut pas voir sa date de validité avancée, seulement prolongée ;
- empêche la suppression de la commande.

Dans **Gestion des bons**, l'infobulle de l'icône de désactivation d'un tel bon
indique **Bon associé à un utilisateur, désactivation impossible**.

## Avec Néo

Demandez : « Comment lire les informations d'une commande dans le
back-office ? » pour obtenir cette explication.

Pour consulter une commande réelle dans le chat, donnez son numéro commercial :
« Que contient la commande [numéro] ? ». Néo lit en lecture seule le client,
« Offert par », les lignes, le total, le montant payé et le reste à payer. Il ne
modifie, ne facture et ne supprime aucune commande.
