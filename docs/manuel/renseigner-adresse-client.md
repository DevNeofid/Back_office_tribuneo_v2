# Renseigner ou modifier l'adresse d'un client

## Objectif et prérequis

Compléter l'adresse d'un client existant depuis **Clients**, écran
**Liste des clients**. Disposez des droits de gestion des adresses et vérifiez
l'identité de la fiche avant toute modification.

Une adresse renseignée est nécessaire au parcours de facturation : les champs
de rue, code postal et ville sont repris pour le client sur la facture. Ajouter
une adresse ne crée ni commande ni facture. Pour la facturation, consultez la
fiche [Générer la facture d'une commande](generer-facture-commande.md).

## Étapes

1. Dans **Clients**, retrouvez la fiche et consultez l'onglet **Adresse**.
2. Ouvrez le menu d'édition dans l'en-tête de la fiche et choisissez
   **Editer l'adresse**.
3. La fenêtre porte le titre **Indiquer l'adresse de ce commerçant** : ce
   libellé est aussi utilisé dans le parcours client. Si une adresse existe,
   les champs sont préremplis ; sinon le formulaire permet son ajout.
4. Renseignez **Adresse**, **Code postal**, **Ville** et **Pays**.
5. Cliquez sur **Enregistrer** pour envoyer l'ajout ou la modification. Pour
   abandonner, fermez sans enregistrer, notamment par clic à l'extérieur de la
   boîte de dialogue ; aucun bouton **Annuler** n'est prévu dans ce formulaire.
6. Après **Ajout de l'adresse réussi** ou **Modification de l'adresse réussie**,
   contrôlez l'onglet **Adresse** de la fiche actualisée.

## Contrôles et limites

- **Adresse**, **Ville** et **Pays** ne peuvent pas être vides ou composés
  uniquement d'espaces : **🚩 Texte non valide**.
- **Code postal** conserve uniquement les chiffres et exige cinq chiffres.
  Les messages sont **Entrez un code postal** et **Entrez un code postal valide**.
  Le contrôle reste le même quel que soit le pays saisi ; ce formulaire ne
  prouve pas la prise en charge d'un autre format postal.
- Pour le type client, les champs **Latitude** et **Longitude** ne sont pas
  proposés. Des mentions GPS peuvent apparaître dans l'onglet de consultation,
  sans rendre ces champs éditables dans le formulaire client.
- Ce parcours complète l'adresse liée à l'entité sélectionnée. Il ne propose
  ni carnet de plusieurs adresses ni choix séparé d'adresse de livraison et
  de facturation. Il ne garantit pas la mise à jour d'une facture déjà créée.
- **Aucune adresse enregistrée pour le moment** décrit la fiche reçue ; une
  erreur de lecture peut empêcher de conclure sur l'état réel des données.

En cas de **Erreur lors de l'ajout de l'adresse**,
**Erreur lors de la modification de l'adresse** ou de réponse incertaine,
vérifiez la fiche avant de recommencer. Une erreur lors de la facturation qui
suggère de vérifier l'adresse ne suffit pas à diagnostiquer à elle seule une
adresse absente.

## Portée de l'aide Néo

Néo peut expliquer où renseigner l'adresse ; il ne l'enregistre pas et ne lance
pas la facturation.

Vérification au 30 octobre 2026 : accès depuis la fiche client, formulaires,
repositories et utilisation de l'adresse en facturation lus dans le code.
Rendu, fermeture en session, enregistrement et génération de facture non testés.
