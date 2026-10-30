# Rechercher et consulter un partenaire

## Objectif et prérequis

Retrouver un commerce partenaire du réseau courant et lire sa fiche depuis le
menu **Partenaires**, écran **Liste des magasins partenaires**. La liste est
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

1. Ouvrez **Partenaires** dans le menu latéral.
2. Saisissez une partie du nom dans **Rechercher...**. La liste se met à jour
   après une courte pause de saisie, sans distinction de majuscules.
3. Ou cliquez sur une lettre : seules les lettres qui ont au moins un partenaire
   sont proposées. Cliquer une lettre vide le champ de recherche.

La recherche porte uniquement sur le nom, dans la liste déjà chargée. Elle ne
cherche ni par e-mail, ni par SIRET, ni par code, ni par nom d'utilisateur.
Effacer la recherche ramène à la dernière lettre choisie.

## Lire la fiche

Chaque carte affiche le nom, **Accepte la dématérialisation : Oui** ou **Non**,
puis trois onglets :

| Onglet | Contenu affiché |
| --- | --- |
| **Informations générales** | **Email**, **Tel**, **Siret**, **Nom d'utilisateur** ; **Secteurs d'activité** ; **Solde Tribuneo actuel** en euros |
| **Adresse** | **Adresse**, **Code Postal**, **Ville**, **Pays** ; **Coordonnées GPS** (lat, long) |
| **Informations bancaires** | **Iban**, **BIC**, **Clé RIB**, **Code établissement**, **Code Guichet**, **Numéro de compte**, **Numéro de comptabilité**, **Numéro intracommunautaire** |

**Filtres :** et ses trois icônes ne filtrent pas les partenaires : elles
choisissent l'onglet ouvert sur toutes les cartes (informations générales,
adresse, informations bancaires).

Les textes **Pas de secteur d'activité pour le moment**,
**Aucune adresse enregistrée pour le moment** et
**Aucune information bancaire enregistrée pour le moment** indiquent ce que la
liste a reçu. Le code du partenaire n'est pas affiché sur la carte.

## Actions disponibles depuis la carte

- Icône QR, info-bulle **Menu Qrcode** : QR de réception, QR et lien de première
  connexion. Chaque choix lance une génération ; ne l'ouvrez pas pour vérifier
  un simple libellé.
- Icône d'édition, info-bulle **Menu Edition** : informations générales,
  secteurs d'activité, adresse, informations bancaires.
- Menu à trois points, info-bulle **Afficher le Menu** :
  **Dupliquer ce Partenaire en Client** et **Désactiver ce partenaire**.

## Limites

- Une liste vide ou un partenaire absent ne prouve pas son inexistence : le
  chargement peut avoir échoué sans message. Rouvrez **Partenaires** avant de
  conclure, et ne recréez pas un partenaire sans passer par la recherche par
  SIRET de l'ajout.
- Un partenaire dont le nom commence par une lettre accentuée peut ne pas
  apparaître sous une lettre : cherchez-le avec **Rechercher...**.
- Un partenaire désactivé dans le réseau n'apparaît plus dans cette liste.
- L'IBAN est affiché en clair sur la carte : ne le recopiez pas dans une
  conversation.

## Portée de l'aide Néo

Néo explique où trouver l'information et peut lire les partenaires en lecture
seule ; il ne modifie aucune fiche. Il ne cite pas d'IBAN complet.

Vérification au 30 octobre 2026 : menu, écran, recherche, onglets, repository
et lecture API lus. Affichage en session, cas de liste vide et noms commençant
par un caractère accentué non testés.
