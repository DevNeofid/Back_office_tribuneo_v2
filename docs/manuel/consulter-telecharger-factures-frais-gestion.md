# Consulter et télécharger les factures de frais de gestion

## Objectif

Retrouver une facture de frais de gestion liée à une demande de remboursement
partenaire. Elle est distincte d'une facture de commande, d'un justificatif de
réception et d'un ordre de virement bancaire, même si le téléchargement peut
rassembler justificatif et facture.

Le parcours décrit concerne l'administrateur du réseau dans le back-office.
Consulter la liste et télécharger un document sont deux actions différentes.

## Consulter la liste

1. Ouvrez **Documents**.
2. Choisissez **Frais de gestion**. L'autre bouton, **Factures**, affiche les
   factures de commande.
3. Identifiez la ligne avec **Numéro de transaction**, **Numéro de facture**,
   **Destinataire**, **Montant total (€)** et **Date de création**. Le montant
   est celui de la facture de frais, pas le montant net viré au partenaire.
4. Utilisez la pagination du tableau, réglé sur dix lignes par page, pour
   consulter les factures plus anciennes. Aucun filtre de recherche ou de
   période n'est proposé dans cet onglet.

La liste présente les factures déjà liées à un justificatif de réception,
classées par date de création décroissante. Cette lecture n'émet aucune
nouvelle facture. Un tableau vide peut aussi résulter d'un refus ou d'une
erreur de lecture : il ne prouve pas l'absence de facture ou de remboursement.

## Télécharger une ligne

1. Après avoir identifié la bonne facture dans **Frais de gestion**, utilisez
   l'icône **Télécharger** de sa colonne **Actions** seulement si vous souhaitez
   réellement obtenir le document.
2. Attendez la fermeture de **Génération du document...** et contrôlez le fichier
   reçu. Le BO donne au fichier le nom du destinataire, espaces remplacés par
   des traits de soulignement, ou `Frais` si le nom est absent.
3. En cas d'échec, vérifiez à nouveau la liste et la référence de transaction
   avant de recommencer ; transmettez le message à Neofid si nécessaire.

**Format du fichier :** d'après le code lu du service des PDF, la réponse est
une archive ZIP de deux PDF : la facture de frais `FAC_<numéro>.pdf` et le
justificatif `JR_<numéro>.pdf`. Le BO l'enregistre sous `<destinataire>.zip`,
sans reprendre le nom proposé par le serveur. Aucun fichier réel n'a été
produit pour l'observer ; aucun parcours vers un PDF de facture seule n'est
établi dans cet onglet.

## Effets possibles du téléchargement

La route appelée peut créer les documents manquants pour une demande de
remboursement lorsqu'elle est utilisée par un administrateur réseau. Elle
cherche d'abord une paire justificatif/facture existante et la réutilise ;
sinon, elle contrôle la demande, le partenaire, son adresse postale et ses
IBAN/BIC, puis numérote et enregistre la paire sous verrou et transaction.
Elle demande ensuite le rendu au service PDF. Un échec du PDF peut donc laisser
une facture et un justificatif déjà enregistrés.

Dans cette liste, une facture est normalement déjà présente ; le contrôle de
réutilisation reste effectué au moment du téléchargement. Il ne faut pas
généraliser cette action en « lecture sans effet » à partir de son nom ou de
la méthode GET. L'émission de la facture ne prouve pas le paiement du
remboursement ni l'envoi d'un virement à la banque.

Les frais sont calculés au moment de l'émission à partir du montant de la
demande et des taux configurés pour le réseau : frais hors taxe arrondis au
centime, puis TVA arrondie au centime, total des frais déduit du remboursement.
La paire déjà émise est réutilisée sans recalculer ces montants enregistrés.
Cette description du calcul du logiciel n'est pas un conseil comptable.

La génération d'un ordre de virement peut également émettre ces mêmes paires
pour les demandes retenues. Dans **Virements**, l'icône **Documents (justificatifs
et factures)** récupère les pièces déjà liées à un virement : le ZIP
`DOCUMENTS_BTO_<id>.zip` contient une entrée `.pdf` par demande, nommée avec
les numéros du justificatif et de la facture ; d'après le code lu, chaque
entrée est elle-même l'archive des deux PDF, malgré son extension. Voir
[Consulter le justificatif d'une demande de remboursement](consulter-justificatif-remboursement.md).
Cette route produit les rendus et un ZIP
temporaire, sans émettre de nouvelle paire. Si aucun document n'est lié au
virement, le BO affiche **Aucun document disponible pour ce virement.** ; il
ne faut pas en déduire que toute facture de frais est absente. Pour la
conduite du virement, voir
[Générer l'ordre de virement des remboursements](generer-ordre-virement.md).

## Contrôles et messages

| Situation | Comportement lu |
|---|---|
| Échec du téléchargement depuis **Documents → Frais de gestion** | **Erreur lors de la génération du fichier.** est le message générique du BO ; il ne détaille pas la cause ni l'état d'enregistrement. |
| Demande invalide/introuvable, hors réseau ou mauvais type de transaction | Refus de la route API ; seuls les remboursements de type 4 sont admis. |
| Documents à émettre et partenaire incomplet | L'API contrôle rue, code postal, ville, IBAN et BIC non vides. Elle peut refuser avec les codes `INCOMPLETE_ENTITY`, `MISSING_ADDRESS` ou `MISSING_BANK_DETAILS` dans les détails. Ce bouton ne fournit pas de formulaire de correction. |
| Numérotation occupée | Refus API 409 `NUMBERING_BUSY`. Le verrou de numérotation est libéré en sortie ; il ne s'agit pas d'une mise en attente de remboursement. |
| Service PDF indisponible après émission | Une erreur peut survenir alors que les documents numérotés sont déjà enregistrés. Vérifiez les données avant de retenter. |

Pour l'accès commerçant distinct de ce BO, la route n'émet jamais de documents :
elle exige qu'ils existent déjà et contrôle la propriété du commerce. À défaut,
elle refuse avec `DOCUMENTS_NOT_YET_ISSUED`. Ce comportement ne doit pas être
confondu avec celui de l'administrateur réseau.

## Avec Néo

Néo explique la consultation, les effets possibles et les limites du fichier.
Il ne crée ni facture ni justificatif, ne déclenche pas de remboursement et ne
télécharge pas ces pièces. La facture de commande reste un autre sujet ; une
demande telle que « télécharger la facture » doit préciser de quelle facture
il s'agit.
