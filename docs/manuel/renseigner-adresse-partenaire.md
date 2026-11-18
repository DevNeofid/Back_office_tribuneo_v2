# Renseigner l'adresse d'un partenaire

## Objectif et prérequis

Ajouter ou corriger l'adresse postale et, si besoin, les coordonnées GPS d'un
partenaire depuis **Partenaires**, écran **Magasins partenaires**. Identifiez
d'abord la fiche, dépliez-la et consultez sa rubrique **ADRESSE**.

L'adresse est rattachée à l'entité : si elle est aussi cliente ou partenaire
d'un autre réseau, c'est la même adresse qui y est utilisée.

## Étapes

1. Sur la ligne du partenaire, cliquez sur le crayon **Modifier le partenaire**
   (anciennement **Menu Edition**), puis sur
   **Editer l'adresse**.
2. Le BO choisit seul entre ajout et modification : sans adresse enregistrée,
   le panneau est vide et sa rubrique est **AJOUTER L'ADRESSE** ; sinon il est
   prérempli et sa rubrique est **MODIFIER L'ADRESSE**. Dans les deux cas, le
   titre est le nom du partenaire (anciennement **Indiquer l'adresse**) et les
   champs sont dans la section **Adresse du magasin**.
3. Renseignez **Adresse**, **Code postal**, **Ville** et **Pays**.
4. **Latitude** et **Longitude** sont facultatives. Saisissez-les avec un point
   comme séparateur décimal, par exemple `44.09` (valeur fictive).
5. Cliquez sur **Enregistrer**. Les messages de réussite sont
   **Ajout de l'adresse réussi** ou **Modification de l'adresse réussie**.
6. Dépliez la fiche et contrôlez la rubrique **ADRESSE** : l'adresse, puis
   **Latitude** et **Longitude**, avec **Non renseigné** pour une coordonnée
   absente.

Pour abandonner, cliquez sur **Annuler** ou sur le bouton ✕ **Fermer** ; un
clic en dehors du panneau le ferme aussi sans enregistrer. Ce mode de
fermeture n'a pas été vérifié en session.

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
le motif **Adresse du commerçant incomplète**. Pour rendre la demande payable,
voir [Traiter les demandes de remboursement écartées](traiter-demandes-remboursement-bloquees.md).

## Erreurs et vérifications

Les échecs affichent **Erreur lors de l'ajout de l'adresse** ou
**Erreur lors de la modification de l'adresse**, sans la cause. Avant de
recommencer un ajout, rouvrez **Partenaires** et vérifiez la rubrique **ADRESSE** :
l'API n'empêche pas l'enregistrement d'une seconde adresse pour la même entité.

## Portée de l'aide Néo

Néo explique la saisie ; il n'enregistre aucune adresse.

Vérification au 30 octobre 2026 : menu, deux formulaires, validateurs,
repository, actions API, table des adresses et contrôle des prérequis de
remboursement lus. Enregistrement réel et fermeture sans sauvegarde non testés.

Libellés relus le 2 novembre 2026 : tranche 1 M15, sans changement de logique.
Recette visuelle et opérations en session non exécutées pour cette mise à jour.
