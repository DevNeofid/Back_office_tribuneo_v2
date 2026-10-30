# Attribuer des secteurs d'activité à un partenaire

## Objectif et prérequis

Choisir les secteurs d'activité affichés pour un partenaire depuis
**Partenaires**, écran **Liste des magasins partenaires**. Identifiez d'abord
la fiche et vérifiez ses secteurs actuels dans l'onglet
**Informations générales**, rubrique **Secteurs d'activité**.

Les secteurs sont rattachés à l'entité, pas au seul réseau courant : si elle
est partenaire dans un autre réseau, elle y garde les mêmes secteurs.

## Étapes

1. Sur la carte, ouvrez l'icône d'édition (**Menu Edition**), puis
   **Editer secteurs d'activité**.
2. La boîte affiche **Sélectionnez les options qui s'appliquent:** et la liste
   de tous les secteurs. Les secteurs actuels du partenaire sont déjà cochés.
3. Cochez ou décochez les secteurs voulus.
4. Cliquez sur **Enregistrer**. La sélection remplace intégralement la
   précédente : un secteur décoché est retiré, et tout décocher retire tous les
   secteurs du partenaire.
5. Après **Modification des secteurs d'activité réussie**, contrôlez la rubrique
   **Secteurs d'activité** de la carte.

La boîte n'a pas de bouton **Annuler** ; fermez-la par un clic à l'extérieur
pour abandonner. Ce mode de fermeture n'a pas été vérifié en session.

## Créer un secteur depuis cette boîte

Le champ **Nouveau secteur d'activité** et le bouton **Créer** ajoutent
immédiatement un secteur au catalogue commun, avant même **Enregistrer** et
même si vous fermez ensuite la boîte. Le nouveau secteur n'est pas coché
automatiquement. Les messages sont **Le secteur d’activité a été ajouté** ou
**Erreur lors de l’ajout du secteur d’activité** ; un nom déjà existant est
refusé. Le catalogue n'a pas de séparation par réseau dans les sources lues.

La gestion du catalogue, dont la suppression d'un secteur, se fait depuis le
menu **Secteurs** et n'est pas décrite ici.

## Erreurs et vérifications

En cas de **Erreur lors de la modification des secteurs d'activité**, ne
concluez pas que rien n'a changé : l'API retire d'abord tous les secteurs de
l'entité puis ajoute ceux sélectionnés, sans transaction. Une erreur peut donc
laisser le partenaire sans une partie de ses secteurs. Contrôlez la carte avant
de recommencer.

Si la liste des secteurs reste vide à l'ouverture, le catalogue n'a pas pu
être chargé et aucun message ne le signale. Fermez la boîte sans enregistrer
et réessayez plus tard ; la carte continue d'afficher les secteurs actuels.

## Portée de l'aide Néo

Néo explique l'attribution ; il ne crée ni ne modifie aucun secteur.

Vérification au 30 octobre 2026 : menu, boîte de sélection, repository, actions
API et structure des tables lus. Enregistrement réel, création réelle et
comportement en cas d'erreur non testés.
