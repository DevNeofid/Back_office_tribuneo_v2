# Renseigner les coordonnées bancaires d'un partenaire

## Objectif et prérequis

Enregistrer ou corriger l'IBAN, le BIC et les informations comptables d'un
partenaire depuis **Partenaires**, écran **Liste des magasins partenaires**.
Ayez sous les yeux le RIB transmis par le commerçant et identifiez d'abord la
bonne fiche dans l'onglet **Informations bancaires**.

L'IBAN, le BIC et les champs du RIB sont rattachés à l'entité, donc communs à
ses autres rôles et réseaux. Le numéro comptable est propre au réseau courant.

## Étapes

1. Sur la carte, ouvrez l'icône d'édition (**Menu Edition**), puis
   **Editer informations bancaires**.
2. Sans informations existantes, le formulaire est vide et titré
   **Indiquer les informations bancaires de ce commerçant**. S'il en existe,
   il est prérempli et titré **Indiquer les informations bancaire de ce commerçant**.
3. Saisissez l'**Iban**. Les espaces sont ajoutés automatiquement tous les
   quatre caractères.
4. Lorsque l'IBAN complet est valide, **Code établissement**, **Code guichet**,
   **Numéro de compte** et **Clé RIB** sont remplis à partir de lui. Vérifiez-les
   avec le RIB ; ils restent modifiables.
5. Saisissez le **BIC**.
6. Complétez si besoin le numéro comptable et le numéro intracommunautaire
   (13 caractères au plus). Leurs libellés sont **Numéro de compte comptabilité**
   et **Numéro intracommunautaire** à l'ajout, **Numéro de comptabilité** et
   **Numéro intra communautaire** en modification.
7. Cliquez sur **Enregistrer**. Les messages de réussite sont
   **Informations bancaires ajoutées avec succès** ou
   **Modification des informations bancaires réussie**.
8. Contrôlez l'onglet **Informations bancaires** de la carte.

Le formulaire n'a pas de bouton **Annuler** ; fermez-le par un clic à
l'extérieur pour abandonner. Ce mode de fermeture n'a pas été vérifié en session.

## Contrôles

| Champ | Contrôle du formulaire |
| --- | --- |
| Iban vide | **🚩 IBAN requis** |
| Iban d'une autre longueur que 27 caractères sans espaces | **🚩 Numéro d'Iban invalide** |
| Iban de structure incorrecte | **🚩 Numéro IBAN invalide** |
| BIC vide (ajout) | **🚩 BIC requis** |
| BIC d'une autre longueur que 8 ou 11 caractères (ajout) | **🚩 BIC invalide (8 ou 11 caractères)** |
| BIC de structure incorrecte (ajout) | **🚩 Code BIC invalide** |
| BIC vide (modification) | **🚩 Texte non valide** |

Pendant la saisie, un IBAN complet peut aussi afficher
**🚩 Format d'IBAN invalide** ou **🚩 IBAN invalide (clé de contrôle incorrecte)**.
Ce second message n'empêche pas l'enregistrement : corrigez l'IBAN tant qu'il
apparaît. En modification, le format du BIC n'est pas contrôlé.

L'API n'accepte qu'un IBAN commençant par `FR` suivi de deux chiffres ; avec la
longueur imposée par le formulaire, seul un IBAN français peut être enregistré
par ce parcours. Elle refuse aussi un second jeu de coordonnées pour la même
entité.

## Utilité pour les remboursements

Le code de remboursement considère les coordonnées bancaires d'un commerçant
comme manquantes si l'IBAN ou le BIC est vide. L'écran **Prochain virement**
affiche alors **IBAN ou BIC du commerçant manquant**. Pour rendre la demande
payable, voir [Traiter les demandes de remboursement écartées](traiter-demandes-remboursement-bloquees.md).

## Erreurs et vérifications

Les échecs affichent **Erreur lors de l'ajout des informations bancaires** ou
**Erreur lors de la modification des informations bancaires**, sans la cause.
En modification, l'API peut enregistrer les coordonnées puis échouer en relisant
la fiche ; vérifiez l'onglet avant de recommencer. Effacer le numéro comptable
ne garantit pas sa suppression.

## Confidentialité et portée de l'aide Néo

L'IBAN apparaît en clair dans le BO. Ne le copiez pas dans une conversation ;
Néo n'en a pas besoin pour expliquer l'écran et masque les IBAN qu'il lit. Néo
ne saisit aucune coordonnée et n'effectue aucun virement.

Vérification au 30 octobre 2026 : menu, deux formulaires, validateurs, modèle,
repository, actions API et contrôle des prérequis de remboursement lus.
Enregistrement réel, refus API en session et fermeture sans sauvegarde non testés.
