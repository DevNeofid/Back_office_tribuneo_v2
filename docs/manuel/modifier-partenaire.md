# Modifier les informations générales d'un partenaire

## Objectif et prérequis

Corriger le nom, l'e-mail, le SIRET, le téléphone ou la préférence de
dématérialisation d'un partenaire depuis **Partenaires**, écran
**Liste des magasins partenaires**. Identifiez d'abord la bonne fiche avec
[Rechercher et consulter un partenaire](rechercher-consulter-partenaire.md).

Ces informations appartiennent à l'entité commune : si elle est aussi cliente
ou partenaire d'un autre réseau, la modification s'applique aussi à ces rôles.

## Étapes

1. Sur la carte du partenaire, ouvrez l'icône d'édition (**Menu Edition**).
2. Choisissez **Editer informations générales**.
3. Le formulaire **Modifier un partenaire** s'ouvre prérempli : **Nom du partenaire**,
   **Email du partenaire**, **Siret du partenaire**, **Téléphone du partenaire**,
   **Code du partenaire** et la case **Accepte la dématérialisation**, cochée
   selon la valeur actuelle.
4. Modifiez les champs utiles, puis cliquez sur **Enregistrer**.
5. Après **Modification du partenaire réussie**, la liste se recharge.
   Contrôlez l'onglet **Informations générales**.

Ce formulaire n'a pas de bouton **Annuler**. Pour abandonner sans enregistrer,
fermez-le par un clic à l'extérieur de la boîte de dialogue ; ce mode de
fermeture n'a pas été vérifié en session.

## Contrôles

| Champ | Contrôle du formulaire | Contrôle de l'API |
| --- | --- | --- |
| Nom | **🚩 Texte non valide** si vide | refus si vide |
| E-mail | **🚩 Veuillez entrer une adresse email valide** | refus si vide |
| SIRET | **🚩 Numéro SIRET incorrect** si vide, **🚩 Numéro SIRET invalide** si autre que 14 chiffres | 14 chiffres ; obligatoire pour un partenaire ; refus s'il appartient déjà à une autre entité |
| Téléphone | **🚩 Numéro de mobile non valide** hors 10 chiffres commençant par 01 à 09 | refus si vide |
| Code | **🚩 Code non valide** si vide | non repris, voir ci-dessous |

Tout refus de l'API s'affiche par le même message
**Erreur lors de la modification du partenaire**, sans en donner la cause.
Vérifiez la fiche avant de recommencer.

## Limites

- **Code du partenaire** : le champ est obligatoire dans ce formulaire, mais
  l'action de mise à jour lue ne l'enregistre pas. Un changement de code n'est
  donc pas garanti, même après le message de réussite.
- Le **Nom d'utilisateur** de l'application n'est pas modifié par ce formulaire.
- Changer l'e-mail change l'adresse utilisée pour l'envoi du lien de première
  connexion ; cela ne modifie pas, dans l'action lue, l'e-mail du compte
  d'application.
- Adresse, coordonnées bancaires et secteurs ont leurs propres formulaires.

## Portée de l'aide Néo

Néo explique la modification ; il ne change aucune fiche partenaire.

Vérification au 30 octobre 2026 : menu, formulaire, validateurs, repository et
action API de mise à jour lus. Enregistrement réel, fermeture sans sauvegarde et
effet sur les autres rôles non testés.
