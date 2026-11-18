# Consulter les demandes de remboursement des partenaires

## Objectif

Voir, avant un virement, quelles demandes de remboursement des partenaires
seront payées, pour quel montant, et lesquelles seront écartées. L'écran est
le menu **Prochain virement**, dans le groupe **FINANCE** du menu de gauche.
Une pastille orange « 1 » sur ce menu signale qu'au moins une demande est
prête à être payée ; elle disparaît quand vous ouvrez l'écran. À l'accueil, la
carte **PROCHAIN VIREMENT** et son bouton **Préparer le virement** y mènent
aussi.

## D'où viennent les demandes

Le back-office ne crée aucune demande : il n'existe pas de bouton pour le
faire. Une demande est créée côté partenaire, depuis l'application
commerçant, ou, si le partenaire a activé le remboursement automatique, par
un traitement du serveur prévu le samedi soir. Ces parcours ne sont pas
décrits dans ce manuel.

À la création, l'API retire du porte-monnaie du partenaire tout ce qui est
remboursable et peut lui envoyer une notification « Votre remboursement de …€
a été effectué. ». Cette notification n'indique **pas** qu'un virement a eu
lieu : la demande attend encore l'ordre de virement généré par le réseau.

## Étapes

1. Ouvrez **Prochain virement**.
2. Lisez la carte du haut : **PÉRIMÈTRE** (**Demandes faites jusqu'au
   JJ/MM/AAAA inclus**), **COMPTE PAYEUR** et quatre tuiles :
   **Demandes à payer**, **Commerçants**, **Montant à virer** et
   **Demandes écartées**.
3. Section **À payer** : une carte par commerçant (initiales, nom, code en
   dessous, nombre de demandes, net total). Cliquez sur la carte pour la
   déplier ou la replier.
4. Pour chaque demande dépliée : **Date**, **Numéro**, **Montant**, **Frais**,
   **Net**, **Justificatifs** et **Action**. Dans **Justificatifs**, la
   pastille verte **Déjà émis**, avec l'info-bulle **Documents déjà émis**,
   indique que le justificatif et la facture de frais existent déjà ;
   **À émettre** indique qu'ils n'existent pas encore.
5. Section **Écartées** : **Date**, **Numéro**, **Commerçant**, **Montant**,
   **Motifs** (en pastilles) et **Actions**. Sans demande écartée, elle
   affiche **Aucune demande écartée**. Voir la fiche
   [Traiter les demandes de remboursement écartées](traiter-demandes-remboursement-bloquees.md).

Sans demande, l'écran affiche **Aucune demande de remboursement en attente.**
L'écran n'a ni recherche ni filtre.

## Période prise en compte

- Borne haute : **hier à 23:59:59, heure de Paris**. Une demande faite
  aujourd'hui n'apparaît que demain.
- Borne basse : la date de bascule configurée pour le réseau. Les demandes
  plus anciennes relevaient de l'ancien mécanisme et ne sont jamais reprises.
- Une demande reste proposée tant qu'elle n'a pas été payée par un ordre de
  virement, même si elle a été écartée lors d'un virement précédent.

## Montants

| Colonne | Signification |
| --- | --- |
| **Montant** | Montant de la demande |
| **Frais** | Frais de gestion TTC retenus sur la demande |
| **Net** | Montant moins frais : ce qui sera viré pour cette demande |

Les frais sont calculés avec le taux de frais et la TVA configurés pour le
réseau. Si les documents existent déjà, les montants sont repris de la
facture de frais. Tous les montants viennent de l'API ; l'écran n'en calcule
aucun. Pour les factures de frais de gestion, voir
[Consulter et télécharger les factures de frais de gestion](consulter-telecharger-factures-frais-gestion.md).

## États d'une demande

| Ce que vous voyez | Ce que cela signifie |
| --- | --- |
| Absente de l'écran, faite aujourd'hui | Sera proposée à partir de demain |
| Dans **À payer** | Sera payée par le prochain ordre de virement |
| Dans **Écartées** | Ne sera pas payée par ce virement ; motif affiché |
| **Mise en attente** dans les motifs | Suspendue par un administrateur |
| Disparue après une génération | Rattachée à un ordre de virement |

Aucun de ces états ne prouve que le partenaire a reçu l'argent : être
rattachée à un ordre signifie que le fichier bancaire a été produit, pas
qu'il a été transmis à la banque ni que le virement a été exécuté. Le
back-office ne propose pas d'annuler une demande.

## Messages utiles

- **Impossible de charger l'aperçu du prochain virement.** avec
  **Réessayer** : l'aperçu n'a pas pu être lu ; ce n'est pas une absence de
  demande.
- **Configuration du réseau incomplète, contactez le support.** : la date de
  bascule du réseau manque.
- **Aucun compte bancaire de remboursement n'est configuré pour ce réseau,
  contactez le support.**
- **Vous n'avez pas accès à ce réseau.**

## Portée de l'aide Néo

Néo explique cet écran. Il ne crée, ne suspend ni ne paie aucune demande et
ne peut pas confirmer qu'un partenaire a été remboursé.

Vérification au 30 octobre 2026 : menu, écran, modèle de l'aperçu, sélection
et calcul côté API, création d'une demande côté API lus. Aucun écran ouvert en
session, aucune demande créée ; application commerçant non lue.
