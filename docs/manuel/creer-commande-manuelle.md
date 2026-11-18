# Créer une commande en saisie manuelle

## Objectif

Enregistrer une commande pour un client existant, en renseignant les montants,
les quantités de chèques, l'occasion et la date d'expiration dans le formulaire.
Cette fiche concerne uniquement **Saisie manuelle**.

## Étapes

1. Ouvrez **Commandes**, puis cliquez sur le bouton orange
   **Ajouter une commande**, en haut à droite. Le panneau **Ajouter une
   commande** (rubrique **NOUVELLE COMMANDE**) s'ouvre à droite. Dans sa
   section **Bons cadeaux**, conservez **Saisie manuelle**.
2. Vérifiez la **Date d'expiration** préremplie. Modifiez-la au format
   **JJ/MM/AAAA** ou cliquez sur l'icône calendrier **Choisir une date**.
3. Renseignez **Montant par chèque** et **Nombre de chèque**. Le montant doit
   être supérieur à zéro ; la quantité est un entier d'au moins un. Pour les
   centimes, utilisez un point avec au maximum deux décimales.
4. Si nécessaire, remplissez **Message personnalisé** pour cette ligne. Pour
   plusieurs lignes, cliquez sur **Ajouter un autre montant**, puis renseignez
   le montant et la quantité de la nouvelle ligne.
5. Dans **Offert par**, sélectionnez le client. La recherche de cette liste
   porte sur son nom, via **Rechercher une entité...**. Sélectionnez aussi
   **Pour l'occasion de** : l'occasion est obligatoire.
6. Si nécessaire, complétez **Personnalisation « offert par » (optionnel)**
   (anciennement **Personnalisation offert par (optionnel)**) pour changer le
   texte « Offert par » sur les chèques.
7. Relisez les lignes, le client, l'occasion, la date et le total affiché en
   pied de panneau (**… bon(s) · total de la commande**), puis cliquez sur
   **Enregistrer** et attendez le résultat. Le message **Ajout de la commande
   réussi** confirme l'enregistrement ; le panneau se ferme et la liste se
   recharge. Retrouvez la commande dans la liste pour la contrôler.
   **Annuler**, le bouton ✕ **Fermer** ou un clic en dehors du panneau le
   ferment sans enregistrer.

## Personnalisations et plusieurs lignes

- Le **Message personnalisé** remplace le texte de l'occasion sur les chèques
  de la ligne. S'il est vide, le nom de l'occasion sélectionnée est utilisé.
  Il ne dispense pas de sélectionner une occasion.
- **Personnalisation « offert par »** modifie le texte imprimé ; elle
  ne change pas le client auquel la commande est rattachée.
- Quand plusieurs lignes sont présentes, l'icône corbeille **Retirer la ligne**
  retire la ligne concernée. Passer à **Importer un fichier** efface les lignes
  saisies : vérifiez les données avant de changer de mode.
- La section **Où les chèques sont acceptés** est réglée par défaut sur
  **Chez tous les commerçants du réseau**. L'option
  **Seulement chez certains commerçants** réserve les chèques à une liste de
  commerçants ; ce réglage n'est pas décrit dans cette fiche.
- Si le formulaire a été ouvert depuis une fiche client, le client est déjà
  fixé et son nom n'est pas modifiable dans ce formulaire.

## Messages et difficultés

| Message ou situation | Action |
|---|---|
| « Le montant des fonds non valide » | Renseignez un montant strictement positif, avec un point pour les centimes. |
| « Le nombre de fond non valide » | Renseignez une quantité entière supérieure ou égale à un. |
| « Date de commande non valide » | Vérifiez le format de la Date d'expiration ou utilisez Choisir une date. |
| « Veuillez sélectionner l'occasion (URSSAF) » | Choisissez une valeur dans Pour l'occasion de. |
| « Veuillez sélectionner une entité ("Offert par") » | Sélectionnez un client dans Offert par. |
| « L'enregistrement précédent est encore en cours. Patientez quelques secondes. » | Attendez et vérifiez la liste avant toute nouvelle tentative. |
| « Erreur lors de l’ajout de la commande » ou autre erreur | Lisez le message, vérifiez les champs puis la liste avant de recommencer. Si le problème persiste, signalez le message à votre interlocuteur Tribuneo. |

Pendant l'enregistrement, un indicateur d'attente remplace le bouton.
La fermeture du formulaire, à elle seule, ne confirme pas une création : elle
peut aussi suivre le message d'un enregistrement encore en cours. En cas de
doute, contrôlez la liste avant de refaire une commande.

## Périmètre de cette fiche

L'import **CSV/XLSX**, la facturation et les paiements sont des procédures
distinctes. Cette fiche ne décrit pas leurs étapes.

Néo peut expliquer cette procédure. La saisie et l'enregistrement sont effectués
par l'utilisateur dans l'interface ; Néo ne crée aucune commande.
