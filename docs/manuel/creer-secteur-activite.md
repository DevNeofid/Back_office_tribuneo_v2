# Créer un secteur d'activité

## Objectif et portée

Ajouter un libellé au catalogue des secteurs, avec un compte administrateur.
Ce catalogue est commun aux réseaux dans les sources vérifiées ; l'ajout ne
concerne pas uniquement le réseau affiché en haut de page.

Créer un secteur ne l'attribue automatiquement à aucun partenaire. Pour
l'attribution, utilisez la fiche existante
[Attribuer des secteurs d'activité à un partenaire](attribuer-secteurs-partenaire.md).

## Étapes

1. Ouvrez **Secteurs** dans le menu latéral. Le titre est **Secteurs d'activité**
   et la liste comporte **Nom du secteur** et **Actions**.
2. Vérifiez que le secteur recherché n'existe pas déjà. Si la liste semble
   anormalement vide, ne supposez pas que le catalogue est vide : un échec de
   chargement n'affiche pas de message dédié dans cette vue.
3. Renseignez **Nouveau secteur d'activité** avec le libellé souhaité.
4. Cliquez sur **Ajouter**. L'ajout part immédiatement, sans confirmation ;
   un indicateur de chargement remplace temporairement le bouton.
5. Après **Le secteur d’activité a été ajouté**, contrôlez la présence du
   libellé dans la liste. Le champ est alors vidé.

## Validations et erreurs

Les espaces au début et à la fin sont retirés avant l'envoi. Une saisie vide
ou composée seulement d'espaces n'est pas envoyée et ne produit pas de message
de validation. L'écran ne contrôle pas lui-même les doublons et n'impose pas
de longueur maximale de saisie.

Le schéma de base lu limite le nom à 255 caractères et le rend unique. Sa
comparaison ignore la casse et les accents : une variation de majuscules ou
d'accent ne garantit pas un nouveau nom distinct. Cette contrainte est côté
base, pas un avertissement préalable du formulaire ; le schéma de la base en
service n'a pas été interrogé.

En cas de **Erreur lors de l’ajout du secteur d’activité**, vérifiez la liste
avant de recommencer. L'ajout peut avoir réussi alors que le rechargement de
la liste a échoué. Ce message ne permet pas de distinguer à lui seul un
doublon, une limite de nom ou un problème technique.

Il existe aussi un bouton **Créer** dans la boîte des secteurs d'un partenaire :
il ajoute immédiatement au même catalogue, indépendamment de **Enregistrer**,
et ne coche pas automatiquement le nouveau secteur. Son utilisation et
l'attribution restent décrites dans la fiche partenaire citée plus haut.
L'écran **Secteurs** ne propose pas de renommage d'un secteur existant.

## Portée de l'aide Néo

Néo guide la création ; il ne crée ni n'attribue un secteur pour vous.

Vérification au 30 octobre 2026 : menu, vue, formulaire partenaire, usecase,
repository, action API et schéma lus. Aucun ajout ni essai de doublon effectué.
