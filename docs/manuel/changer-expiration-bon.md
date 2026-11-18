# Changer la date d'expiration d'un bon individuel

## Objectif et prérequis

Modifier la date d'un seul bon non désactivé, avec les droits d'administration
du réseau. Pour changer toute la commande et ses bons, utilisez la procédure
distincte [Changer la validité d'une commande](changer-validite-commande.md).
Un changement global ultérieur peut remplacer la date choisie individuellement.

## Étapes

1. Ouvrez **Commandes**, retrouvez la commande, puis choisissez
   **Gestion → Gestion des bons** : le panneau **Bons de la commande** s'ouvre.
2. Repérez précisément le bon par son numéro (colonne **Bon**) et vérifiez sa
   colonne **Expiration** : voir [Consulter les bons](consulter-bons-commande.md).
3. Dans la colonne **Action**, cliquez sur **…** (infobulle **Actions du bon**),
   puis sur **Modifier la date d'expiration** (icône calendrier). Ce choix est
   grisé pour un bon déjà désactivé, avec la mention **Bon déjà désactivé**.
4. Le calendrier **Date de validité** s'ouvre. Il propose au plus tôt demain et
   se positionne sur la date actuelle, ou sur demain si cette date est
   antérieure. La saisie au clavier utilise le format **JJ/MM/AAAA**.
5. Cliquez sur **Valider** pour envoyer le changement. **Il n'y a pas de
   confirmation supplémentaire.** Pour renoncer, cliquez sur **Annuler**.
6. Après **Date d'expiration mise à jour au …**, contrôlez la colonne
   **Expiration** dans le tableau rechargé, puis fermez le panneau avec
   ✕ **Fermer**.

## Règles appliquées

- La nouvelle date est au plus tôt demain ; le serveur fixe la fin de validité
  à 23:59:59 le jour choisi.
- Un bon non désactivé peut être prolongé même s'il est attribué, déjà expiré
  ou rattaché à une commande facturée.
- Avancer la date est refusé pour un bon attribué à un compte consommateur.
  Pour un bon non attribué, la nouvelle date doit rester au minimum demain.
- Le serveur recalcule le solde du porte-monnaie consommateur concerné après
  le changement. Si un ajustement est retourné, le message ajoute
  **Le solde du consommateur a été mis à jour (… → …).** Ce complément peut
  être absent, par exemple si le solde n'a pas changé.
- La date globale de la commande n'est pas modifiée par cette action individuelle.

## Messages et difficultés

| Message | Suite utile |
|---|---|
| **Ce bon est déjà attribué : sa date peut seulement être prolongée.** | Choisissez une date égale ou postérieure à son expiration actuelle. |
| **La date doit être au plus tôt demain.** | Rouvrez le calendrier et choisissez à partir de demain. |
| **Date invalide.** | Choisissez de nouveau une date valide. |
| **Ce bon a été annulé.** | Rouvrez la liste pour vérifier la désactivation. |
| **Introuvable. Rechargez la page.** | Rechargez puis retrouvez le bon avant de poursuivre. |
| **Vous n'avez pas accès à cette ressource.** | Faites vérifier vos droits auprès de votre interlocuteur Tribuneo. |
| **Erreur lors de la mise à jour de la date d'expiration.** | Rouvrez la liste et contrôlez la date avant de réessayer : le changement peut avoir été enregistré avant une erreur ultérieure. |

## Écran et aide Néo

Panneau **Bons de la commande** (anciennement **Gestion des bons - Commande …**),
calendrier ouvert depuis le menu **…** de la ligne du bon. Demandez à Néo : « Comment prolonger un seul bon de commande ? ».
Néo explique le parcours et les refus ; il ne change aucune date et ne lit pas
le détail de ces bons avec ses outils actuels.
