# Supprimer un paiement d'une commande

## Objectif

Retirer un paiement enregistré sur une commande, lorsque la suppression est
autorisée, puis vérifier les paiements restants.

## Étapes

1. Ouvrez **Commandes**, retrouvez la commande, puis choisissez
   **Gestion → Paiements** sur sa ligne.
2. Attendez le chargement. Identifiez précisément le paiement avec les colonnes
   **Date**, **Méthode**, **Montant** et **Compte** lorsque cette dernière est
   affichée. Vérifiez que vous êtes sur la bonne commande.
3. Dans la colonne **Action** de cette ligne, cliquez sur l'icône de corbeille
   rouge, dont l'infobulle est **Supprimer le paiement**.
4. La fenêtre **Supprimer un paiement** rappelle le montant et la date du
   paiement. Relisez-les. Cliquez sur **Annuler** pour revenir sans suppression,
   ou sur **Supprimer** uniquement si vous souhaitez réellement retirer ce
   paiement.
5. Après confirmation, attendez le résultat. Le message **Paiement supprimé avec
   succès.** annonce le succès. Vérifiez la disparition de la bonne ligne et
   l'actualisation de **Montant payé:** dans la fenêtre **Paiements**.
6. Cliquez sur **Fermer** pour revenir à la liste des commandes, qui se recharge
   après une modification.

## Refus lié aux écritures comptables

La suppression peut être refusée après génération d'écritures comptables. Le
message est alors : **Impossible de supprimer ce paiement : les écritures
comptables ont déjà été générées.**

La corbeille peut rester visible alors que cette règle interdit la suppression.
Sa présence ne garantit donc pas que l'opération sera autorisée. En cas de refus,
signalez la situation à votre interlocuteur Tribuneo ; cette fiche ne décrit
aucun contournement du contrôle comptable.

## Autres messages et résultat incertain

| Message ou situation | Action |
|---|---|
| « Paiement introuvable. » | Fermez puis rouvrez Paiements pour vérifier la liste actuelle : le paiement peut déjà avoir été retiré. |
| « Erreur lors de la suppression du paiement. » ou réponse incertaine | Contrôlez le tableau en rouvrant la fenêtre avant de recommencer ; le message ne prouve pas que le paiement est toujours présent. |
| Ligne absente ou tableau momentanément vide | Attendez le chargement, puis vérifiez à nouveau. Une erreur de lecture peut aussi donner un tableau vide. |

Si la ligne ou le cumul restent incohérents, arrêtez les tentatives et signalez
le message avec la référence de la commande à votre interlocuteur Tribuneo.
Ne supprimez pas un autre paiement pour compenser une erreur supposée.

## Portée de l'action

Il s'agit de retirer un enregistrement du back-office, pas d'effectuer un
remboursement bancaire. La suppression du paiement ne supprime pas la commande
ni sa facture. Les montants payés sont recalculés et la commande peut redevenir
non soldée. Cette fiche ne décrit pas la suppression de commande, de facture ou
d'écriture comptable.

## Avec Néo

Demandez : « Comment supprimer un paiement d'une commande dans le back-office ? »
Néo peut expliquer cette procédure et le refus comptable documenté. L'utilisateur
effectue l'action dans l'interface ; Néo ne supprime aucun paiement.

Pour vérifier les paiements réels dans le chat, identifiez la commande et
demandez leur consultation. Une liste vide ou une lecture en erreur ne doit pas
être présentée comme une preuve de suppression réussie.
