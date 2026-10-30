# Ajouter un partenaire ou reprendre une entité existante

## Objectif et prérequis

Inscrire un commerce comme partenaire du réseau courant depuis **Partenaires**,
écran **Liste des magasins partenaires**. Munissez-vous de son SIRET (14
chiffres), de son nom, de son e-mail et de son téléphone. Disposez des droits
d'administration du réseau.

L'ajout commence toujours par une recherche du SIRET dans les entités déjà
connues de Tribuneo. Selon le résultat, vous créez une nouvelle fiche ou vous
reprenez l'entité trouvée pour lui donner le rôle partenaire dans ce réseau.

## Étapes

1. Sous **Ajouter un partenaire**, cliquez sur le bouton orange **+**.
2. La boîte **Rechercher un SIRET** s'ouvre. Saisissez le SIRET dans
   **Entrer le SIRET** (chiffres seulement, 14 au maximum), puis cliquez sur
   **Suivant**. **Annuler** ferme sans rien créer ; un clic à l'extérieur ne
   ferme pas cette boîte.
3. Si aucune entité n'a ce SIRET, le formulaire **Ajouter un partenaire**
   s'ouvre avec le SIRET prérempli. Passez à « Nouvelle fiche ».
4. Si une entité existe déjà, la boîte **Partenaire existant** affiche :
   **Un partenaire existe déjà avec ce numéro de SIRET, voulez-vous vous en servir ?**
   avec son nom, son e-mail, son téléphone et son SIRET. Passez à « Reprise ».

### Nouvelle fiche

1. Renseignez **Nom du partenaire**, **Email du partenaire**,
   **Siret du partenaire** et **Téléphone du partenaire**.
2. **Code du partenaire** est facultatif : il peut servir à identifier le
   partenaire dans vos systèmes internes. Sans code, l'API en génère un.
3. Cochez **Accepte la dématérialisation** si c'est le cas ; la case est
   décochée par défaut.
4. Cliquez sur **Enregistrer**. **Annuler** ferme sans créer.
5. Le message **Inscription du partenaire réussie** confirme l'ajout ; la liste
   se recharge ensuite.

### Reprise d'une entité existante

- **Oui** demande le rôle partenaire pour l'entité trouvée, avec ses
  informations actuelles. Le message attendu est
  **Partenaire ajouté avec succès !**.
- **Non** abandonne et affiche **Ajout annulé**. Aucune donnée n'est envoyée.

L'entité trouvée peut être un client de ce réseau ou une entité d'un autre
réseau : la recherche ne filtre ni par rôle ni par réseau, malgré le titre
**Partenaire existant**. La reprise ne modifie pas son nom, son e-mail ni son
téléphone ; elle ne recopie pas de code saisi, puisqu'aucun code n'est demandé.

## Contrôles du formulaire

| Champ | Message affiché |
| --- | --- |
| SIRET vide | **🚩 Numéro SIRET incorrect** |
| SIRET autre que 14 chiffres | **🚩 Numéro SIRET invalide** |
| Nom vide | **🚩 Texte non valide** |
| E-mail vide ou mal formé | **🚩 Veuillez entrer une adresse email valide** |
| Téléphone autre que 10 chiffres commençant par 01 à 09 | **🚩 Numéro de mobile non valide** |

Le contrôle du SIRET porte sur le format, pas sur son existence au registre :
aucune vérification externe n'est faite.

## Ce que l'ajout crée

Pour un partenaire nouveau dans le réseau, l'API enregistre le rôle partenaire,
un code (saisi ou généré ; un autre code peut être généré si l'enregistrement du
premier échoue), un compte d'application commerçant s'il n'en existe pas, son
solde Tribuneo dans le réseau et son rattachement au réseau. Le compte créé
n'est pas utilisable tant que la première connexion n'a pas été faite :
voir [Donner accès à l'application à un partenaire](donner-acces-application-partenaire.md).

Adresse, informations bancaires et secteurs ne sont pas demandés ici. Complétez
ensuite [l'adresse](renseigner-adresse-partenaire.md),
[les coordonnées bancaires](renseigner-coordonnees-bancaires-partenaire.md) et
[les secteurs d'activité](attribuer-secteurs-partenaire.md).

## Erreurs et vérifications

- Un SIRET déjà partenaire dans ce réseau est refusé par l'API avec
  `An entity with the same siret and type already exists`.
- Un SIRET manquant est refusé avec
  `Missing required fields: name, type, email, phone, siret`.
- Les échecs s'affichent sous la forme **Erreur lors de l’inscription : …**
  (nouvelle fiche), **Erreur lors de l'ajout du partenaire : …** (reprise) ou
  **Erreur lors de la recherche : …** (recherche du SIRET).
- Une partie de l'ajout peut être enregistrée avant une erreur, notamment
  quand la création du solde ou du rattachement échoue. Avant toute nouvelle
  tentative, recherchez le partenaire par son nom dans la liste, puis refaites
  la recherche par SIRET ; ne créez pas de doublon.

Le bouton **Importer des commerçants** ouvre un import assisté distinct, qui
n'est pas décrit dans cette fiche.

## Portée de l'aide Néo

Néo explique l'ajout ; il ne crée ni ne reprend aucun partenaire et ne vérifie
pas un SIRET auprès d'un registre.

Vérification au 30 octobre 2026 : bouton, boîte de recherche SIRET, formulaire,
validateurs, repository et actions API de recherche et de création lus. Ajout
réel, reprise réelle, messages en session et import de commerçants non testés.
