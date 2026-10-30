# Retélécharger un fichier d'écritures comptables

## Objectif et prérequis

Récupérer le ZIP d'un lot déjà enregistré dans l'historique, sans déclencher
une nouvelle période. Il faut un accès administrateur du réseau et des
écritures comptables activées ; l'API contrôle encore l'activation pour lire
l'historique et télécharger un ancien fichier.

## Étapes

1. Ouvrez **Écritures**, qui affiche **Écritures comptables**.
2. Dans l'historique, identifiez le lot à partir de **Nom du fichier** et
   **Date de création**. Le nom enregistré est normalement
   `ECRITURES_<début>_<fin>.zip`. La date de création affichée est celle du lot,
   pas la fin de sa période. Le tableau présente dix lignes par page ; utilisez
   sa pagination pour parcourir les lots précédents.
3. Dans **Actions**, cliquez sur l'icône dont l'infobulle est **Télécharger**
   sur la bonne ligne. N'utilisez pas **Déclencher les écritures comptables**
   pour récupérer un fichier existant.
4. Attendez le fichier portant le nom de la ligne. Le texte d'attente est
   **Génération des écritures comptables...**, même pour ce retéléchargement.
   Ce libellé ne signifie pas qu'une nouvelle période est produite.

## Ce que fait cette action

La consultation charge la liste des lots, classés par identifiant décroissant.
Le téléchargement lit le ZIP déjà présent sur le serveur pour l'identifiant
de la ligne. Dans l'action API lue, il ne recalcule pas les écritures, ne crée
pas de lot, ne met pas à jour `downloaded_date` et ne change pas le seuil de
suppression des paiements. Le BO recharge le tableau après réception des octets.

Le nom initial imposé par le BO lors d'une génération peut être plus court,
`ECRITURES_<veille>.zip`. Le retéléchargement reprend le nom enregistré avec
les deux bornes. Cette différence ne suffit pas à conclure à un lot différent.

## Difficultés

| Situation | Vérification utile |
|---|---|
| Tableau vide ou ligne non visible | Attendez le chargement et vérifiez les pages. Le repository peut rendre une liste vide en cas d'erreur : cela ne prouve pas qu'aucun lot n'existe. |
| **Aucune écritures comptables disponibles.** | Message générique du BO en cas d'échec de téléchargement, y compris si un lot existe. Notez son nom et sa date et signalez le problème à Neofid si le fichier reste inaccessible. |
| Fichier supprimé ou inaccessible sur le serveur | L'API peut répondre `Accounting entry file not found.` ou `Unable to open accounting entry file.` ; ces détails ne sont pas nécessairement visibles dans le BO. Aucun bouton de reconstruction d'un ancien ZIP n'est établi. |
| Pas de ZIP après une tentative de génération | Relisez l'historique avant tout nouveau déclenchement ; la génération peut avoir été enregistrée malgré l'échec du téléchargement. |

L'historique n'offre ici ni filtre de dates, ni sélection de période à
recalculer, ni suppression de lot. Les bornes précises et la seconde incluse
avant le début annoncé sont détaillées dans
[Générer les écritures comptables](generer-ecritures-comptables.md).

## Avec Néo

Néo explique comment retrouver et retélécharger un lot dans le BO. Il ne lit
pas cet historique par un outil métier dédié, ne télécharge pas le ZIP et ne
recrée pas un fichier absent.
