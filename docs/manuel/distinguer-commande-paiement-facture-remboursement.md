# Distinguer commande, paiement, facture et remboursement

## Objectif

Ne pas confondre quatre éléments que le back-office enregistre séparément, et
savoir ce que chacun prouve. Un élément présent ne démontre jamais à lui seul
l'existence des autres.

## Quatre éléments distincts

| Élément | Créé par | Où le lire | Ce qu'il établit | Ce qu'il ne prouve pas |
| --- | --- | --- | --- | --- |
| **Commande** | **Commandes**, saisie manuelle ou import ; boutique en ligne | **Liste des commandes** | Un achat de bons enregistré pour un client, avec son total | Ni paiement, ni facture |
| **Paiement** | **Gestion → Paiements**, puis **Valider** | Fenêtre **Paiements** ; colonne **Payé** | Un règlement enregistré dans Tribuneo | Ni facture, ni opération bancaire déclenchée |
| **Facture de commande** | **Gestion → Générer la Facture** | **Documents → Factures** | Un numéro de facture attribué à la commande | Ni paiement, ni envoi au client |
| **Remboursement d'un partenaire** | Demande créée côté partenaire, puis ordre de virement généré dans le back-office | **Prochain virement**, **Virements** | Selon l'étape : voir plus bas | Aucune étape ne prouve seule le virement exécuté |

