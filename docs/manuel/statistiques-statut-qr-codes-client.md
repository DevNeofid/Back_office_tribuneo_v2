# Statistiques : Statut des QR codes par client

## Objectif

Retrouver les bons rattachés au compte d'un bénéficiaire, avec leur montant,
leur reste et leur expiration, à partir de son nom, prénom, e-mail ou mobile.
Le parcours commun est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

Malgré son intitulé, ce rapport ne recherche pas le client qui a passé la
commande : **Nom**, **Prénom**, **Email** et **Mobile** sont ceux du compte
utilisateur rattaché au bon, c'est-à-dire du bénéficiaire. Le commerçant
n'apparaît pas.

## Retrouver les bons d'un bénéficiaire

1. Ouvrez **Statistiques**, puis choisissez **Statut des QR codes par client**.
   Les champs **Nom**, **Prénom**, **Email** et **Mobile** apparaissent avec
   **Rechercher** et **Réinitialiser**.
2. Renseignez un ou plusieurs champs. L'e-mail complet est le critère le plus
   discriminant.
3. Cliquez sur **Rechercher**, ou appuyez sur Entrée dans l'un des champs.
   La saisie seule ne filtre pas le tableau.
4. Vérifiez sur chaque ligne les colonnes **Email** et **Mobile** : la
   recherche accepte une correspondance partielle et peut ramener d'autres
   personnes.
5. Lisez une ligne par bon, des commandes les plus récentes aux plus anciennes,
   dix lignes par page.
6. Pour tout exporter, cliquez sur **Exporter en CSV** : fichier
   `liste_qr_code_status.csv`.
7. **Réinitialiser** vide les quatre champs et relance aussitôt la liste sans
   filtre, c'est-à-dire tous les bons rattachés à un compte dans le réseau.

## Règles de recherche

- Chaque champ rempli doit correspondre : les critères se combinent. Un champ
  vide n'est pas pris en compte.
- Chaque valeur est recherchée comme une partie du champ enregistré : « dupo »
  retrouve aussi « Dupont » ou « Dupontel ». Les espaces au début et à la fin
  sont ignorés. La prise en compte des majuscules et des accents dépend de la
  base et n'est pas garantie.
- Les caractères `%` et `_` sont interprétés comme des jokers par la recherche.
- **Mobile** est converti au format international avant la recherche : les
  espaces et séparateurs sont retirés, `06…` devient `+336…`, `0033…` devient
  `+33…`. Une saisie partielle est acceptée. Un numéro sans indicatif est
  considéré comme français.

## Colonnes

| Écran | En-tête CSV | Définition |
|---|---|---|
| **Identifiant** | `identifiant` | Identifiant composé du réseau, du bon et de la commande, comme la colonne **ID** de la gestion des bons. |
| **N° de commande** | `numéro_de_commande` | Numéro de la commande du bon. |
| **Montant** | `montant` | Valeur du bon. |
| **Montant restant** | `montant_restant` | Reste enregistré sur le bon. |
| **Donation** | `donation` | **Oui** ou **Non**. |
| **Date d'expiration** | `date_expiration` | Expiration propre au bon : jj/mm/aaaa à l'écran, format brut de la base dans le CSV. |
| **Email**, **Prénom**, **Nom**, **Mobile** | `email`, `prenom`, `nom`, `mobile` | Coordonnées du compte utilisateur rattaché au bon. |

À l'écran, les montants sont suivis de €. Dans le CSV, ils sont repris au
format de la base, sans symbole.

## Lire le statut d'un bon

Le rapport ne calcule pas de statut. Lisez-le dans les colonnes :
**Montant restant** indique le reste enregistré, **Date d'expiration**
indique si le bon est expiré. Un reste positif ne garantit pas à lui seul que
le bon est encore utilisable. Les bons désactivés et ceux des
commandes supprimées n'apparaissent pas. Les bons qui ne sont rattachés à
aucun compte utilisateur, par exemple un bon pas encore attribué, n'apparaissent
pas non plus : une recherche sans résultat ne prouve pas qu'aucun bon n'a été
prévu pour cette personne.

## L'export suit les filtres appliqués

Le CSV contient toutes les lignes correspondant aux derniers filtres appliqués
par **Rechercher**, Entrée ou **Réinitialiser**, pas seulement la page
affichée. Un texte saisi sans avoir été validé n'est pas pris en compte :
cliquez sur **Rechercher** avant d'exporter. Sans filtre, l'export contient
les bons et coordonnées de tous les bénéficiaires du réseau ; aucun masquage
n'est appliqué.

## Ce que ce rapport n'est pas

- Ce n'est pas la liste des bons d'une commande : pour une commande précise,
  utilisez [Consulter les bons d'une commande](consulter-bons-commande.md) ou
  [Bénéficiaires (commande importée)](consulter-beneficiaires-commande-importee.md).
- Il ne génère ni QR code ni fichier de QR codes : voir
  [Générer et télécharger les QR codes d'une commande](generer-qr-codes-commande.md).
- Il ne modifie aucun bon. Pour agir sur un bon, passez par la gestion des
  bons de sa commande.

## Avec Néo

Demandez : « Comment retrouver les bons d'un bénéficiaire avec son e-mail ? ».
Néo explique la recherche et les colonnes ; il ne consulte pas ce rapport,
ne recherche pas la personne et n'exporte pas le fichier.
