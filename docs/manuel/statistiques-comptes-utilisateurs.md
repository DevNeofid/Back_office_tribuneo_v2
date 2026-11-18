# Statistiques : Comptes utilisateurs

## Objectif

Lister les comptes utilisateurs rattachés au réseau qui possèdent un
porte-monnaie consommateur, avec le montant de ce porte-monnaie au moment de
la lecture. Le parcours commun (menu, pagination, export) est décrit dans
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

## Étapes

1. Ouvrez **Statistiques** ; **Comptes utilisateurs** est le rapport affiché
   par défaut. Sinon, cliquez dessus dans le catalogue des rapports à gauche,
   groupe **UTILISATEURS**.
2. Lisez le tableau, dix lignes par page, trié du montant le plus élevé au
   plus faible. Les téléphones sont masqués par défaut : cliquez sur
   **Afficher les numéros** pour les voir en entier.
3. Pour obtenir toutes les lignes, cliquez sur **Exporter en CSV** : fichier
   `comptes_utilisateurs.csv`.

Ce rapport n'a ni période ni filtre.

## Colonnes

| Écran | En-tête CSV | Définition |
|---|---|---|
| **Téléphone** | `mobile` | Mobile enregistré sur le compte utilisateur, masqué par défaut à l'écran (**Afficher les numéros**), complet dans le CSV. |
| **Initiales** | `initials` | Première lettre du prénom puis du nom, en majuscules, dans un petit carré. |
| **Montant coupon** | absent du CSV | Barre de valeur : sa longueur est proportionnelle au plus gros montant de la page affichée, dont la barre est orange. |
| **€** | `montant` | Montant actuel du porte-monnaie consommateur du compte dans ce réseau, deux décimales, sans symbole (par exemple 2 300,00). |

L'ancienne colonne **Montant coupon (€)** est désormais séparée en deux : la
barre **Montant coupon** et le montant chiffré dans la colonne **€**.

## Lecture et limites

- Une ligne correspond à un lien entre un compte et le réseau, avec son
  porte-monnaie consommateur. Le rapport n'affiche ni nom complet ni e-mail :
  les initiales ne suffisent pas à identifier une personne.
- Le montant est un état au moment de la lecture, pas un cumul sur une
  période ni le détail des bons. Pour les bons d'une personne, utilisez
  [Statut des QR codes par client](statistiques-statut-qr-codes-client.md).
- La requête ne filtre pas les comptes ou liens supprimés : ce rapport ne
  permet pas d'établir qu'un compte est actif.
- Un montant à zéro ou une personne absente ne prouvent pas à eux seuls
  qu'aucun bon ne lui a été attribué.
- Le fichier contient des téléphones : traitez-le comme une donnée personnelle.

## Avec Néo

Demandez : « Que contient le rapport Comptes utilisateurs ? ». Néo explique
les colonnes ; il ne lit pas ce rapport et ne l'exporte pas.
