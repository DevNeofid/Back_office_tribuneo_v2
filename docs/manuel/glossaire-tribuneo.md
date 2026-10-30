# Glossaire Tribuneo

## Objectif

Donner le sens précis des termes employés dans le back-office et indiquer la
fiche à suivre pour chaque tâche. Une définition ne remplace pas la procédure :
pour agir, suivez le renvoi indiqué.

## Personnes et entités

- **Client (client acheteur)** : entité qui passe une commande et la règle. Elle
  est choisie dans **Offert par** à la création et se gère dans **Clients**. Ce
  n'est ni le bénéficiaire qui reçoit les bons, ni le commerçant qui les
  encaisse. Voir [Rechercher et filtrer un client](rechercher-client.md).
- **« Offert par »** : texte enregistré sur la commande et imprimé sur les
  chèques. Il reprend en général le nom du client, mais
  **Personnalisation offert par (optionnel)** peut le remplacer sans changer le
  client rattaché. La recherche des commandes porte sur ce texte, pas sur le nom
  de la fiche client.
- **Bénéficiaire** : personne destinataire d'un bon. Elle n'a de fiche ni dans
  **Clients** ni dans **Partenaires**. Ses coordonnées peuvent être enregistrées
  sur le bon lors d'un import, ou venir du compte consommateur auquel le bon est
  attribué. Voir [Consulter les bons d'une commande](consulter-bons-commande.md)
  et [Consulter les bénéficiaires d'une commande importée](consulter-beneficiaires-commande-importee.md).
- **Compte consommateur** : compte utilisateur de l'application auquel un bon
  peut être attribué, avec un porte-monnaie consommateur dans le réseau. Voir
  [Statistiques : Comptes utilisateurs](statistiques-comptes-utilisateurs.md).
- **Partenaire (commerçant)** : commerce qui a le rôle partenaire dans le
  réseau. Il dispose d'un compte d'application, d'un **Solde Tribuneo** et peut
  être remboursé. Il se gère dans **Partenaires**. Voir
  [Rechercher et consulter un partenaire](rechercher-consulter-partenaire.md).
- **Entité commune** : une même entité peut être cliente et partenaire, et
  exister dans plusieurs réseaux. Nom, e-mail, téléphone, SIRET, adresse,
  IBAN/BIC et secteurs lui sont communs : une correction vaut pour ses autres
  rôles. **Dupliquer** ajoute un rôle à cette même entité, sans copie
  indépendante. Voir [Dupliquer un client en partenaire](dupliquer-client-en-partenaire.md)
  et [Dupliquer un partenaire en client](dupliquer-partenaire-en-client.md).
- **Réseau** : nom affiché en haut de page. Ce n'est ni un sélecteur ni la
  preuve d'un paramétrage complet. Voir
  [Comprendre la configuration du réseau](comprendre-configuration-reseau.md).

## Commandes et bons

- **Commande** : achat de bons par un client, composé d'une ou plusieurs lignes
  (**Montant par chèque** × **Nombre de chèque**). Elle peut être saisie à la
  main, importée par fichier ou issue de la boutique en ligne. Voir
  [Comprendre les informations d'une commande](comprendre-commande.md).
- **Numéro commercial (N°)** : numéro de la commande à communiquer et à
  rechercher. L'identifiant interne, technique, n'est pas affiché. L'**ID** d'un
  bon et le **Numéro de facture** sont d'autres références.
- **Total de la commande** : somme des lignes. C'est ce qu'affiche la colonne
  **Facturé** de la liste, malgré son titre.
- **Occasion** : valeur de **Pour l'occasion de**, obligatoire à la création ;
  les messages du formulaire la désignent comme « occasion (URSSAF) ».
- **Bon, chèque, coupon** : chaque chèque d'une commande correspond à un bon.
  Les lignes parlent de chèques, la gestion des bons de bons, le récapitulatif
  (**N° Coupon**) et certains rapports de coupons. Chaque bon a un montant, un
  **Montant restant**, sa propre date d'expiration et peut être désactivé.
- **Bon attribué** : bon rattaché à un compte consommateur, par exemple après
  avoir été scanné ou utilisé. Il empêche la suppression de la commande, la
  désactivation du bon et l'avancement de sa date ; une modification de la
  commande ne le retire jamais.
- **Donation** : marquage **Oui** ou **Non** d'un bon dans les tableaux. Ce
  n'est pas une action.
- **Validité de la commande et expiration d'un bon** : la colonne **Expiration**
  de la liste concerne toute la commande ; un bon peut avoir sa propre date.
  Voir [Changer la date de validité d'une commande](changer-validite-commande.md)
  et [Changer la date d'expiration d'un bon](changer-expiration-bon.md).
- **Désactiver un bon** : renseigne sa date de **Suppression** ; aucune
  réactivation n'est proposée. Voir [Désactiver un bon](desactiver-bon.md).
- **QR codes** : trois parcours distincts. Le ZIP des QR des bons d'une
  commande ([fiche](generer-qr-codes-commande.md)), le QR de réception d'un
  partenaire ([fiche](generer-qr-reception-partenaire.md)) et le QR ou lien de
  première connexion d'un partenaire ([fiche](donner-acces-application-partenaire.md)).
- **Fichiers d'une commande** : **Générer le récapitulatif** donne montants et
  contacts ([fiche](generer-recapitulatif-commande.md)) ; **Générer le CSV**
  donne seulement des UUID ([fiche](generer-csv-bons-commande.md)) ; le fichier
  d'import sert à créer une commande ([format](annexes/format-import-commande.md)).

## Paiements et factures de commande

- **Paiement (règlement)** : enregistrement, dans **Gestion → Paiements**, d'un
  règlement reçu pour une commande : date, méthode, montant et, si demandé,
  compte encaisseur. Il ne déclenche aucune opération bancaire et ne crée pas de
  facture. Voir [Enregistrer un paiement](enregistrer-paiement-commande.md) et
  [Consulter les paiements](consulter-paiements-commande.md).
- **Payé** et **Montant payé:** : cumul des paiements enregistrés sur la commande.
- **Reste à payer (solde de la commande)** : total moins cumul payé. La liste ne
  l'affiche pas directement. Voir
  [Vérifier le solde et le statut payé](verifier-solde-commande.md).
- **Indicateur « payée »** : état enregistré séparément, mis à jour lors de
  l'ajout ou de la suppression d'un paiement, mais pas lors d'un changement du
  total. En cas de désaccord, les montants font foi.
- **Compte encaisseur** : compte bancaire du réseau sur lequel un paiement de
  commande a été encaissé.
- **Facture de commande** : document numéroté, unique pour une commande, créé
  par **Générer la Facture** et listé dans **Documents → Factures**. Voir
  [Générer la facture](generer-facture-commande.md) et
  [Retélécharger une facture existante](retelecharger-facture-existante.md).
- **Bon de livraison** : document dont le numéro est créé avec la facture. Il
  n'existe pas sans elle et n'apparaît pas dans **Documents**. Voir
  [Générer le bon de livraison](generer-bon-livraison-commande.md).

## Remboursements des partenaires

- **Remboursement** : dans le back-office, paiement à un partenaire, par un
  ordre de virement, du montant de ses demandes de remboursement. Aucune
  procédure de remboursement d'un client acheteur n'est décrite ; supprimer un
  paiement n'est pas un remboursement.
- **Solde Tribuneo** : montant du partenaire dans le réseau, affiché sur sa
  carte. La création d'une demande de remboursement en retire ce qui est
  remboursable. Un solde non nul empêche la désactivation du partenaire.
- **Demande de remboursement** : demande créée côté partenaire, depuis
  l'application commerçant ou par un traitement automatique, jamais depuis le
  back-office. Elle apparaît dans **Prochain virement** à partir du lendemain.
  Voir [Consulter les demandes de remboursement](consulter-demandes-remboursement.md).
- **Montant, Frais, Net** : montant de la demande, frais de gestion TTC retenus,
  et ce qui sera viré pour elle.
- **Demande écartée, mise en attente** : demande que le prochain ordre ne paiera
  pas, avec son motif ; la mise en attente est une suspension manuelle. Voir
  [Traiter les demandes écartées](traiter-demandes-remboursement-bloquees.md) et
  [Mettre en attente ou libérer une demande](mettre-en-attente-liberer-demande-remboursement.md).
- **Justificatif (de réception)** : pièce numérotée d'une demande, émise avec sa
  facture de frais de gestion, en général à la génération de l'ordre de
  virement. Il ne prouve ni la transmission à la banque ni la réception de
  l'argent. Voir [Consulter le justificatif](consulter-justificatif-remboursement.md).
- **Facture de frais de gestion** : facture des frais retenus sur une demande de
  remboursement, listée dans **Documents → Frais de gestion**. Elle est distincte
  de la facture de commande. Voir
  [Consulter et télécharger les factures de frais de gestion](consulter-telecharger-factures-frais-gestion.md).
- **Ordre de virement** : enregistrement et ZIP produits par
  **Générer l'ordre de virement**, avec le fichier bancaire `.TXT.SCT`. Les
  demandes qu'il contient ne sont plus proposées ensuite. Ce n'est pas un
  virement exécuté. Voir [Générer l'ordre de virement](generer-ordre-virement.md)
  et [Consulter et retélécharger un ordre](consulter-retelecharger-ordre-virement.md).
- **Compte payeur** : compte bancaire du réseau donneur d'ordre du fichier de
  virement, lu ou choisi dans **Prochain virement**. Voir
  [Choisir le compte payeur](choisir-compte-payeur-virement.md).
- **Virement exécuté** : crédit effectif du partenaire par la banque, après
  transmission du fichier selon la procédure convenue avec elle. Le back-office
  n'affiche ni la transmission ni l'exécution.

## Comptabilité et paramétrage

- **Écritures comptables** : lot de fichiers produit par
  **Déclencher les écritures comptables** dans **Écritures**, pour une période
  calculée automatiquement. Voir [Générer](generer-ecritures-comptables.md),
  [Retélécharger](retelecharger-ecritures-comptables.md) et
  [Faire configurer](configurer-ecritures-comptables.md).
- **Journal et compte 512** : paramètres comptables de chaque compte bancaire du
  réseau, vérifiés par Neofid. Aucun formulaire du back-office ne les modifie.
- **Seuil de suppression des paiements** : un paiement créé avant le dernier lot
  d'écritures ne peut plus être supprimé, même si le lot était vide.
- **Comptes bancaires du réseau** : configurés par Neofid, sans écran de
  création ou de modification dans le back-office. Ne les confondez pas avec
  les **Informations bancaires** d'un client (numéro comptable et
  intracommunautaire) ou d'un partenaire (IBAN, BIC).
- **Secteur d'activité** : libellé d'un catalogue commun, attribué aux
  partenaires. Voir [Créer un secteur](creer-secteur-activite.md),
  [Supprimer un secteur](supprimer-secteur-activite.md) et
  [Attribuer des secteurs](attribuer-secteurs-partenaire.md).

## Mots à préciser avant de répondre

| Mot employé | Peut désigner | Question à se poser |
| --- | --- | --- |
| facture | facture de commande ; facture de frais de gestion | Commande d'un client ou frais d'une demande de remboursement ? |
| remboursement | demande d'un partenaire ; ordre de virement ; virement exécuté | Quelle étape ? Un client acheteur n'a pas de parcours de remboursement décrit. |
| solde | reste à payer d'une commande ; Solde Tribuneo d'un partenaire ; porte-monnaie consommateur ; montant restant d'un bon | De quel écran vient le chiffre ? |
| compte | compte encaisseur ; compte payeur ; compte consommateur ; compte d'application du partenaire ; compte « support technique » ; compte comptable ; compte administrateur | Bancaire, utilisateur ou comptable ? |
| client | client acheteur ; bénéficiaire (rapport **Statut des QR codes par client**) | Qui a payé la commande, ou qui a reçu le bon ? |
| expiration | validité de toute la commande ; expiration d'un seul bon | Toute la commande ou un bon ? |
| export CSV | récapitulatif ; CSV des UUID ; rapport de **Statistiques** ; fichier d'import | Quel contenu est attendu ? |
| supprimer, désactiver | bon, client, partenaire, commande, paiement, secteur | Chaque objet a ses propres effets et refus. |
| annuler | bouton **Annuler** d'une fenêtre, qui n'envoie rien | Aucune annulation d'une demande, d'un ordre de virement ou d'une commande supprimée n'est proposée. |

Les différences entre commande, paiement, facture et remboursement sont
détaillées dans
[Distinguer commande, paiement, facture et remboursement](distinguer-commande-paiement-facture-remboursement.md).
Les enchaînements nécessaires figurent dans
[Comprendre les prérequis entre les tâches](comprendre-prerequis-entre-taches.md).

## Avec Néo

Demandez par exemple : « Quelle différence entre client et bénéficiaire ? » ou
« Qu'est-ce qu'un compte payeur ? ». Néo explique le terme et indique la fiche
utile ; il n'effectue aucune opération et ne remplace pas la procédure de cette
fiche.

Vérification au 30 octobre 2026 : définitions reprises des 73 fiches vérifiées
des lots 01 à 05, sans les modifier. Aucune opération métier ni appel réseau.
