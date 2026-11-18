# Modifier les informations générales d'un partenaire

## Objectif et prérequis

Corriger le nom, l'e-mail, le SIRET, le téléphone ou la préférence de
dématérialisation d'un partenaire depuis **Partenaires**, écran
**Magasins partenaires**. Identifiez d'abord la bonne fiche avec
[Rechercher et consulter un partenaire](rechercher-consulter-partenaire.md).

Ces informations appartiennent à l'entité commune : si elle est aussi cliente
ou partenaire d'un autre réseau, la modification s'applique aussi à ces rôles.

## Étapes

1. Sur la ligne du partenaire, cliquez sur le crayon **Modifier le partenaire**
   (anciennement **Menu Edition**).
2. Choisissez **Editer informations générales**.
3. Un panneau s'ouvre à droite, avec la rubrique **MODIFIER LE PARTENAIRE** et
   le nom du partenaire en titre (anciennement **Modifier un partenaire**). La
   section **Informations du partenaire** est préremplie : **Nom du partenaire**,
   **Code du partenaire**, **Siret du partenaire**, **Email du partenaire**,
   **Téléphone du partenaire** et l'interrupteur **Accepte la dématérialisation**,
   activé selon la valeur actuelle. **Code du partenaire** est en lecture seule, sous
   la mention « Le code du partenaire est attribué à la création et n'est pas
   modifiable depuis cet écran. »
4. Modifiez les champs utiles, puis cliquez sur **Enregistrer**.
5. Après **Modification du partenaire réussie**, la liste se recharge.
   Dépliez la fiche et contrôlez la rubrique **INFORMATIONS GÉNÉRALES**.

Pour abandonner, cliquez sur **Annuler** ou sur le bouton ✕ **Fermer** ; un
clic en dehors du panneau le ferme aussi sans enregistrer. Ce mode de
fermeture n'a pas été vérifié en session.

## Contrôles

| Champ | Contrôle du formulaire | Contrôle de l'API |
| --- | --- | --- |
| Nom | **🚩 Texte non valide** si vide | refus si vide |
| E-mail | **🚩 Veuillez entrer une adresse email valide** | refus si vide |
| SIRET | **🚩 Numéro SIRET incorrect** si vide, **🚩 Numéro SIRET invalide** si autre que 14 chiffres | 14 chiffres ; obligatoire pour un partenaire ; refus s'il appartient déjà à une autre entité |
| Téléphone | **🚩 Numéro de mobile non valide** hors 10 chiffres commençant par 01 à 09 | refus si vide |
| Code | aucun : champ en lecture seule ; un code absent ne bloque pas l'enregistrement | non repris, voir ci-dessous |

Tout refus de l'API s'affiche par le même message
**Erreur lors de la modification du partenaire**, sans en donner la cause.
Vérifiez la fiche avant de recommencer.

## Limites

- **Code du partenaire** : affiché en lecture seule. Il est attribué à la
  création (saisi ou généré) et ne peut pas être changé depuis cet écran ;
  l'action de mise à jour lue ne le reprend pas. Une fiche sans code s'affiche
  avec un champ vide : cela ne bloque plus l'enregistrement des autres champs,
  et aucun code n'est créé.
- Le nom d'utilisateur de l'application (ligne **Utilisateur** de la fiche)
  n'est pas modifié par ce formulaire.
- Changer l'e-mail change l'adresse utilisée pour l'envoi du lien de première
  connexion ; cela ne modifie pas, dans l'action lue, l'e-mail du compte
  d'application.
- Adresse, coordonnées bancaires et secteurs ont leurs propres formulaires.

## Portée de l'aide Néo

Néo explique la modification ; il ne change aucune fiche partenaire.

Vérification au 30 octobre 2026 : menu, formulaire, validateurs, repository et
action API de mise à jour lus. Le 2 novembre 2026 (lot 09, M15C) : code en
lecture seule et fiche sans code vérifiés par tests de widget simulés, sans
appel réseau. Enregistrement réel, rendu visuel, fermeture sans sauvegarde et
effet sur les autres rôles non testés.
