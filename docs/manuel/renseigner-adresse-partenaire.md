# Renseigner l'adresse d'un partenaire

## Objectif et prérequis

Ajouter ou corriger l'adresse postale et, si besoin, les coordonnées GPS d'un
partenaire depuis **Partenaires**, écran **Liste des magasins partenaires**.
Identifiez d'abord la fiche et consultez l'onglet **Adresse**.

L'adresse est rattachée à l'entité : si elle est aussi cliente ou partenaire
d'un autre réseau, c'est la même adresse qui y est utilisée.

## Étapes

1. Sur la carte, ouvrez l'icône d'édition (**Menu Edition**), puis
   **Editer l'adresse**.
2. Le BO choisit seul entre ajout et modification : sans adresse enregistrée,
   le formulaire est vide ; sinon il est prérempli. Dans les deux cas, son
   titre est **Indiquer l'adresse de ce commerçant**.
3. Renseignez **Adresse**, **Code postal**, **Ville** et **Pays**.
4. **Latitude** et **Longitude** sont facultatives. Saisissez-les avec un point
   comme séparateur décimal, par exemple `44.09` (valeur fictive).
5. Cliquez sur **Enregistrer**. Les messages de réussite sont
   **Ajout de l'adresse réussi** ou **Modification de l'adresse réussie**.
6. Contrôlez l'onglet **Adresse** : **Localisation:** et **Coordonnées GPS:**,
   avec **Non renseigné** pour une coordonnée absente.

Le formulaire n'a pas de bouton **Annuler** ; fermez-le par un clic à
l'extérieur pour abandonner. Ce mode de fermeture n'a pas été vérifié en session.

## Contrôles du formulaire

| Champ | Message |
| --- | --- |
| Adresse, Ville ou Pays vide | **🚩 Texte non valide** |
| Code postal vide | **Entrez un code postal** |
| Code postal autre que 5 chiffres | **Entrez un code postal valide** |
| Latitude ou longitude mal formée | **🚩 Entrez une position valide** |

Le contrôle des coordonnées n'accepte que des chiffres avec un point
facultatif : une virgule ou une valeur négative (par exemple une longitude à
l'ouest de Greenwich) est refusée. L'API ne refait aucun contrôle de ces champs.

## Utilité pour les remboursements

Le code de remboursement considère l'adresse d'un commerçant comme incomplète
si la rue, le code postal ou la ville manquent ; le pays et les coordonnées GPS
ne font pas partie de ce contrôle. L'écran **Prochain virement** affiche alors
le motif **Adresse du commerçant incomplète**. Le cycle de remboursement n'est
pas décrit ici.

## Erreurs et vérifications

Les échecs affichent **Erreur lors de l'ajout de l'adresse** ou
**Erreur lors de la modification de l'adresse**, sans la cause. Avant de
recommencer un ajout, rouvrez **Partenaires** et vérifiez l'onglet **Adresse** :
l'API n'empêche pas l'enregistrement d'une seconde adresse pour la même entité.

## Portée de l'aide Néo

Néo explique la saisie ; il n'enregistre aucune adresse.

Vérification au 30 octobre 2026 : menu, deux formulaires, validateurs,
repository, actions API, table des adresses et contrôle des prérequis de
remboursement lus. Enregistrement réel et fermeture sans sauvegarde non testés.
