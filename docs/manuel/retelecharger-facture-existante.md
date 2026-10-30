# Retélécharger une facture existante

## Objectif

Récupérer le PDF d'une facture de commande déjà présente dans **Documents**.
Cette fiche ne décrit pas la première facturation d'une commande.

## Prérequis

La facture doit déjà exister et apparaître dans la liste **Factures**. Disposez
de son numéro ou des informations permettant de reconnaître sa ligne : nom,
montant et date.

## Étapes

1. Dans le menu latéral, ouvrez **Documents**.
2. Sélectionnez **Factures** si cet onglet n'est pas déjà actif.
3. Retrouvez la facture avec **Numéro de facture**, **Nom**,
   **Montant total (EUR)** et **Date de creation**. Parcourez les pages du tableau
   si nécessaire ; la liste affiche initialement 10 lignes par page.
4. Sur la ligne de la facture, cliquez sur l'icône de téléchargement dans la
   colonne **Actions**. Son infobulle est **Télécharger**.
5. Attendez la préparation du document. Le navigateur prend en charge le
   téléchargement du fichier PDF.

## Lire les informations affichées

- **Numéro de facture** identifie la facture ; ce n'est pas le numéro commercial
  de la commande.
- **Nom**, **Montant total (EUR)** et **Date de creation** permettent de vérifier
  que la bonne ligne a été choisie.
- Le bouton **Frais de gestion** affiche une autre liste. Pour une facture de
  commande, restez dans **Factures**.

## Règles et limites

- Cette vue ne propose pas de champ de recherche ni de filtre par numéro de
  commande. Utilisez les informations visibles et la pagination pour retrouver
  la facture.
- Le parcours **Documents → Factures → Télécharger** part d'une facture existante.
  Tant qu'elle existe toujours, son numéro est réutilisé pour préparer le PDF.
  Le document téléchargé ne constitue pas une nouvelle numérotation.
- Le message **Génération de la facture...** peut apparaître pendant ce
  téléchargement. Dans ce parcours, il accompagne la préparation du PDF et ne
  prouve pas à lui seul la création d'une nouvelle facture.
- Le nom du fichier peut venir du serveur ou être construit à partir des
  informations de la commande. Ne l'utilisez pas comme seul identifiant :
  contrôlez le numéro de facture dans le document.
- Si la facture n'apparaît pas à l'écran, cela ne prouve pas qu'elle n'a pas été
  créée ou enregistrée : elle peut se trouver sur une autre page, vous pouvez
  être sur le mauvais onglet, ou un problème de chargement peut masquer la liste.
  Vérifiez **Factures**, la pagination et le chargement pour la retrouver.
  Ne lancez pas une nouvelle facturation uniquement pour contourner une erreur
  de téléchargement.
- Le menu **Commandes → Gestion → Générer la Facture** correspond à une autre
  opération ; il n'est pas nécessaire pour retélécharger la facture sélectionnée
  dans **Documents**.

## Si le téléchargement échoue

Le message affiché peut être **Erreur lors de la génération du fichier.**
Il ne précise pas la cause du problème.

1. Vérifiez que vous êtes dans **Documents → Factures** et sur la bonne ligne.
2. Rechargez la page et vérifiez que la facture apparaît toujours, puis réessayez
   son bouton **Télécharger**.
3. Si le problème persiste, signalez-le à votre interlocuteur Tribuneo avec le
   numéro de facture concerné, sans communiquer de mot de passe ni de jeton.

Une liste vide peut également résulter d'une erreur de chargement. Elle ne
prouve pas à elle seule qu'aucune facture n'existe pour le réseau.

## Écran concerné

Menu **Documents**, onglet **Factures**, colonne **Actions**, icône
**Télécharger**.

## Avec Néo

Pour obtenir cette procédure, demandez : « Comment retélécharger une facture
existante dans le back-office ? »

Pour consulter les informations réelles de la facture d'une commande dans le
chat, demandez par exemple : « Existe-t-il une facture pour cette commande ? »
après avoir identifié la commande avec Néo. Cette lecture peut fournir les
métadonnées disponibles ; elle ne signifie pas que Néo a téléchargé ou joint
le PDF. Le téléchargement décrit ici est réalisé depuis le back-office.
