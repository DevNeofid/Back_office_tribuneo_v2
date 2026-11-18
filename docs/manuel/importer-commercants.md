# Importer des commerçants depuis un fichier

## Objectif et prérequis

Ajouter plusieurs commerçants au réseau à partir d'un fichier, en trois temps :
déposer le fichier, relire et corriger chaque ligne dans une grille, puis
importer les lignes validées. Rien n'entre dans le réseau avant l'import final.

Préparez un fichier `.csv` (séparateur `;`) ou `.xlsx` de 2 000 lignes au plus.
Pour un seul commerçant, utilisez plutôt
[Ajouter un partenaire](ajouter-partenaire.md).

## Préparer le fichier

L'écran affiche la carte **Modèle de fichier** :

- Colonnes reconnues par leur nom d'en-tête : code, name, email, type, siret,
  phone, contact_phone, street, zip, city, country, lat, lng, activity_sectors,
  intracommunity_vat_number, iban, bic, key, account_number.
- Une colonne absente des en-têtes est lue à sa position : code (0), nom (1),
  email (2), type (4), SIRET (5), ville (6), téléphone de contact (7),
  téléphone (8), clé RIB (10), IBAN (14), BIC (15). Le fichier doit donc suivre
  le modèle.
- Type : « commerçant adhérent » ou partner pour un commerçant ; vide =
  commerçant.

## Étapes

1. Dans le menu latéral, groupe **RÉSEAU**, ouvrez **Import** (écran
   **Import de commerçants**). Le bouton **Importer des commerçants** de
   l'écran **Magasins partenaires**, ou **Importer** de l'écran **Clients**,
   mène au même écran.
2. Cliquez sur **Nouveau lot depuis un fichier** et choisissez le fichier.
   Pendant la lecture, **Lecture du fichier…** s'affiche. Le nouveau lot s'ouvre
   directement dans la grille **Relecture du lot**.
3. Relisez les lignes. La barre **Avancement : X / Y lignes traitées** résume
   le lot ; le bouton rouge **Prochaine à corriger (n)** ouvre directement la
   prochaine cellule en erreur.
4. Corrigez une cellule en cliquant dessus, en tapant la valeur, puis Entrée
   ou en sortant de la cellule. L'enregistrement est automatique ; Échap
   rétablit la valeur de départ.
5. Quand une ligne est juste, cochez sa case pour la valider. Une ligne à ne
   pas importer se retire avec **Écarter** (**Rétablir** pour revenir).
6. Cliquez sur **Importer les lignes validées (N)**, puis confirmez
   **Importer** dans la fenêtre **Importer les lignes validées**.
7. Lisez la fenêtre **Résultat de l'import** : nombre de lignes importées,
   dont les nouveaux commerçants, et lignes en échec avec leur motif.

Les lignes non validées restent dans le lot : vous pouvez les reprendre plus
tard avec **Ouvrir** dans la liste des lots.

## Lire la grille

- Champs obligatoires : **Nom**, **Type** (**Commerçant** ou **Client**),
  **Email** et, pour un commerçant, **SIRET**.
- Filtres : **Toutes**, **À relire**, **En anomalie**, **Complétées par la
  recherche**, **Validées**, **Écartées**, **Importées**, **En échec**, et
  recherche **Rechercher (nom, ville, SIRET)**. Le filtre, la recherche et la
  page sont mémorisés pour chaque lot.
- Survolez une cellule ou un statut pour lire le détail des anomalies. Un
  petit triangle bleu signale une valeur modifiée par rapport au fichier ; un
  clic propose **Revenir à l'origine**.

| Statut de ligne | Signification |
| --- | --- |
| **Prête à valider** | Aucune anomalie : cochez la ligne |
| **n à vérifier** | Avertissements seulement : l'import reste possible |
| **n à corriger** | Anomalies bloquantes ; un clic ouvre la première cellule en erreur |
| **Validée** | Ligne cochée, prête à importer |
| **Importée** | Commerçant déjà ajouté au réseau |
| **Écartée** | Ligne exclue de l'import |
| **Échec import** | L'import de cette ligne a échoué |

Raccourcis clavier, après un clic sur une ligne : ↑ ↓ changer de ligne,
Espace valider, E écarter, Entrée ou F2 modifier, N prochaine à corriger,
Échap quitter.

## Lots

La liste **Lots** affiche **Date**, **Source**, **Statut**, **Avancement**
(« X validées · Y en anomalie · Z à relire · W importées ») et **Action**.
Statuts : **En relecture**, **Recherche en cours**, **Import en cours**,
**Terminé**, **Abandonné**, **Échec**. Un lot terminé ou abandonné est en
lecture seule.

**Abandonner** (ou **Abandonner ce lot** dans le menu **⋮** de la grille) ferme
le lot après confirmation **Abandonner ce lot** : il ne pourra plus être
modifié ni importé. Les commerçants déjà importés restent dans le réseau.

## Compléter les informations

Selon la configuration du réseau, le bouton **Compléter les informations**
recherche dans des sources publiques des propositions pour les champs vides
(adresse, SIRET, position, TVA). Les propositions s'appliquent seulement au
brouillon, champ par champ, après **Appliquer au brouillon** ; la ligne reste
à valider dans la grille. **Comparer avec Néo** compare les candidats sans
choisir à votre place. Si le bouton est absent ou grisé, la fonction n'est pas
disponible pour ce réseau.

## Contrôles et limites

- Fichier refusé : « Fichier illisible : seuls les fichiers .csv (séparateur ;)
  et .xlsx sont acceptés. », « Le fichier ne contient aucune ligne. » ou « Le
  fichier dépasse 2 000 lignes : découpez-le en plusieurs fichiers. »
- Un SIRET déjà présent dans le réseau complète la fiche existante ; un SIRET
  connu de Tribuneo dans un autre réseau rattache la fiche à ce réseau. Le
  détail s'affiche dans l'infobulle du statut.
- Avant l'import ou en quittant l'écran, si des corrections n'ont pas pu être
  enregistrées, la fenêtre **Modifications non enregistrées** le signale.
  L'indicateur en haut de la grille (**Enregistré**, **Enregistrement…** ou
  **n erreur(s) d'enregistrement**) permet de réessayer.
- « Un import est déjà en cours sur ce lot, ou il est terminé. » : rechargez
  la grille avant de recommencer.

## Portée de l'aide Néo

Néo explique l'import ; il ne dépose aucun fichier, ne valide aucune ligne et
ne lance aucun import.

Vérification au 18 novembre 2026 : écran d'import, grille de relecture,
contrôles et messages lus dans le code de l'interface « Arc ». Dépôt, import
et recherche réels non testés.
