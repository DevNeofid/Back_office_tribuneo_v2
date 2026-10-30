# Supprimer une commande

## Objectif

Retirer une commande de la liste lorsqu'aucun de ses bons n'a été attribué à un
consommateur, et comprendre pourquoi une suppression est refusée.

## Avant de supprimer

- Vérifiez le numéro commercial dans la colonne **N°** : la fenêtre de
  confirmation ne rappelle pas la commande concernée.
- La suppression est refusée dès qu'au moins un bon non annulé de la commande
  est attribué à un consommateur ou utilisé, par exemple après avoir été scanné.
- Les bons de la commande sont annulés en même temps qu'elle.
- Le back-office ne propose aucun écran pour restaurer une commande supprimée.
- Une commande dont la facture et les écritures comptables ont déjà été
  générées ne peut pas être supprimée. L'écran ne bloque pas ce cas de
  lui-même : vérifiez que la commande n'est pas facturée avant de confirmer
  (étape 2).

## Étapes

1. Ouvrez **Commandes** et retrouvez la commande : voir
   [Rechercher une commande](rechercher-commande.md).
2. Vérifiez qu'elle n'est pas facturée : dans la colonne **Edition**, choisissez
   **Modifier**. Si le bandeau **Cette commande est facturée** s'affiche, ne la
   supprimez pas. Dans tous les cas, cliquez sur **Fermer** sans enregistrer.
3. Dans la colonne **Edition**, ouvrez de nouveau le menu de sa ligne et
   choisissez **Supprimer**.
4. La fenêtre **Supprimer une commande** demande : « Êtes-vous sûr de vouloir
   supprimer cette commande ? ». **Annuler** ferme la fenêtre sans rien
   supprimer.
5. Cliquez sur **Supprimer** uniquement pour confirmer réellement la
   suppression, puis attendez le résultat : aucun indicateur d'attente n'est
   affiché pendant l'envoi.
6. En cas de succès, le message **Commande supprimée avec succès.** s'affiche,
   la fenêtre se ferme et la liste se recharge : la commande n'y figure plus.

## Comprendre un refus

En cas d'échec, le message est toujours :
**Erreur lors de la suppression de la commande, au moins un utilisateur a
scanné son bon sur cette commande.**

- La cause habituelle est un bon attribué ou utilisé. Pour le vérifier, ouvrez
  **Gestion → Gestion des bons** : l'infobulle de l'icône de désactivation d'un
  bon attribué indique **Bon associé à un utilisateur, désactivation
  impossible**. Fermez ensuite avec **Fermer**.
- Le même message s'affiche aussi pour d'autres échecs, par exemple une
  commande introuvable ou une erreur du serveur. Il ne prouve donc pas, à lui
  seul, qu'un bon a été scanné.
- Une commande refusée pour un bon attribué ne peut pas être supprimée. Selon
  le besoin, les bons non attribués d'une commande non facturée peuvent être
  retirés en diminuant les quantités : voir [Modifier une commande](modifier-commande.md).

## Difficultés

| Situation | Action |
|---|---|
| La fenêtre de confirmation reste affichée sans message après **Supprimer** | Cliquez sur **Annuler**, rechargez la page et vérifiez si la commande figure encore dans la liste avant toute nouvelle tentative. |
| La commande reste visible après le message de succès | Rechargez la page et recherchez-la de nouveau. |

## Avec Néo

Demandez : « Comment supprimer une commande ? » ou « Pourquoi je ne peux pas
supprimer cette commande ? ». Néo explique la procédure et la cause des refus ;
la suppression est effectuée par l'utilisateur dans l'interface. Néo ne supprime
aucune commande. Il peut aider à identifier la commande et vérifier en lecture
seule si une facture existe déjà pour elle, avant toute action.
