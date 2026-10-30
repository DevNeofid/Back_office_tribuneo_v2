# Vérifier le solde et le statut payé d'une commande

## Objectif

Savoir si une commande est entièrement payée et, sinon, combien il reste à
payer, sans enregistrer ni supprimer de paiement.

## Lire le solde dans la liste des commandes

1. Ouvrez **Commandes** et retrouvez la commande, par exemple avec son numéro
   commercial : voir [Rechercher une commande](rechercher-commande.md).
2. Sur sa ligne, lisez **Payé**, le cumul des paiements enregistrés, et
   **Facturé**, le montant total de la commande.
3. Interprétez la couleur des deux montants :
   - **vert** : le cumul payé est égal au total, la commande est soldée ;
   - **rouge** : les deux montants sont différents.
4. S'il reste un montant à payer, calculez-le : **Facturé** moins **Payé**.
   La liste n'affiche pas directement de reste à payer.

## Contrôler le détail dans la fenêtre Paiements

1. Sur la ligne de la commande, ouvrez **Gestion → Paiements**.
2. Attendez le chargement, puis lisez les paiements et la ligne **Montant
   payé:**, qui présente le cumul des paiements puis le total de la commande.
3. Lorsque le cumul atteint le total, la zone d'ajout d'un paiement n'est plus
   affichée.
4. Cliquez sur **Fermer**, sans rien saisir. Le détail de cette fenêtre est
   décrit dans [Consulter les paiements d'une commande](consulter-paiements-commande.md).

## Interpréter le résultat

- **Rouge** ne distingue pas une commande sans paiement d'une commande
  partiellement payée : lisez le montant **Payé**.
- Si **Payé** dépasse **Facturé**, le total de la commande a pu être diminué
  après l'enregistrement de paiements. Ne corrigez pas l'écart au hasard :
  vérifiez les paiements et les lignes de la commande, puis signalez l'écart à
  la personne qui gère les encaissements.
- Le solde ne renseigne pas sur la facture. Une commande soldée peut ne pas
  être facturée, et une commande facturée peut rester à payer. Le titre de la
  colonne **Facturé** ne prouve pas qu'une facture existe.
- La liste est chargée à l'ouverture de l'écran. Après un paiement enregistré
  sur un autre poste, rechargez la page avant de conclure.
- Un tableau de paiements vide ou un cumul à zéro peut aussi venir d'une
  erreur de chargement. Fermez puis rouvrez **Paiements** avant de conclure à
  l'absence de paiement.

## Avec Néo

Demandez : « Comment savoir si une commande est soldée dans le back-office ? »
pour obtenir cette procédure.

Pour lire les données réelles dans le chat, donnez le numéro commercial :
« La commande [numéro] est-elle soldée ? » ou « Combien reste-t-il à payer sur
la commande [numéro] ? ». Néo lit en lecture seule le total, le montant payé, le
reste à payer et un indicateur « payée ».

Cet indicateur est un état enregistré séparément : il est mis à jour lors de
l'enregistrement ou de la suppression d'un paiement, mais pas lors d'une
modification du total de la commande. Si l'indicateur et les montants ne
concordent pas, fiez-vous aux montants et à la fenêtre **Paiements**, puis
signalez l'écart. Néo n'enregistre ni ne supprime aucun paiement.
