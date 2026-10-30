# Statistiques : Toutes les infos partenaires

## Objectif

Extraire en un tableau les informations administratives, bancaires et
comptables des partenaires du réseau, avec le montant de leur fonds. Le
parcours commun est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Toutes les infos partenaires**.
2. Faites défiler horizontalement : le tableau compte seize colonnes. Il
   affiche dix lignes par page, trié par nom.
3. Cliquez sur **Exporter en CSV** : fichier `toutes_les_infos_partenaires.csv`.

Ce rapport n'a ni période ni filtre.

## Colonnes

| Écran | En-tête CSV | Contenu |
|---|---|---|
| **Code** | `code` | Code de la fiche. |
| **Nom** | `nom` | Nom du partenaire. |
| **Email** | `email` | E-mail de la fiche. |
| **Siret** | `siret` | SIRET enregistré. |
| **Téléphone** | `tel` | Téléphone de la fiche. |
| **Accepte démat.** | `accepte_demat` | `oui` ou `non`. |
| **Adresse** | `rue` | Rue de l'adresse enregistrée. |
| **Code postal** | `code_postal` | Code postal. |
| **Ville** | `ville` | Ville. |
| **Pays** | `pays` | Pays. |
| **IBAN** | `iban` | IBAN complet enregistré. |
| **BIC** | `bic` | BIC enregistré. |
| **N° TVA intracommunautaire** | `num_intracom` | Numéro de TVA enregistré avec les coordonnées bancaires. |
| **Code NAF** | `code_naf` | Code NAF enregistré avec les coordonnées bancaires. |
| **N° comptable** | `numero_compta` | Numéro comptable du partenaire dans le réseau. |
| **Montant** | `solde` | Montant actuel du fonds du partenaire, suivi de « € » à l'écran comme dans le CSV. |

## Qui figure dans la liste

Un partenaire apparaît s'il est propriétaire d'un lien actif avec le réseau
et s'il possède à la fois une adresse, des coordonnées bancaires, des
informations comptables et un code. Une fiche à qui l'un de ces éléments
manque n'apparaît pas. Le nombre total annoncé par la pagination ne tient pas
compte de ces conditions : les dernières pages peuvent être vides ou
incomplètes. Une fiche ayant plusieurs adresses ou coordonnées bancaires peut
apparaître plusieurs fois.

## Lecture et limites

- **IBAN** et **BIC** sont affichés et exportés en clair. Aucun masquage n'est
  appliqué : protégez ce fichier.
- **Montant** est un état au moment de la lecture. Ce n'est ni le montant du
  prochain virement, ni une somme due établie. Pour les remboursements, voir
  [Consulter les demandes de remboursement](consulter-demandes-remboursement.md).
- Un partenaire absent n'est pas forcément inconnu ou désactivé : vérifiez
  ses informations avec
  [Rechercher et consulter un partenaire](rechercher-consulter-partenaire.md),
  puis complétez si nécessaire l'[adresse](renseigner-adresse-partenaire.md)
  ou les [coordonnées bancaires](renseigner-coordonnees-bancaires-partenaire.md).
- Ce rapport ne permet pas d'établir qu'une fiche est active.

## Avec Néo

Demandez : « Quelles colonnes contient l'export Toutes les infos
partenaires ? ». Néo décrit les colonnes ; il ne lit pas ce rapport et ne
communique aucun IBAN.
