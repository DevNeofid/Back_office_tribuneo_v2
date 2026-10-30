# Changer la date de validité d'une commande

## Objectif

Changer en une seule opération la date de validité de toute une commande et de
tous ses bons, y compris lorsque la commande est déjà facturée.

## Portée de cette fiche

- Le changement s'applique à la commande (colonne **Expiration**) et à tous ses
  bons non annulés.
- Il remplace aussi les dates qui avaient été changées bon par bon.
- Le changement de date d'un seul bon se fait dans **Gestion des bons** ; cette
  procédure distincte n'est pas décrite ici.

## Étapes

1. Ouvrez **Commandes** et retrouvez la commande : voir
   [Rechercher une commande](rechercher-commande.md).
2. Dans la colonne **Edition**, ouvrez le menu de sa ligne et choisissez
   **Changer la date de validité**. Cette entrée est proposée même après
   facturation.
3. Un calendrier s'ouvre avec le titre **Date de validité de toute la
   commande**. Il est positionné sur la date actuelle de la commande, ou sur
   demain si cette date est antérieure à demain. Les dates antérieures à
   demain ne peuvent pas être choisies.
4. Choisissez la nouvelle date. L'icône en forme de crayon du calendrier permet
   aussi de saisir la date au format **Jour/Mois/Année**.
5. Validez le calendrier. **Aucune confirmation supplémentaire n'est
   demandée** : la date est envoyée dès la validation du calendrier. Pour
   renoncer, utilisez le bouton d'annulation du calendrier ou cliquez en dehors
   de celui-ci : rien n'est alors envoyé.
6. Le message **Mise à jour de la date de validité...** s'affiche pendant
   l'envoi. En cas de succès, le message **Date de validité mise à jour pour**
   indique le nombre de bons concernés, et la liste se recharge.
7. Contrôlez la colonne **Expiration** de la commande.

Pour une commande facturée, le formulaire **Edition → Modifier** propose aussi
un bouton **Changer la date de validité**, qui ouvre ce même calendrier.

## Règles

- La nouvelle date est au plus tôt demain. Les bons restent valables jusqu'à la
  fin de la journée choisie.
- **Prolonger** est toujours possible, même après facturation et même pour des
  bons attribués ou déjà expirés.
- **Avancer** la date n'est possible que si aucun bon attribué à un
  consommateur, par exemple scanné ou utilisé, ne verrait sa date avancée.
  Sinon, la demande est refusée en entier et aucune date n'est modifiée.
- Les bons annulés ne sont pas concernés.
- Pour les bons attribués, le solde des consommateurs concernés est recalculé
  après le changement.

## Messages et difficultés

| Message | Cause et action |
|---|---|
| « Date de validité mise à jour pour … bon(s). » | Changement effectué. Contrôlez la colonne **Expiration**. |
| « Impossible d'avancer la date : des bons sont déjà attribués à des consommateurs. On peut seulement la prolonger. » | Choisissez une date égale ou postérieure à la date actuelle des bons attribués. |
| « La date doit être au plus tôt demain. » | Choisissez une date à partir de demain, par exemple si la page est restée ouverte depuis la veille. |
| « Date invalide. » | Rouvrez le calendrier et choisissez de nouveau la date. |
| « Introuvable. Rechargez la page. » | La commande n'existe plus ou a été supprimée : rechargez la page. |
| « Vous n'avez pas accès à cette ressource. » | Votre compte n'a pas accès à cette opération ; adressez-vous à votre interlocuteur Tribuneo. |
| « Erreur lors de la mise à jour de la date de validité. » | Résultat incertain : rechargez la page et contrôlez **Expiration** avant toute nouvelle tentative. |

## Avec Néo

Demandez : « Comment changer la date de validité d'une commande ? » ou
« Pourquoi je ne peux pas avancer la date de validité de cette commande ? ».
Néo explique la procédure et les refus ; le changement est effectué par
l'utilisateur dans l'interface. Néo ne change aucune date. Le détail d'une
commande qu'il lit en lecture seule peut indiquer sa date de validité
enregistrée ; après un changement, contrôlez la colonne **Expiration**.
