# Renseigner les informations bancaires accessibles pour un client

## Objectif et prérequis

Compléter les informations proposées dans l'écran **Clients**, onglet
**Banque** de la fiche du client. Retrouvez d'abord la bonne fiche et disposez
des droits nécessaires à sa gestion.

Dans ce parcours client, le formulaire propose uniquement le numéro comptable
et le numéro intracommunautaire. La saisie d'un IBAN, d'un BIC ou d'un RIB client
n'est pas accessible dans les sources vérifiées. Les champs de compte bancaire
du formulaire partagé sont conditionnés au type partenaire.

## Étapes

1. Dans **Clients**, sélectionnez le client et consultez l'onglet **Banque**
   de sa fiche, à droite.
2. Cliquez sur le bouton **Ajouter** (ou **Modifier** si des informations
   existent) en bas de la fiche. Autre accès : sur la ligne du client, menu
   **…** (**Plus d'actions**), puis **Editer informations bancaires**.
3. Sans informations existantes, le panneau porte la rubrique
   **AJOUTER LES INFORMATIONS BANCAIRES** et le nom du client pour titre ; il
   ne contient que la section **Comptabilité**. Renseignez selon
   le besoin **Numéro de compte comptabilité** et **Numéro intracommunautaire**.
4. Si des informations existent déjà, le formulaire est prérempli. Sa rubrique
   est **MODIFIER LES INFORMATIONS BANCAIRES** et ses champs
   sont **Numéro de comptabilité** et **Numéro intra communautaire**.
   Ces différences de libellé des champs restent celles de l'écran actuel.
5. Cliquez sur le bouton orange **Enregistrer** pour envoyer les informations.
   Pour abandonner sans enregistrer, cliquez sur **Annuler**, sur ✕ **Fermer**
   ou en dehors du panneau.
6. Après **Informations bancaires ajoutées avec succès** ou
   **Modification des informations bancaires réussie**, vérifiez l'onglet
   **Banque**. Il affiche **N° comptabilité** et **N° TVA intracom.**, ou
   **Non renseigné** pour une valeur absente. Des lignes **IBAN** et **BIC**
   n'y apparaissent que si ces valeurs existent déjà pour l'entité.

## Contrôles et limites

- Les deux champs visibles n'ont pas de validation obligatoire ni de contrôle
  local de format ; le numéro intracommunautaire est limité à treize caractères.
  Le clavier numérique suggéré n'est pas un filtre imposant des chiffres seuls.
  Ne prenez pas l'acceptation du formulaire pour une certification du numéro.
- Le bouton de la fiche et le menu décident automatiquement entre ajout et
  modification selon les informations reçues. Il n'existe pas ici de commande pour ajouter plusieurs
  comptes au même client. L'API refuse un second ajout avec
  `Bank information already exists for this entity`.
- Le panneau bancaire du client ne permet pas de saisir
  **Iban**, **BIC**, **Clé RIB**, **Code établissement**, **Code guichet** ou
  **Numéro de compte**. Leur présence dans un formulaire partagé ne prouve pas
  un parcours client. Cette fiche ne décrit aucune opération de partenaire.
- Effacer le numéro comptable ne garantit pas sa suppression : le formulaire
  envoie une valeur nulle et l'action API ne met à jour ce numéro que s'il est
  non nul. La persistance et l'effacement effectifs n'ont pas été testés.
- La mise à jour API relit ensuite les informations avec un identifiant qui
  peut ne pas être celui de l'entité. En cas d'erreur, vérifiez l'état avant de
  retenter : une partie des données peut déjà avoir été enregistrée.

Les erreurs prévues sont **Erreur lors de l'ajout des informations bancaires**
et **Erreur lors de la modification des informations bancaires**.
Une réponse incertaine ou **Aucune information bancaire enregistrée pour le
moment** ne suffit pas à conclure à l'absence d'effet ou de données.

## Portée de l'aide Néo

Néo guide en lecture seule. Il ne saisit pas de coordonnées bancaires, ne
réalise pas de paiement et n'a pas besoin d'un IBAN réel pour expliquer l'écran.

Vérification au 30 octobre 2026 : formulaires client, modèle, repositories et
actions API lus. Affichage, fermeture en session, validations exécutées et
persistance réelle non testés.

Libellés relus le 2 novembre 2026 : tranche 1 M15, sans changement de logique.
Recette visuelle et opérations en session non exécutées pour cette mise à jour.
