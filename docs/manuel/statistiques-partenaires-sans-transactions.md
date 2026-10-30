# Statistiques : Partenaires sans transactions

## Objectif

Repérer les partenaires du réseau, ayant déjà utilisé leur accès de première
connexion, pour lesquels un compte utilisateur rattaché n'a aucune
transaction enregistrée. Le parcours commun est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

## Étapes

1. Ouvrez **Statistiques**, puis choisissez **Partenaires sans transactions**.
2. Lisez le tableau, dix lignes par page, trié par nom.
3. Cliquez sur **Exporter en CSV** : fichier `partenaires_sans_activite.csv`.

Ce rapport n'a ni période ni filtre : toutes les transactions enregistrées,
quelle que soit leur date, sont prises en compte.

## Colonnes

| Écran | En-tête CSV | Définition |
|---|---|---|
| **Nom** | `nom` | Nom du partenaire. |
| **ID** | absent du CSV | Identifiant interne de la fiche partenaire. |
| **Email** | `email` | E-mail enregistré sur la fiche partenaire. |
| **Téléphone** | `tel` | Téléphone enregistré sur la fiche partenaire. |

La colonne **ID** n'est pas exportée : notez-la depuis l'écran si besoin.

## Définition retenue

Une fiche partenaire non supprimée, avec un lien actif vers le réseau,
apparaît lorsqu'au moins un de ses comptes rattachés n'est ni émetteur ni
destinataire d'aucune transaction, tous types confondus. Les partenaires
listés dans
[Partenaires jamais connectés](statistiques-partenaires-jamais-connectes.md)
sont exclus.

## Lecture et limites

- Si un partenaire a plusieurs comptes rattachés, il suffit qu'un seul n'ait
  aucune transaction pour qu'il apparaisse, même si un autre compte en a.
  Ce rapport ne prouve donc pas l'absence totale d'activité du commerce.
- Le rapport ne porte pas sur une période : un partenaire actif autrefois
  puis arrêté n'y figure pas.
- Une absence de transaction ne dit rien de la raison (accès non transmis,
  commerce fermé, refus des bons) et ne justifie pas à elle seule une
  désactivation.

## Avec Néo

Demandez : « Comment lire le rapport Partenaires sans transactions ? ». Néo
explique la définition ; il ne lit pas ce rapport.
