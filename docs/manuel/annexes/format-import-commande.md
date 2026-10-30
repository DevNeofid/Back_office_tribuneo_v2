# Format du fichier d'import de commande

Cette annexe complète [Créer une commande par import CSV/XLSX](../creer-commande-import-fichier.md).
Elle décrit le parseur du code examiné le 30 octobre 2026. Elle ne constitue pas
une validation d'un import réel.

## Formats et séparateurs

- Extensions proposées par le sélecteur et acceptées par l'API : **.csv** et
  **.xlsx**. Les formats .xls et .ods ne sont pas pris en charge.
- Pour le CSV, préférez **UTF-8**, séparateur virgule et montants avec un point.
  Un BOM UTF-8 en début du premier en-tête est retiré par le parseur.
- Le serveur remplace globalement les points-virgules et les tabulations par
  des virgules avant de lire le CSV. Ces séparateurs sont donc possibles, mais
  leur remplacement touche aussi le contenu des cellules, même entre guillemets :
  évitez points-virgules et tabulations dans les valeurs.
- Les champs contenant une virgule doivent être entre guillemets doubles.
  Préférez `25.50` à `25,50` ; une virgule décimale non protégée peut décaler
  les colonnes. `"25,50"` est lu comme 25,50, mais le point évite cette ambiguïté.
- Le XLSX est converti en CSV par PhpSpreadsheet avant le même traitement.
  Préparez une seule feuille simple contenant le tableau utile.
  Le code n'offre aucun choix de feuille et ne parcourt pas toutes les feuilles.
  La conversion XLSX et les formules n'ont pas été vérifiées en exécution locale :
  utilisez des valeurs simples et contrôlez votre export CSV si nécessaire.
- Aucun plafond de taille ou de lignes spécifique à ce formulaire n'a été
  relevé ; cela ne garantit pas l'acceptation d'un fichier volumineux par le serveur.

## En-têtes et colonnes

La première ligne contient les en-têtes. Leur ordre est libre ; les espaces
au début et à la fin sont retirés et la casse est ignorée. Utilisez les noms
exacts ci-dessous, sans accent : **prenom**, et non « prénom ».
Évitez les en-têtes en double : le dernier de même nom normalisé l'emporte.

| En-tête | Obligation | Valeur attendue |
|---|---|---|
| **montant** | Colonne et valeur obligatoires | Montant du chèque, strictement supérieur à zéro. Utilisez un nombre simple, sans devise, avec au plus deux décimales. |
| **email** | Au moins une colonne parmi email et mobile | Adresse non vide si mobile est vide. Si renseignée, elle doit respecter le contrôle de forme e-mail, même avec un mobile présent. |
| **mobile** | Au moins une colonne parmi email et mobile | Valeur non vide si email est vide. Le parseur de cet import ne contrôle pas le format téléphonique ; vérifiez vous-même le numéro et conservez les zéros initiaux en cellule texte. |
| **prenom** | Facultative | Prénom du bénéficiaire ; vide autorisé. |
| **nom** | Facultative | Nom du bénéficiaire ; vide autorisé. |

Le contrôle de l'e-mail exige des caractères avant et après `@`, puis un point
et une fin de domaine, sans espace ni autre `@`. Il ne vérifie pas l'existence
ou la délivrabilité de l'adresse.

Les colonnes inconnues sont ignorées. **quantite**, **occasion**, **date**,
**offert_par** ou **message** ne pilotent donc pas la commande.
N'utilisez pas une ligne de total en fin de tableau : elle serait lue comme
un chèque. Les lignes entièrement vides sont ignorées ; une ligne de
séparateurs avec des cellules vides n'est pas nécessairement ignorée.

## Montants et regroupements

Chaque ligne valide produit un chèque, quel que soit le nombre de fois où le
même destinataire apparaît. Il n'y a pas de dédoublonnage des lignes ou des
contacts. Le total est la somme des montants et le nombre de chèques est le
nombre de lignes valides.

Les lignes de commande sont agrégées par montant formaté sur deux décimales.
Pour trois lignes de 25.00, 25.00 et 20.00, on obtient trois chèques, un total
de 70.00 et deux groupes : deux chèques de 25.00, un de 20.00.

