# Créer un secteur d'activité

## Objectif et portée

Ajouter un libellé au catalogue des secteurs, avec un compte administrateur.
Ce catalogue est commun aux réseaux dans les sources vérifiées ; l'ajout ne
concerne pas uniquement le réseau affiché en bas du menu.

Créer un secteur ne l'attribue automatiquement à aucun partenaire. Pour
l'attribution, utilisez la fiche existante
[Attribuer des secteurs d'activité à un partenaire](attribuer-secteurs-partenaire.md).

## Étapes

1. Ouvrez **Secteurs** dans le menu latéral (groupe **RÉSEAU**). Le titre est
   **Secteurs d'activité**. Sous le champ d'ajout, la liste **Secteurs**
   indique leur nombre et les classe par ordre alphabétique, sur deux colonnes.
2. Vérifiez que le secteur recherché n'existe pas déjà. Un échec de chargement
   affiche **Impossible de charger les secteurs d'activité.** avec un bouton
   **Réessayer** ; un catalogue vide affiche **Aucun secteur d'activité**.
3. Renseignez **Nouveau secteur d'activité** avec le libellé souhaité (exemple
   affiché dans le champ : « Ex. Fromagerie »).
4. Cliquez sur **Ajouter** ou appuyez sur Entrée. L'ajout part immédiatement,
   sans confirmation ; pendant l'envoi, le bouton est désactivé et un
   indicateur de chargement remplace son icône.
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
avant de recommencer. Ce message ne permet pas de distinguer à lui seul un
doublon, une limite de nom ou un problème technique. Si l'ajout réussit mais
que le rechargement de la liste échoue, le message de réussite s'affiche et la
liste indique **Impossible de charger les secteurs d'activité.** : cliquez sur
**Réessayer** pour contrôler la présence du libellé.

Il existe aussi un bouton **Créer** dans le panneau des secteurs d'un partenaire :
il ajoute immédiatement au même catalogue, indépendamment de **Enregistrer**,
et ne coche pas automatiquement le nouveau secteur. Son utilisation et
l'attribution restent décrites dans la fiche partenaire citée plus haut.
L'écran **Secteurs** ne propose pas de renommage d'un secteur existant.

## Portée de l'aide Néo

Néo guide la création ; il ne crée ni n'attribue un secteur pour vous.

Vérification au 30 octobre 2026 : menu, vue, formulaire partenaire, usecase,
repository, action API et schéma lus. Aucun ajout ni essai de doublon effectué.
