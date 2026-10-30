# Créer une commande par import CSV/XLSX

## Objectif et préparation

Créer une commande pour un client existant à partir d'un fichier : chaque ligne
décrit un chèque et son bénéficiaire. Ce parcours est distinct de la saisie
manuelle. L'enregistrement nécessite les droits d'administration du réseau.

Préparez le fichier selon l'[annexe de format](annexes/format-import-commande.md).
Vérifiez les montants et les destinataires avant de l'utiliser : **l'enregistrement
déclenche des tentatives d'envoi d'e-mails aux bénéficiaires ayant une adresse
e-mail**, après la création de la commande. Aucun choix de désactivation de ces
envois n'est proposé dans ce formulaire.

## Étapes

1. Ouvrez **Commandes**, puis le bouton **+** sous **Ajouter une commande**.
2. Vérifiez la **Date d'expiration**, préremplie à un an. Saisissez une date au
   format **JJ/MM/AAAA** ou utilisez **Choisir une date**. Choisissez au minimum
   le lendemain ; le serveur fixe l'expiration à 23:59:59.
3. Cliquez sur **Importer un fichier**, puis **Importer CSV/XLSX**. Sélectionnez
   un fichier **.csv** ou **.xlsx**. Vérifiez **Fichier sélectionné : …**.
   Ce libellé confirme seulement la sélection locale, pas la validité du contenu.
4. Dans **Offert par**, choisissez le client existant. La liste propose
   **Rechercher une entité...** pour retrouver son nom.
5. Sélectionnez **Pour l'occasion de**. Choisissez toujours une occasion pour
   cet import : le formulaire actuel peut échouer avant l'envoi si elle manque.
   Si la liste ne propose aucune occasion, interrompez la saisie et signalez le
   problème à votre interlocuteur Tribuneo.
6. Si nécessaire, renseignez **Personnalisation offert par (optionnel)** :
   ce texte remplace « Offert par » sur le chèque, sans changer le client auquel
   la commande est rattachée. Les caractères `/` et `\` y sont remplacés par
   un tiret.
7. Relisez le fichier dans votre tableur, le client, l'occasion et la date.
   Le formulaire ne propose ni aperçu des lignes ni contrôle détaillé avant
   l'enregistrement. **Enregistrer** lance directement la création et les envois
   prévus : il n'y a pas de seconde confirmation dans ce parcours.
8. Pour créer réellement la commande, cliquez sur **Enregistrer** une seule fois
   et attendez. Un indicateur d'attente remplace le bouton. **Ajout de la commande
   réussi** accompagne la fermeture du formulaire et le rechargement de la liste.
   Retrouvez la commande et contrôlez son montant et son nombre de chèques.
   Ce message ne confirme pas la réception des e-mails par les bénéficiaires.

## Fichier, bénéficiaires et regroupements

- Une ligne = un chèque. Pour plusieurs chèques au même bénéficiaire, il faut
  plusieurs lignes ; une colonne de quantité n'est pas utilisée.
- Les chèques de même montant sont regroupés en lignes de commande. Les
  bénéficiaires restent associés à leurs chèques individuels.
- Chaque ligne doit fournir **email** ou **mobile**. Si un e-mail est renseigné,
  il doit être valide même si un mobile est également présent.
- **prenom** et **nom** sont facultatifs. L'import ne crée pas de fiche client
  pour chaque bénéficiaire et ne prouve pas qu'un utilisateur a déjà reçu ou
  scanné son bon.
- La date, le client, « Offert par » et l'occasion sont communs à toute la
  commande et viennent du formulaire. Une colonne de message personnalisé
  n'est pas prise en charge.
- Passer à **Saisie manuelle** efface la sélection du fichier. Passer à
  **Importer un fichier** efface les lignes de saisie manuelle.

## E-mails et résultat incertain

Après l'enregistrement en base, une tentative d'e-mail est effectuée pour chaque
ligne ayant une adresse e-mail. Des lignes répétées peuvent donc provoquer
plusieurs envois. Une ligne avec seulement un mobile est ignorée par le service
d'e-mail ; aucun envoi de SMS n'est appelé par ce parcours.

L'API comptabilise les e-mails envoyés, en échec et ignorés, mais le formulaire
ne présente pas ce bilan. Une commande peut être créée avec des e-mails en échec.
Un succès d'envoi ne constitue pas une preuve de réception.

**Ne réimportez pas automatiquement un fichier après une erreur ou une attente
anormale.** L'import n'est pas protégé contre les doublons d'envoi de la requête.
Vérifiez d'abord la commande dans la liste, en tenant compte de la recherche,
du chargement et de la pagination. Une liste vide ou une lecture en erreur ne
prouve pas qu'aucune commande n'a été créée. En cas de doute, faites vérifier
le résultat avant de recommencer.

## Messages et difficultés

| Message ou situation | Action |
|---|---|
| **🚩 Date de commande non valide** | Ce message concerne ici la Date d'expiration. Vérifiez JJ/MM/AAAA ; le contrôle local ne vérifie que la forme, le serveur contrôle ensuite la date. |
| **Veuillez sélectionner une entité ("Offert par")** | Choisissez le client dans Offert par. |
| **Veuillez importer un fichier** | Sélectionnez un CSV ou XLSX. Ce contrôle n'est atteint que si l'occasion a été choisie. |
| **Veuillez importer un fichier valide** | Le fichier sélectionné n'a pas de contenu exploitable en mémoire. Sélectionnez le bon fichier. |
| Occasion absente | Le contrôle explicite de l'occasion est sauté en mode import, mais sa valeur est lue juste après. Une erreur non gérée est possible avant l'appel API ; aucun message précis n'est garanti. Choisissez une occasion avant d'enregistrer. |
| **Erreur lors de l’ajout de la commande** | Message générique de l'import : vérifiez d'abord le résultat, puis les en-têtes, montants, contacts et date. Les erreurs détaillées du serveur ne sont pas affichées par ce parcours. |

Le parseur s'arrête à la première ligne invalide, avant la création de la
commande. Il ne renvoie pas de tableau d'erreurs ni de numéro de ligne.
L'[annexe](annexes/format-import-commande.md) décrit les contrôles et les
messages techniques pour aider au diagnostic.

## Écran et portée de l'aide

Écran **Liste des commandes**, formulaire **Ajouter une commande**, mode
**Importer un fichier**. Si ce même formulaire a été ouvert depuis un client,
le client est déjà fixé et son nom est en lecture seule.

Le [CSV d'exemple](exemples/commande-import-exemple.csv) est synthétique et
**volontairement non importable** : son premier e-mail est un marqueur invalide.
Conservez ce marqueur pour toute vérification sans écriture métier.

Néo peut expliquer la procédure pour CCI04 ; il ne sélectionne pas de fichier,
ne crée pas de commande et n'envoie pas d'e-mail. La facturation et les paiements
relèvent de procédures distinctes.
