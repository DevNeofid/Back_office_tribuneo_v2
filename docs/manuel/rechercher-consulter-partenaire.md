# Rechercher et consulter un partenaire

## Objectif et prérequis

Retrouver un commerce partenaire du réseau courant et lire sa fiche depuis le
menu **Partenaires**, écran **Magasins partenaires** (anciennement
**Liste des magasins partenaires**). La liste est
chargée pour le réseau sélectionné ; un partenaire d'un autre réseau n'y figure
pas. Disposez des droits d'administration du réseau.

## Partenaire, client et bénéficiaire

- Un **partenaire** est un commerce qui a le rôle partenaire dans le réseau :
  il dispose d'un compte pour l'application, d'un solde Tribuneo et peut être
  remboursé. Il se gère dans **Partenaires**.
- Un **client** est l'entité qui passe des commandes. Il se gère dans
  **Clients** et ses fiches sont distinctes de celles-ci.
- Un **bénéficiaire** est le destinataire des bons d'une commande. Il n'a pas
  de fiche dans **Partenaires** ni dans **Clients** ; il se consulte depuis la
  commande concernée : voir [Consulter les bons d'une commande](consulter-bons-commande.md)
  et, pour une commande importée,
  [Consulter les bénéficiaires d'une commande importée](consulter-beneficiaires-commande-importee.md).

Une même entité peut être à la fois client et partenaire : son nom, son e-mail,
son téléphone, son SIRET, son adresse, ses informations bancaires (hors numéro
comptable) et ses secteurs d'activité sont alors communs aux deux rôles.

## Rechercher

1. Ouvrez **Partenaires** dans le menu latéral bleu marine (groupe **RÉSEAU**).
2. Saisissez une partie du nom dans le champ **Nom du partenaire…**
   (anciennement **Rechercher...**). La liste se met à jour environ une
   demi-seconde après la frappe, sans distinction de majuscules.
3. Ou cliquez sur une lettre de l'index alphabétique : seules les lettres qui
   ont au moins un partenaire sont proposées. Cliquer une lettre vide le champ
   de recherche.
4. Affinez si besoin avec la liste des secteurs (**Tous les secteurs** par
   défaut ; seuls les secteurs présents dans la liste sont proposés) et la
   bascule **Tous** / **Dématérialisés** / **Papier seul**. Ces filtres
   s'appliquent aussi aux résultats d'une recherche.

La recherche porte uniquement sur le nom, dans la liste déjà chargée. Elle ne
cherche ni par e-mail, ni par SIRET, ni par code, ni par nom d'utilisateur.
Effacer la recherche ramène à la dernière lettre choisie. Si aucun partenaire
ne correspond, l'écran affiche **Aucun partenaire**.

## Lire la fiche

Chaque partenaire occupe une carte. Sa ligne affiche ses initiales, son nom,
son code s'il en a un, ses secteurs d'activité, la pastille **Dématérialisé**
ou **Papier seul**, la pastille orange **Aucun compte utilisateur** s'il n'a
pas de nom d'utilisateur, et à droite son **SOLDE TRIBUNEO** en euros
(anciennement **Solde Tribuneo actuel**).

Cliquez sur la ligne ou sur le chevron **Déplier la fiche** pour afficher le
détail ; une seule fiche est dépliée à la fois. Les trois rubriques sont côte
à côte, sans onglets :

| Rubrique | Contenu affiché |
| --- | --- |
| **INFORMATIONS GÉNÉRALES** | **Email**, **Téléphone**, **SIRET**, **Utilisateur** (nom d'utilisateur de l'application) |
| **ADRESSE** | adresse, code postal et ville, pays ; **Latitude**, **Longitude** |
| **INFORMATIONS BANCAIRES** | **IBAN**, **BIC**, **Clé RIB**, **Code établ.**, **Code guichet**, **N° compte**, **N° compta.**, **N° intracom.** |

Une valeur absente est notée **Non renseigné**. Les textes
**Pas de secteur d'activité**, **Aucune adresse enregistrée pour le moment**
et **Aucune information bancaire enregistrée pour le moment** indiquent ce que
la liste a reçu. L'ancienne rangée **Filtres :** n'existe plus.

## Actions disponibles depuis la carte

Les boutons sont à droite de la ligne, avant le chevron :

- Icône QR, infobulle **QR code du magasin** (anciennement **Menu Qrcode**) :
  QR de réception, QR et lien de première connexion. Chaque choix lance une
  génération ; ne l'ouvrez pas pour vérifier un simple libellé.
- Crayon, infobulle **Modifier le partenaire** (anciennement **Menu Edition**) :
  informations générales, secteurs d'activité, adresse, informations bancaires.
- Bouton **…**, infobulle **Plus d'actions** (anciennement **Afficher le Menu**) :
  **Dupliquer ce Partenaire en Client** et **Désactiver ce partenaire**.

## Limites

- Une liste vide (**Aucun partenaire**) ou un partenaire absent ne prouve pas
  son inexistence : le chargement peut avoir échoué sans message, ou un filtre
  de secteur ou de dématérialisation peut le masquer. Remettez les filtres sur
  **Tous les secteurs** et **Tous**, rouvrez **Partenaires** avant de
  conclure, et ne recréez pas un partenaire sans passer par la recherche par
  SIRET de l'ajout.
- Un partenaire dont le nom commence par une lettre accentuée peut ne pas
  apparaître sous une lettre : cherchez-le avec **Nom du partenaire…**.
- Un partenaire désactivé dans le réseau n'apparaît plus dans cette liste.
- L'IBAN est affiché en clair dans la fiche dépliée : ne le recopiez pas dans
  une conversation.

## Portée de l'aide Néo

Néo explique où trouver l'information et peut lire les partenaires en lecture
seule ; il ne modifie aucune fiche. Il ne cite pas d'IBAN complet.

Vérification au 30 octobre 2026 : menu, écran, recherche, onglets, repository
et lecture API lus. Affichage en session, cas de liste vide et noms commençant
par un caractère accentué non testés.
