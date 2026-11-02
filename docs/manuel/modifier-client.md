# Modifier les informations générales d'un client

## Objectif et prérequis

Corriger les informations générales d'un client existant dans **Clients**,
écran **Liste des clients**. Retrouvez d'abord la bonne fiche et vérifiez son
identité. Vous devez disposer des droits de modification des clients.

## Étapes

1. Dans **Clients**, retrouvez le client avec **Rechercher...** ou son initiale.
2. Dans l'en-tête de sa fiche, ouvrez le menu d'édition, représenté par une
   icône de rectangle, puis choisissez **Editer informations générales**.
   Ce menu est distinct de celui proposant duplication et désactivation.
3. Dans **Modifier le client**, vérifiez les valeurs préremplies de
   **Nom du client**, **Email du client**, **Siret du client**,
   **Téléphone du client** et **Code du client**. Le code est en lecture
   seule, avec la mention « Le code du client est attribué à la création et
   n'est pas modifiable depuis cet écran. »
4. Corrigez le nom, l'e-mail, le SIRET ou le téléphone selon le besoin.
   Le code ne peut pas être modifié depuis cet écran.
5. Cliquez sur **Enregistrer** pour envoyer la modification. Pour abandonner,
   fermez la fenêtre sans enregistrer, notamment par clic à l'extérieur de la
   boîte de dialogue ; aucun bouton **Annuler** n'est prévu dans ce formulaire.
6. Après **Modification du client réussie**, vérifiez la fiche actualisée.

## Contrôles et différences avec la création

- Le nom est obligatoire : **🚩 Texte non valide**. L'e-mail est obligatoire et
  soumis au contrôle de format : **🚩 Veuillez entrer une adresse email valide**.
  Le téléphone conserve uniquement les chiffres et doit comporter dix chiffres
  commençant par 01 à 09 : **🚩 Numéro de mobile non valide**.
- Contrairement à l'ajout d'un particulier, le champ **Siret du client** est
  visible même pour un client sans SIRET. Aucun choix particulier/professionnel
  ni recherche SIRET n'est proposé dans cette fenêtre.
- Le champ SIRET limite la saisie aux chiffres et à quatorze caractères, sans
  validateur local de longueur minimale. L'API refuse un SIRET non vide qui ne
  comporte pas exactement quatorze chiffres :
  `Invalid siret format. It should be 14 digits.`
- Un SIRET vide est admis pour un client qui n'est partenaire dans aucun réseau.
  Si cette même entité est partenaire dans au moins un réseau, l'API le refuse :
  `Siret is required for a partner.` Un autre client ou partenaire ayant déjà
  le SIRET peut également provoquer un refus :
  `Update entity failed: Another entity with same siret already exists.`
- **Code du client** est affiché en lecture seule. Il est attribué à la
  création (saisi ou généré) et n'est pas modifiable depuis cet écran. Sa
  valeur existante reste envoyée, mais l'action API lue ne la reprend pas
  dans la mise à jour. Un code absent ne crée aucun blocage local supplémentaire pour corriger
  les autres champs : aucun code de remplacement n'est fabriqué. Une véritable modification
  du code reste une décision API distincte ; signalez le besoin au support.
- Les informations générales concernent l'entité commune. Pour une entité
  également partenaire ou liée à plusieurs réseaux, elles ne constituent pas
  une copie indépendante réservée à cette seule fiche client.
- La préférence de dématérialisation n'est pas affichée dans ce formulaire.
  Le code lu l'envoie à faux lors de cette modification : signalez cette limite
  au support avant d'enregistrer si cette préférence doit être conservée.

En cas de **Erreur lors de la modification du client.** ou de réponse
incertaine, relisez la fiche avant de retenter. Ce message ne prouve pas qu'aucun
changement n'a été appliqué. Le détail technique d'un refus API n'est pas
nécessairement affiché par le formulaire.

L'[adresse](renseigner-adresse-client.md) et les
[informations bancaires du client](renseigner-coordonnees-bancaires-client.md)
se modifient avec leurs entrées d'édition dédiées.

## Portée de l'aide Néo

Néo explique les champs et les refus ; il ne modifie pas le client.

Vérification au 30 octobre 2026 : interface, modèle et action API lus.
Le 2 novembre 2026 (lot 10, M15F) : code en lecture seule, correction sans code
et valeurs transmises au use case vérifiés par tests de widget simulés hors
réseau. Rendu navigateur, HTTP et persistance réelle non testés.
