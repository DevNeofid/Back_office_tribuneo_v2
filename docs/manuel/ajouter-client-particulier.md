# Ajouter un client particulier

## Objectif et prérequis

Créer une fiche client sans SIRET depuis **Clients**, écran **Liste des clients**.
Vous devez disposer des droits de gestion des clients et connaître le nom,
l'adresse e-mail et le téléphone à renseigner. Recherchez d'abord le client
pour éviter de créer une seconde fiche.

## Étapes

1. Ouvrez **Clients** dans le menu latéral.
2. Sous **Ajouter un client**, cliquez sur le bouton **+**.
3. À la question **Ce client est il un particulier ?**, choisissez **Oui**.
4. Dans **Ajouter un client**, renseignez **Nom du client**, **Email du client**
   et **Téléphone du client**. Le champ SIRET n'est pas affiché dans ce parcours.
5. Renseignez éventuellement **Code du client**. Le formulaire précise que ce
   code est optionnel et peut servir d'identifiant dans vos systèmes internes.
6. Cliquez sur **Enregistrer** pour créer le client, ou sur **Annuler** pour
   fermer sans enregistrer.
7. Après le message **Ajout du client réussi.**, retrouvez sa fiche dans la
   liste et vérifiez ses informations.

## Contrôles et limites

- Le nom ne peut pas être vide ou composé uniquement d'espaces :
  **🚩 Texte non valide**.
- L'e-mail est obligatoire et soumis au contrôle de format du formulaire :
  **🚩 Veuillez entrer une adresse email valide**. Ce contrôle ne vérifie pas
  l'existence de la boîte.
- Le téléphone est obligatoire : dix chiffres, commençant par 01 à 09. La
  saisie conserve uniquement les chiffres. Le message est
  **🚩 Numéro de mobile non valide**, même si le champ est nommé téléphone.
- Le code n'a pas de contrôle de format dans ce formulaire. L'API peut en
  générer un si vous le laissez vide ; vérifiez le résultat avant de l'utiliser
  dans un autre système. Aucun contrôle de doublon par nom ou e-mail n'est
  établi pour ce parcours sans SIRET.
- L'adresse et les informations bancaires ne sont pas demandées à cette étape.
  Complétez ensuite l'[adresse du client](renseigner-adresse-client.md),
  notamment avant la facturation, et si nécessaire ses
  [informations bancaires accessibles côté client](renseigner-coordonnees-bancaires-client.md).

Si **Erreur lors de l’ajout du client** apparaît ou si la réponse est incertaine,
recherchez la fiche et vérifiez son état avant de recommencer. Une liste vide
ne prouve pas à elle seule que la création n'a eu aucun effet.

## Portée de l'aide Néo

Néo explique le parcours ; il ne crée pas le client. Ne lui transmettez pas de
données personnelles pour une recette documentaire.

Vérification au 30 octobre 2026 : code de l'interface et API lus. Affichage en
session et enregistrement réel non testés.
