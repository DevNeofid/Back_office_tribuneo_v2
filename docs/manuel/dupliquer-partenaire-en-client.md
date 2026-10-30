# Dupliquer un partenaire en client

## Objectif et prérequis

Ajouter le rôle client à une entité déjà partenaire du réseau courant, depuis
**Partenaires**, écran **Liste des magasins partenaires**, par exemple pour
qu'elle puisse passer commande. Vérifiez d'abord dans **Clients** qu'elle n'y
figure pas déjà.

Le terme **Dupliquer** de l'écran ne crée pas une copie indépendante : c'est la
même entité qui reçoit un second rôle dans le réseau courant. Nom, e-mail,
téléphone, SIRET, adresse, IBAN/BIC et secteurs restent communs aux deux rôles ;
une modification faite d'un côté s'applique à l'autre.

## Étapes

1. Retrouvez le partenaire avec
   [Rechercher et consulter un partenaire](rechercher-consulter-partenaire.md).
2. Sur sa carte, ouvrez le menu à trois points (**Afficher le Menu**).
3. Choisissez **Dupliquer ce Partenaire en Client**.
4. La boîte **Ajouter ce Partenaire comme Client** indique :
   **Vous allez ajouter ce Partenaire comme Client. Êtes-vous sûr de vouloir continuer ?**
5. **Annuler** ferme sans changement. **Valider** envoie la demande.
6. Après **Partenaire dupliqué en client avec succès !**, vérifiez la présence
   de l'entité dans **Clients**.

Ici, contrairement à la duplication d'un client en partenaire, le message de
réussite n'apparaît qu'après la réponse favorable de l'API.

## Refus et anomalies

- L'API refuse un rôle client déjà présent dans le réseau avec
  `Entity type already exists`, et une entité introuvable avec
  `Entity not found`.
- En cas de refus, le BO n'affiche aucun message et la boîte reste ouverte.
  Choisissez **Annuler**, puis vérifiez dans **Clients** au lieu de recommencer.
- L'ajout du rôle client ne crée ni compte d'application, ni solde, ni code
  supplémentaire.

## Suite

La fiche cliente se gère ensuite avec les fiches client existantes, par exemple
[Rechercher un client](rechercher-client.md) et
[Modifier un client](modifier-client.md). Le rôle partenaire n'est pas retiré
par cette action.

## Portée de l'aide Néo

Néo explique cette action ; il n'ajoute aucun rôle.

Vérification au 30 octobre 2026 : menu, confirmation, repository et action API
d'ajout de rôle lus. Ajout réel, absence de message en cas de refus et
apparition dans **Clients** non testés.
