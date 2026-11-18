# Attribuer des secteurs d'activité à un partenaire

## Objectif et prérequis

Choisir les secteurs d'activité affichés pour un partenaire depuis
**Partenaires**, écran **Magasins partenaires**. Identifiez d'abord la fiche et
vérifiez ses secteurs actuels : ils s'affichent en étiquettes sur sa ligne,
sous son nom (**Pas de secteur d'activité** s'il n'en a aucun).

Les secteurs sont rattachés à l'entité, pas au seul réseau courant : si elle
est partenaire dans un autre réseau, elle y garde les mêmes secteurs.

## Étapes

1. Sur la ligne du partenaire, cliquez sur le crayon **Modifier le partenaire**
   (anciennement **Menu Edition**), puis sur
   **Editer secteurs d'activité**.
2. Un panneau s'ouvre à droite, avec la rubrique **SECTEURS D'ACTIVITÉ** et le
   nom du partenaire en titre. La section **Secteurs d'activité** affiche
   « Sélectionnez les options qui s'appliquent. » et tous les secteurs sous
   forme de pastilles. Les secteurs actuels du partenaire sont déjà
   sélectionnés (pastille foncée avec une coche).
3. Cliquez sur une pastille pour la sélectionner ou la désélectionner.
4. Cliquez sur **Enregistrer**. La sélection remplace intégralement la
   précédente : un secteur désélectionné est retiré, et tout désélectionner
   retire tous les secteurs du partenaire.
5. Après **Modification des secteurs d'activité réussie**, contrôlez les
   étiquettes de secteurs sur la ligne du partenaire.

Pour abandonner, cliquez sur **Annuler** ou sur le bouton ✕ **Fermer** ; un
clic en dehors du panneau le ferme aussi sans enregistrer. Ce mode de
fermeture n'a pas été vérifié en session.

## Créer un secteur depuis cette boîte

Dans la section **Secteur absent de la liste**, le champ
**Nouveau secteur d'activité** et le bouton **Créer** ajoutent immédiatement
un secteur au catalogue commun, avant même **Enregistrer** et même si vous
fermez ensuite le panneau. Le nouveau secteur n'est pas sélectionné
automatiquement. Les messages sont **Le secteur d’activité a été ajouté** ou
**Erreur lors de l’ajout du secteur d’activité** ; un nom déjà existant est
refusé. Le catalogue n'a pas de séparation par réseau dans les sources lues.

La gestion du catalogue, dont la suppression d'un secteur, se fait depuis le
menu **Secteurs** : voir [Créer un secteur d'activité](creer-secteur-activite.md)
et [Supprimer un secteur d'activité](supprimer-secteur-activite.md).

## Erreurs et vérifications

En cas de **Erreur lors de la modification des secteurs d'activité**, ne
concluez pas que rien n'a changé : l'API retire d'abord tous les secteurs de
l'entité puis ajoute ceux sélectionnés, sans transaction. Une erreur peut donc
laisser le partenaire sans une partie de ses secteurs. Contrôlez la carte avant
de recommencer.

Si l'indicateur de chargement ne disparaît pas ou si la liste des secteurs
reste vide à l'ouverture, le catalogue n'a pas pu être chargé et aucun message
ne le signale. Fermez le panneau sans enregistrer et réessayez plus tard ; la
carte continue d'afficher les secteurs actuels.

## Portée de l'aide Néo

Néo explique l'attribution ; il ne crée ni ne modifie aucun secteur.

Vérification au 30 octobre 2026 : menu, boîte de sélection, repository, actions
API et structure des tables lus. Enregistrement réel, création réelle et
comportement en cas d'erreur non testés.
