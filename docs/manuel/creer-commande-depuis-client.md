# Créer une commande depuis la fiche d'un client

## Objectif

Ouvrir le formulaire de commande directement depuis un client existant, afin
que la commande lui soit rattachée sans avoir à le choisir dans une liste.

## Prérequis

Le client doit déjà exister dans **Clients**. Pour le créer, voir
[Ajouter un client particulier](ajouter-client-particulier.md) ou
[Ajouter un client professionnel](ajouter-client-professionnel.md).

## Étapes

1. Dans le menu latéral, ouvrez **Clients**. L'écran porte le titre
   **Liste des clients**.
2. Retrouvez le client : saisissez son nom dans le champ **Rechercher...** ou
   cliquez sur la lettre correspondante. Chaque client est présenté dans un
   cadre dont l'en-tête affiche son nom. Voir aussi
   [Rechercher et filtrer un client](rechercher-client.md).
3. Dans l'en-tête du cadre de ce client, à droite, cliquez sur la **première
   icône**, en forme de liste. Elle se trouve avant l'icône du menu d'édition
   du client. Cette icône n'a ni libellé ni infobulle.
4. Le formulaire **Ajouter une commande** s'ouvre. À l'emplacement du choix
   **Offert par**, vérifiez que le nom affiché est bien celui du client ; ce
   champ n'est pas modifiable. S'il ne s'agit pas du bon client, quittez le
   formulaire sans enregistrer (voir plus bas).
5. Conservez **Saisie manuelle**, puis remplissez la commande comme indiqué
   dans [Créer une commande en saisie manuelle](creer-commande-manuelle.md) :
   **Date d'expiration**, lignes **Montant par chèque** / **Nombre de chèque**,
   **Message personnalisé** si besoin, **Différents fonds ?** pour plusieurs
   lignes, **Pour l'occasion de**, et éventuellement **Personnalisation offert
   par (optionnel)**. Vous n'avez pas à sélectionner le client.
6. Relisez le client, les lignes, l'occasion et la date, puis cliquez sur
   **Enregistrer**. Le message **Ajout de la commande réussi** confirme
   l'enregistrement ; le formulaire se ferme et la liste des clients se
   recharge.
7. La liste des clients n'affiche pas les commandes. Pour contrôler la
   nouvelle commande, ouvrez **Commandes** : la liste commence par les
   commandes les plus récentes. Vérifiez **Offert par**, **Occasion**, **Qté**
   et le total affiché dans **Facturé**.

## Quitter sans enregistrer

Ce formulaire ne comporte ni bouton **Fermer** ni bouton **Annuler**. Pour le
quitter sans créer de commande, cliquez en dehors de la fenêtre, sans cliquer
sur **Enregistrer**. Aucune commande n'est envoyée tant que **Enregistrer** n'a
pas été cliqué. Les informations saisies sont alors perdues.

## Différences avec la création depuis Commandes

- Le client est fixé par la fiche d'où le formulaire a été ouvert : le message
  **Veuillez sélectionner une entité ("Offert par")** ne s'applique pas.
- Par défaut, le texte « Offert par » de la commande est le nom du client.
  **Personnalisation offert par (optionnel)** remplace ce texte sur les chèques
  sans changer le client rattaché. Les caractères `/` et `\` y sont remplacés
  par un tiret.
- Le même formulaire propose **Importer un fichier**. Pour ce mode, suivez
  [Créer une commande par import CSV/XLSX](creer-commande-import-fichier.md) ;
  le client y est également fixé.

## Messages et difficultés

| Message ou situation | Action |
|---|---|
| « Le montant des fonds non valide » | Renseignez un montant strictement positif, avec un point pour les centimes. |
| « Le nombre de fond non valide » | Renseignez une quantité entière supérieure ou égale à un. |
| « Date de commande non valide » | Vérifiez le format **JJ/MM/AAAA** de la Date d'expiration ou utilisez **Choisir une date**. |
| « Veuillez sélectionner l'occasion (URSSAF) » | Choisissez une valeur dans **Pour l'occasion de**. |
| « L'enregistrement précédent est encore en cours. Patientez quelques secondes. » | Le formulaire se ferme après quelques secondes : vérifiez la liste des commandes avant toute nouvelle tentative. |
| « Erreur lors de l’ajout de la commande » ou autre erreur | Lisez le message, vérifiez les champs puis la liste des commandes avant de recommencer. |
| L'icône en forme de liste ne réagit pas | Vérifiez que vous cliquez dans l'en-tête du cadre du client, sur la première icône à droite du nom. |

Pendant l'enregistrement, un indicateur d'attente remplace le bouton. Après un
message d'erreur ou une fermeture inattendue, contrôlez d'abord la liste des
commandes : ne refaites pas la commande si elle y figure déjà.

## Avec Néo

Demandez : « Comment créer une commande depuis la fiche d'un client ? » Néo
explique la procédure ; la saisie et l'enregistrement sont effectués par
l'utilisateur dans l'interface. Néo ne crée aucune commande. Il peut aider à
retrouver un client existant en lecture seule.