Pour lire chaque élément, voir
[Comprendre les informations d'une commande](comprendre-commande.md),
[Consulter les paiements d'une commande](consulter-paiements-commande.md),
[Retélécharger une facture existante](retelecharger-facture-existante.md) et
[Consulter les demandes de remboursement](consulter-demandes-remboursement.md).

## Total, payé, reste et indicateur « payée »

| Notion | Où la lire | À retenir |
| --- | --- | --- |
| **Total** | Colonne **Facturé** ; second montant de **Montant payé:** | Somme des lignes. Le titre **Facturé** ne prouve pas qu'une facture existe. |
| **Payé** | Colonne **Payé** ; premier montant de **Montant payé:** | Cumul des paiements enregistrés. |
| **Reste à payer** | À calculer : **Facturé** moins **Payé** | La liste ne l'affiche pas. Vert : soldé ; rouge : montants différents. |
| **Indicateur « payée »** | Lu par Néo et par certains contrôles | Non recalculé après un changement du total : les montants font foi. |

Si **Payé** dépasse **Facturé**, le total a pu être diminué après des
paiements. Ne corrigez pas l'écart au hasard : voir
[Vérifier le solde et le statut payé](verifier-solde-commande.md).

## Règlement et facturation sont indépendants

| Situation | Possible ? | Comment le vérifier |
| --- | --- | --- |
| Payée et facturée | Oui | Montants égaux ; facture dans **Documents → Factures** |
| Payée, non facturée | Oui | Montants égaux ; aucune facture retrouvée pour la commande |
| Facturée, non payée ou en partie | Oui | Facture retrouvée ou bandeau dans **Edition → Modifier** ; reste à payer positif |
| Ni payée ni facturée | Oui | Aucun paiement ; aucune facture retrouvée |

Avant de conclure qu'une facture ou un paiement manque, appliquez
[Réagir à une liste vide ou à un document introuvable](reagir-liste-vide-document-introuvable.md) :
une liste vide ou l'absence de bandeau peuvent venir d'un chargement en échec.

- La facture reprend les paiements déjà enregistrés au moment de sa
  génération. Elle n'exige pas que la commande soit soldée. Voir
  [Générer la facture](generer-facture-commande.md).
- Une fois la commande facturée, seule sa date de validité reste modifiable.
- Un paiement peut être enregistré avant ou après la facture.

## Supprimer un paiement n'est pas rembourser

Supprimer un paiement retire un enregistrement du back-office : aucun argent
n'est rendu, la facture et la commande restent, la commande peut redevenir non
soldée. La suppression est refusée pour un paiement créé avant le dernier lot
d'écritures comptables. Voir
[Supprimer un paiement d'une commande](supprimer-paiement-commande.md).

Le back-office lu ne décrit aucune procédure pour rembourser un client
acheteur. Dans les écrans, « remboursement » concerne les partenaires.

## Remboursement d'un partenaire : chaque étape ne prouve qu'elle-même

| Étape | Où la constater | Ce qu'elle ne prouve pas |
| --- | --- | --- |
| Demande créée ; le partenaire peut recevoir « Votre remboursement de …€ a été effectué. » | **Prochain virement**, à partir du lendemain | Aucun virement n'a encore eu lieu. |
| Demande **À payer** | **Prochain virement** | Elle peut être écartée si la fiche change avant la génération. |
| Justificatif et facture de frais émis | Icône **Documents déjà émis** ; **Documents → Frais de gestion** | Ni paiement, ni transmission à la banque. |
| Ordre de virement généré | **Virements** ; ZIP `BTO_…` avec le fichier `.TXT.SCT` | Le fichier n'est pas encore transmis à la banque. |
| Fichier transmis à la banque | Hors du back-office | Le virement n'est pas encore exécuté. |
| Virement exécuté | Hors du back-office, auprès de la banque | — |

Une demande rattachée à un ordre n'est plus jamais proposée, même si le fichier
n'a pas été transmis. Retélécharger un ordre donne le même fichier : vérifiez
qu'il n'a pas déjà été transmis avant de le transmettre de nouveau. Voir
[Générer l'ordre de virement](generer-ordre-virement.md) et
[Consulter et retélécharger un ordre](consulter-retelecharger-ordre-virement.md).

## Quelle facture ?

| Document | Concerne | Où le trouver |
| --- | --- | --- |
| Facture de commande | Le client acheteur d'une commande | **Documents → Factures** |
| Facture de frais de gestion | Les frais retenus sur une demande de remboursement d'un partenaire | **Documents → Frais de gestion** ; ZIP des documents d'un virement |

Une demande comme « télécharger la facture » doit préciser laquelle. Le
téléchargement d'une facture de frais peut émettre des documents manquants :
voir [Consulter et télécharger les factures de frais de gestion](consulter-telecharger-factures-frais-gestion.md).

## Fichiers produits et chiffres de synthèse

- Le ZIP `BTO_…` et son fichier `.TXT.SCT` sont des fichiers à transmettre à la
  banque, pas une preuve de virement.
- Le ZIP des écritures comptables est un export : il sélectionne factures et
  paiements selon leur date de création et ne crée aucune facture manquante.
  Voir [Générer les écritures comptables](generer-ecritures-comptables.md).
- Dans **Statistiques**, **Total injecté** porte sur les commandes créées, sans
  tenir compte de leur paiement, et **Frais de gestion** n'est pas une liste de
  factures. Voir [Montant total du réseau](statistiques-montant-total-reseau.md).

Les termes sont définis dans le [glossaire](glossaire-tribuneo.md).

## Avec Néo

Demandez par exemple : « Une commande payée est-elle forcément facturée ? » ou
« L'ordre de virement généré prouve-t-il que le partenaire est payé ? ».

Pour une commande identifiée, Néo peut lire en lecture seule son total, son
montant payé, son reste à payer, son indicateur « payée », ses paiements et les
informations d'une facture existante, sans PDF. Il ne lit ni les demandes de
remboursement, ni les ordres de virement, ni les écritures, et ne peut pas
confirmer qu'un virement a été exécuté. Il n'enregistre, ne facture et ne
rembourse rien.

Vérification au 30 octobre 2026 : distinctions reprises des fiches commandes,
paiements, factures, remboursements, comptabilité et statistiques ; règles de
plafond, de suppression de paiement et de facturation relues dans l'API.
Aucune opération métier.