Le parseur enlève les espaces simples et insécables du montant, remplace la
virgule par un point puis convertit en nombre PHP. Il n'impose pas strictement
deux décimales et peut accepter un préfixe numérique suivi de texte. Ce
comportement permissif n'est pas une garantie de montant correct : préparez
uniquement des nombres simples à deux décimales au plus, sans symbole monétaire,
texte ou séparateur de milliers.

## Paramètres communs saisis dans le formulaire

- **Offert par** sélectionne le client auquel la commande est rattachée.
  L'API exige un identifiant d'entité existant et un texte « Offert par » non vide.
- **Personnalisation offert par (optionnel)** remplace ce texte sur le chèque,
  sans changer le client. Les barres obliques sont remplacées par des tirets.
- **Pour l'occasion de** fournit l'identifiant et le nom de l'occasion.
  Dans le BO actuel, sélectionnez-la toujours : l'import saute le contrôle
  explicite, puis tente de lire une valeur non nulle. Si elle est absente,
  l'erreur survient avant l'appel API, hors du bloc de traitement des erreurs.
  L'action API n'impose pas elle-même la présence de ces deux champs.
- **Date d'expiration** est préremplie à un an dans le BO et commune à tous
  les chèques. Le formulaire contrôle la forme JJ/MM/AAAA puis transmet une
  date ; le serveur la normalise à 23:59:59 et exige au minimum le lendemain.
  Si aucune date n'est fournie directement à l'API, son normaliseur utilise
  un an par défaut ; ce n'est pas le parcours normal du formulaire.
- Les prénom, nom, e-mail et mobile sont enregistrés avec chaque chèque.
  L'import ne crée pas de comptes utilisateurs ni de fiches clients par ligne.

## Erreurs du fichier et limites d'affichage

Tout le fichier est analysé avant les écritures de la commande. Le premier
défaut rencontré interrompt cette analyse, sans numéro de ligne ni rapport
exhaustif. Les erreurs de parsing ci-dessous sont renvoyées par l'API avec
le préfixe **Order file creation failed: ** et un statut 500 dans le code actuel.
Le BO affiche généralement **Erreur lors de l’ajout de la commande** à leur place.

| Détail technique de l'API | Contrôle à effectuer |
|---|---|
| **CSV header row is missing.** | Ajouter la première ligne d'en-têtes. |
| **Missing required column: montant** | Utiliser l'en-tête montant. |
| **Missing required column: email or mobile** | Ajouter au moins l'une de ces deux colonnes. |
| **Invalid montant value (must be > 0).** | Contrôler chaque montant, dont les cellules vides, zéros et valeurs négatives. |
| **Each row must have at least email or mobile.** | Renseigner au moins un contact pour chaque ligne. |
| **Invalid email value.** | Contrôler tous les e-mails renseignés, même si un mobile est présent. |

Autres refus lus dans l'API : **Invalid file format. Only .csv or .xlsx are
supported.**, **Parsed file is empty or invalid.** (notamment en-têtes seuls),
**Create ORDER failed: the date must be at + 1 day !**.
Si le composant XLSX est absent, le détail est **XLSX support is not available
(PhpSpreadsheet missing). Upload a CSV instead.**. Ces messages ne sont pas
garantis visibles dans le formulaire.

Un échec d'analyse intervient avant la création. En revanche, une erreur
générique ou une coupure peut survenir après l'enregistrement : contrôlez
l'existence de la commande avant toute nouvelle tentative. Le parcours import
ne bénéficie pas de la protection contre les doubles requêtes de la saisie manuelle.

## Notifications et exemple inerte

Après validation de la transaction de création, le serveur tente un e-mail
pour chaque ligne avec e-mail. Sans e-mail, la ligne est ignorée par ce service ;
aucun appel SMS n'est présent dans ce parcours. Les échecs d'envoi retournés
par le service sont comptés sans annuler la commande. Le BO ignore le bilan
`mails.sent / failed / skipped` ; un succès affiché ne prouve pas la livraison.

Le [fichier exemple](../exemples/commande-import-exemple.csv) montre les cinq
colonnes et les montants du regroupement ci-dessus. Il est **volontairement
non importable** : `NE_PAS_IMPORTER_M02` en première ligne de données n'est
pas un e-mail valide. Les autres contacts utilisent `example.invalid` et les
identités sont fictives. Le marqueur provoque **Invalid email value.** avant
toute création ou notification. Ne le retirez pas pour une recette sans écriture.
La sélection locale du fichier suffit pour vérifier le sélecteur : n'appuyez
pas sur **Enregistrer** pendant cette recette.
