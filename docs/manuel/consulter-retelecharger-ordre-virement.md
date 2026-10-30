# Consulter et retélécharger un ordre de virement

## Objectif

Retrouver les ordres de virement déjà générés et récupérer de nouveau leur
ZIP, par exemple si le téléchargement initial a été perdu. L'écran est le
menu **Virements**, titré **Historique d'ordres de virement bancaire**.

## Lire l'historique

Le tableau affiche dix ordres par page, le plus récent en premier :

| Colonne | Contenu |
| --- | --- |
| **Nom du fichier** | Nom du ZIP de l'ordre |
| **Frais de gestion** | Total des frais de gestion TTC retenus par cet ordre |
| **Montant remboursé** | Total net viré aux commerçants par cet ordre |
| **Compte** | Compte payeur ; colonne présente seulement si le réseau a plusieurs comptes |
| **Date de création** | Date de génération |
| **Actions** | Deux icônes : ordre de virement et documents |

Pour un ordre ancien sans compte enregistré, la colonne **Compte** affiche le
compte par défaut du réseau ; pour un compte supprimé, son code brut.

Le tableau ne montre ni le détail des demandes payées, ni la transmission du
fichier à la banque, ni l'exécution du virement. Un tableau vide peut venir
d'une erreur de lecture : il ne prouve pas l'absence d'ordre.

## Retélécharger le ZIP de l'ordre

1. Ouvrez **Virements** et repérez la ligne par sa date et son nom.
2. Cliquez sur l'icône de téléchargement, info-bulle
   **Télécharger l'ordre de virement**.
3. Patientez pendant **Téléchargement de l'ordre de virement...**. Le
   navigateur enregistre le ZIP sous le nom de la colonne
   **Nom du fichier**.

Le ZIP est celui conservé sur le serveur lors de la génération : même
fichier `.TXT.SCT`, même récapitulatif `.xlsx` et, le cas échéant, même
`REMBOURSEMENTS_ECARTES.csv`. Le retéléchargement ne régénère rien, ne
modifie aucun montant et ne paie aucune demande une seconde fois dans
Tribuneo.

Comme il s'agit du même fichier de virement, vérifiez qu'il n'a pas déjà été
transmis à la banque avant de le transmettre de nouveau.

En cas d'échec, le message est
**Erreur lors de la génération des ordres de virement.**, bien qu'il s'agisse
d'un simple téléchargement. Il peut signifier que le fichier n'est pas
disponible sur le serveur ; ne générez pas un nouvel ordre pour le remplacer
et contactez le support.

## Documents des demandes payées

La seconde icône, **Documents (justificatifs et factures)**, télécharge les
justificatifs et factures de frais des demandes payées par cet ordre. Voir
[Consulter le justificatif d'une demande de remboursement](consulter-justificatif-remboursement.md).

## Portée de l'aide Néo

Néo explique l'historique ; il ne télécharge ni ne génère aucun fichier et ne
peut pas confirmer qu'un ordre a été transmis ou exécuté.

Vérification au 30 octobre 2026 : menu, tableau, deux actions, repository et
actions API de liste et de téléchargement lus. Aucun téléchargement réel ;
noms de fichiers des ordres antérieurs au 14 octobre 2026 non vérifiés.
