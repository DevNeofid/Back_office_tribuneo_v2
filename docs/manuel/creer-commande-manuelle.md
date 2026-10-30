# Créer une commande en saisie manuelle

## Objectif

Enregistrer une commande pour un client existant, en renseignant les montants,
les quantités de chèques, l'occasion et la date d'expiration dans le formulaire.
Cette fiche concerne uniquement **Saisie manuelle**.

## Étapes

1. Ouvrez **Commandes**, puis cliquez sur le bouton **+** sous **Ajouter une
   commande**. Dans le formulaire, conservez **Saisie manuelle**.
2. Vérifiez la **Date d'expiration** préremplie. Modifiez-la au format
   **JJ/MM/AAAA** ou utilisez **Choisir une date**.
3. Renseignez **Montant par chèque** et **Nombre de chèque**. Le montant doit
   être supérieur à zéro ; la quantité est un entier d'au moins un. Pour les
   centimes, utilisez un point avec au maximum deux décimales.
4. Si nécessaire, remplissez **Message personnalisé** pour cette ligne. Pour
   plusieurs lignes, cochez **Différents fonds ?**, puis utilisez **+** pour
   ajouter une ligne et renseignez son montant et sa quantité.
5. Dans **Offert par**, sélectionnez le client. La recherche de cette liste
   porte sur son nom, via **Rechercher une entité...**. Sélectionnez aussi
   **Pour l'occasion de** : l'occasion est obligatoire.
6. Si nécessaire, complétez **Personnalisation offert par (optionnel)** pour
   changer le texte « Offert par » sur les chèques.
7. Relisez les lignes, le client, l'occasion et la date, puis cliquez sur
   **Enregistrer** et attendez le résultat. Le message **Ajout de la commande
   réussi** confirme l'enregistrement ; le formulaire se ferme et la liste se
   recharge. Retrouvez la commande dans la liste pour la contrôler.

## Personnalisations et plusieurs lignes

- Le **Message personnalisé** remplace le texte de l'occasion sur les chèques
  de la ligne. S'il est vide, le nom de l'occasion sélectionnée est utilisé.
  Il ne dispense pas de sélectionner une occasion.
- **Personnalisation offert par (optionnel)** modifie le texte imprimé ; elle
  ne change pas le client auquel la commande est rattachée.
- Quand plusieurs lignes sont présentes, le bouton **−** retire la dernière.
  Décocher **Différents fonds ?** supprime toutes les lignes sauf la première :
  vérifiez les données avant de changer ce réglage.
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
