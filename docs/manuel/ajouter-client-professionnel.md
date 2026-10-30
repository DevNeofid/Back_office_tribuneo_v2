# Ajouter un client professionnel et rechercher son SIRET

## Objectif et prérequis

Ajouter un client professionnel depuis **Clients**, écran **Liste des clients**.
Disposez des droits de gestion des clients et du SIRET à rechercher. Recherchez
d'abord le client par son nom pour éviter un doublon.

La recherche SIRET de ce parcours consulte les entités enregistrées dans
Tribuneo. Les sources lues ne montrent pas d'appel à un registre externe.
Elle ne certifie donc pas l'existence administrative d'une entreprise.

## Étapes

1. Dans **Clients**, sous **Ajouter un client**, cliquez sur **+**.
2. À **Ce client est il un particulier ?**, choisissez **Non**.
3. Dans **Rechercher un SIRET**, renseignez **Entrer le SIRET** : exactement
   quatorze chiffres. Cliquez sur **Suivant** pour lancer la recherche.
   **Annuler** ferme cette fenêtre sans ajout.
4. La suite dépend du résultat :
   - Si aucune entité n'est renvoyée par la recherche, **Ajouter un client**
     s'ouvre avec **Siret du client** prérempli. Renseignez **Nom du client**,
     **Email du client**, **Téléphone du client** et, si utile, **Code du client**.
     Cliquez sur **Enregistrer**, ou sur **Annuler** pour abandonner.
   - Si la fenêtre **Partenaire existant** apparaît, vérifiez les informations
     affichées : nom, e-mail, téléphone et SIRET. **Non** annule l'ajout avec
     **Ajout annulé**. **Oui** déclenche directement l'ajout comme client ; il
     n'ouvre pas une étape de correction avant enregistrement.
5. Après **Ajout du client réussi.** pour le formulaire, ou
   **Client ajouté avec succès !** après acceptation de la fiche trouvée,
   recherchez le client et vérifiez le résultat.

## Contrôles et limites

- La recherche exige un SIRET non vide de quatorze chiffres. Les erreurs sont
  **🚩 Numéro SIRET incorrect** si vide et **🚩 Numéro SIRET invalide** si le format
  est incorrect. Aucun contrôle de clé SIRET n'est établi dans ce validateur.
- Dans le formulaire qui suit une recherche sans résultat, le SIRET reste
  modifiable et peut être vidé : s'il est renseigné, le formulaire exige
  quatorze chiffres. Cette tolérance du formulaire ne permet pas de sauter la
  recherche initiale, qui exige un SIRET.
- Le nom, l'e-mail et le téléphone sont obligatoires. Le téléphone doit avoir
  dix chiffres et commencer par 01 à 09 ; seuls les chiffres sont saisis.
  Les messages sont **🚩 Texte non valide**,
  **🚩 Veuillez entrer une adresse email valide** et
  **🚩 Numéro de mobile non valide**. **Code du client** est optionnel.
- Malgré le titre **Partenaire existant**, la recherche API porte sur une
  entité par SIRET et n'établit pas qu'elle est partenaire du réseau courant.
  Vérifiez son identité ; le titre seul n'est pas une preuve de ce statut.
- L'API refuse un SIRET déjà associé au type client dans le réseau demandé
  avec un conflit 409 : `An entity with the same siret and type already exists`.
  Si l'entité existe avec un autre type, l'API peut réutiliser cette entité et
  lui ajouter le type client ; ne présumez pas qu'une fiche indépendante est
  créée ni que toutes ses informations seront recopiées ou remplacées.
- Une erreur de recherche (**Erreur lors de la recherche : …**) ne prouve pas
  l'absence du client. Un échec d'ajout peut afficher
  **Erreur lors de l’ajout du client** ou
  **Erreur lors de l'ajout du client : …**. Vérifiez les données avant toute
  nouvelle tentative ; ne répétez pas automatiquement l'ajout.

Complétez ensuite l'[adresse du client](renseigner-adresse-client.md) avant
facturation. Les opérations propres aux partenaires ne font pas partie de
cette fiche.

## Portée de l'aide Néo

Néo guide en lecture seule ; il ne lance ni recherche SIRET ni création pour
vous. Pour une recette documentaire, ouvrez **Rechercher un SIRET** puis
**Annuler**, sans cliquer sur **Suivant**.

Vérification au 30 octobre 2026 : chaîne interface, repository et API lue.
Recherche effective, résultat affiché et enregistrement réel non testés.
