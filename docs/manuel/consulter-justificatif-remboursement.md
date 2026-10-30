# Consulter le justificatif d'une demande de remboursement

## Objectif

Récupérer le justificatif de réception d'une demande de remboursement d'un
partenaire. Chaque demande payée a **un** justificatif de réception et **une**
facture de frais de gestion, produits ensemble dans un même document.

## Quand le justificatif existe

Le back-office n'a plus de bouton pour éditer les justificatifs. Ils sont
créés automatiquement lors de la génération de l'ordre de virement, pour
chaque demande payée qui n'en a pas encore. Ils sont datés de leur jour de
création, donc en général du jour du virement.

Dans **Prochain virement**, l'icône de document à l'info-bulle
**Documents déjà émis** indique qu'une demande **À payer** a déjà son
justificatif, avec son numéro entre parenthèses. Ce justificatif sera
réutilisé, jamais dupliqué.

## Depuis l'historique des virements

1. Ouvrez **Virements**.
2. Sur la ligne de l'ordre, cliquez sur l'icône
   **Documents (justificatifs et factures)**.
3. Patientez pendant **Préparation des documents du virement...**. Les
   documents sont produits à la demande, ce qui peut prendre du temps.
4. Le navigateur enregistre `DOCUMENTS_BTO_<numéro de l'ordre>.zip`, avec une
   entrée par demande payée nommée
   `<numéro de justificatif>_<numéro de facture>.pdf`.

D'après le code lu, chacune de ces entrées contient elle-même le
justificatif et la facture dans une archive, malgré son extension `.pdf`.
Ce point n'a pas été observé ; s'il empêche l'ouverture, signalez-le au
support.

| Message | Signification |
| --- | --- |
| **Aucun document disponible pour ce virement.** | Ordre sans document relié, notamment ceux antérieurs au 14/10/2026 |
| **Le service de génération des PDF ne répond pas. Réessayez plus tard.** | Le service des PDF est indisponible |
| **Erreur lors du téléchargement des documents du virement.** | Autre échec |

## Depuis Documents, par demande

Le menu **Documents**, bouton **Frais de gestion**, liste les factures de
frais déjà émises avec leur **Numéro de transaction**, c'est-à-dire le numéro
de la demande. Son bouton **Télécharger** enregistre un fichier `.zip` au nom
du destinataire ; d'après le code lu, il contient la facture de frais et le
justificatif de réception. Ce parcours est décrit dans la fiche sur les
factures de frais de gestion. Une ligne dans cette liste ne prouve pas que la
demande a été payée.

## Ce que contient un justificatif

Le justificatif reprend le numéro et la date de la demande, son montant et
le taux de frais ; la facture associée détaille les frais de gestion
retenus. Il ne prouve pas que le fichier de virement a été transmis à la
banque ni que le partenaire a reçu l'argent. L'adresse et les informations du
commerçant y sont celles de sa fiche au jour de l'émission.

Le partenaire peut aussi télécharger, depuis l'application commerçant, les
documents de ses propres demandes une fois émis. Ce parcours n'est pas décrit
ici.

## Portée de l'aide Néo

Néo explique où trouver ces documents ; il ne les produit ni ne les joint à
la conversation.

Vérification au 30 octobre 2026 : icônes, messages, repositories, actions API
des documents d'un ordre et d'une demande, et route du service des PDF lus.
Aucun document téléchargé ou produit ; contenu des archives non observé.
