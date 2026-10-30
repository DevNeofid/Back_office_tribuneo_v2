# Comprendre les prérequis entre les tâches

## Objectif

Savoir ce qui doit exister avant une tâche, ce qui n'est pas nécessaire, et qui
impose la condition : le formulaire, le serveur, ou seulement une règle de
gestion. Les étapes détaillées restent dans la fiche de chaque tâche.

## Qui impose la condition

| Niveau | Ce que cela signifie pour vous |
| --- | --- |
| **Formulaire** | Le back-office bloque avant l'envoi ou grise un bouton. Le serveur peut ne pas refaire ce contrôle. |
| **Serveur** | L'opération est refusée par le serveur, même si le bouton était actif. Le message affiché peut être générique. |
| **Donnée nécessaire** | L'opération a besoin de l'information, sans refus dédié établi : l'échec peut être générique ou survenir en cours de traitement. |
| **Règle de gestion non bloquée** | Consigne énoncée pour le réseau que le code lu ne bloque pas. Vérifiez vous-même avant d'agir. |

Le détail des messages figure dans
[Comprendre les refus du back-office](comprendre-refus-operations-back-office.md).

## Commande, paiement et facture

Ordre conseillé pour un nouveau client : créer le client, renseigner son
adresse, créer la commande, relire ses lignes, puis enregistrer les paiements
et générer la facture dans l'ordre utile au réseau.

| Pour… | Il faut d'abord… | Niveau | Fiche |
| --- | --- | --- | --- |
| Créer une commande | Un client existant, choisi dans **Offert par**, et une occasion | Formulaire | [Saisie manuelle](creer-commande-manuelle.md), [depuis un client](creer-commande-depuis-client.md) |
| Importer une commande | Client, occasion et fichier conforme ; les e-mails partent à l'enregistrement | Formulaire, puis serveur pour le contenu | [Import](creer-commande-import-fichier.md), [format](annexes/format-import-commande.md) |
| Enregistrer un paiement | Un reste à payer ; un compte encaisseur s'il est demandé | Plafond : formulaire et serveur. Date non antérieure au dernier paiement : formulaire | [Enregistrer un paiement](enregistrer-paiement-commande.md) |
| Générer la facture | L'adresse du client (rue, code postal, ville) | Donnée nécessaire : message générique qui évoque l'adresse | [Générer la facture](generer-facture-commande.md), [adresse](renseigner-adresse-client.md) |
| Générer le bon de livraison | Une facture pour la commande | Échec générique sans facture | [Bon de livraison](generer-bon-livraison-commande.md) |
| Modifier les lignes | Commande non facturée, saisie à la main ; bons à retirer non attribués | Serveur, avec bandeau du formulaire | [Modifier une commande](modifier-commande.md) |
| Avancer la date de validité | Aucun bon attribué concerné ; date au plus tôt demain | Serveur | [Validité](changer-validite-commande.md) |
| Supprimer un paiement | Paiement créé après le dernier lot d'écritures comptables | Serveur ; la corbeille reste visible | [Supprimer un paiement](supprimer-paiement-commande.md) |
| Supprimer une commande | Aucun bon non annulé attribué ou utilisé | Serveur | [Supprimer une commande](supprimer-commande.md) |
| Supprimer une commande | Commande non facturée et non exportée en comptabilité | Règle de gestion non bloquée par le code lu : vérifiez la facture avant de confirmer | [Supprimer une commande](supprimer-commande.md) |

### Ce qui n'est pas un prérequis

- Une commande n'a pas besoin d'être payée pour être facturée : les paiements
  déjà enregistrés figurent sur le document. Elle peut aussi être payée sans
  être facturée.
- Le récapitulatif, le CSV des UUID et le ZIP des QR codes ne demandent pas de
  facture. Le CSV des UUID ne demande pas de générer d'abord le ZIP des QR.
- La facture ne dépend pas des écritures comptables. En revanche, un lot
  d'écritures ne reprend que les factures et paiements déjà créés à sa date.
- Une facture ne se crée qu'une fois : relancer la génération ne crée pas de
  second numéro, mais remplace la référence enregistrée.

## Bons d'une commande

| Pour… | Il faut… | Niveau | Fiche |
| --- | --- | --- | --- |
| Renvoyer l'e-mail cadeau | Bon non annulé, non attribué, avec un e-mail enregistré | Serveur ; le bouton peut être proposé à tort dans **Gestion des bons** | [Renvoyer](renvoyer-cadeau-beneficiaire.md) |
| Désactiver un bon | Bon non attribué et non déjà désactivé | Formulaire selon les contacts affichés, puis serveur | [Désactiver un bon](desactiver-bon.md) |
| Avancer l'expiration d'un bon | Bon non désactivé et non attribué ; au plus tôt demain | Serveur | [Expiration d'un bon](changer-expiration-bon.md) |
| Obtenir le ZIP des QR codes | Bons non annulés ; génération disponible pour le réseau | Serveur | [QR codes](generer-qr-codes-commande.md) |
| Obtenir le CSV des UUID | Liens QR déjà existants | Serveur, message générique | [CSV des UUID](generer-csv-bons-commande.md) |
| Lire les bénéficiaires importés | Commande importée par fichier | Message dans la fenêtre | [Bénéficiaires](consulter-beneficiaires-commande-importee.md) |

## Partenaires et remboursements

La chaîne suivante va de l'inscription du partenaire au virement. Chaque étape
est nécessaire à la suivante, mais n'en prouve aucune.

1. Le partenaire est ajouté : rôle, compte d'application et solde dans le
   réseau. Voir [Ajouter un partenaire](ajouter-partenaire.md).
2. Le commerçant fait sa première connexion avec le QR ou le lien remis. Voir
   [Donner accès à l'application](donner-acces-application-partenaire.md).
3. Une demande de remboursement est créée côté partenaire ; le back-office n'en
   crée jamais.
4. Elle apparaît dans **Prochain virement** à partir du lendemain, si elle est
   postérieure à la date de bascule du réseau.
5. Elle est **À payer** si l'adresse du commerçant (rue, code postal, ville),
   son IBAN et son BIC sont renseignés, si elle n'est pas mise en attente, si
   son net après frais est positif et si le commerçant est retrouvé. Sinon elle
   est **Écartée**, sans bloquer les autres.
6. Le compte payeur doit être complet : titulaire, IBAN et BIC.
7. **Générer l'ordre de virement** émet les justificatifs et factures de frais
   manquants, enregistre l'ordre et télécharge le ZIP.
8. Le fichier `.TXT.SCT` est transmis à la banque, hors du back-office.
9. La banque exécute le virement ; le back-office ne l'affiche pas.

| Pour… | Il faut… | Niveau | Fiche |
| --- | --- | --- | --- |
| Générer le QR de réception | Compte d'application et solde dans le réseau | Serveur, échec sans message | [QR de réception](generer-qr-reception-partenaire.md) |
| Générer le QR ou lien de première connexion | Compte d'application ; première connexion pas encore faite ; e-mail sur la fiche pour l'envoi | Serveur | [Accès](donner-acces-application-partenaire.md) |
| Rendre une demande payable | Les conditions de l'étape 5 | Sélection du serveur | [Demandes écartées](traiter-demandes-remboursement-bloquees.md) |
| Générer l'ordre | Au moins une demande **À payer**, montant non nul, compte payeur complet, réseau configuré, aucune autre génération en cours | Serveur | [Générer l'ordre](generer-ordre-virement.md), [compte payeur](choisir-compte-payeur-virement.md) |
| Désactiver un partenaire | Solde Tribuneo nul dans le réseau ; compte d'application lié | Serveur, message générique | [Désactiver un partenaire](desactiver-partenaire.md) |

La libération d'une demande mise en attente ne lève pas ses autres motifs,
malgré le texte de la fenêtre **Libérer la demande**.

## Clients, rôles et secteurs

| Pour… | Il faut… | Niveau | Fiche |
| --- | --- | --- | --- |
| Ajouter un client professionnel ou un partenaire | SIRET de 14 chiffres ; pas déjà ce rôle dans le réseau | Formulaire pour le format, serveur pour le doublon | [Client professionnel](ajouter-client-professionnel.md), [partenaire](ajouter-partenaire.md) |
| Vider le SIRET d'une entité | Qu'elle ne soit partenaire dans aucun réseau | Serveur | [Modifier un client](modifier-client.md) |
| Désactiver un client | Aucune commande associée marquée non payée | Serveur, sur l'indicateur « payée » et non sur les montants ; message identique pour tout refus | [Désactiver un client](desactiver-client.md) |
| Dupliquer un client ou un partenaire | Que l'entité n'ait pas déjà ce rôle dans le réseau | Serveur | [Client → partenaire](dupliquer-client-en-partenaire.md), [partenaire → client](dupliquer-partenaire-en-client.md) |
| Supprimer un secteur | Aucun lien avec une entité, tous réseaux confondus | Serveur | [Supprimer un secteur](supprimer-secteur-activite.md) |

## Comptabilité, statistiques et accès

| Pour… | Il faut… | Niveau | Fiche |
| --- | --- | --- | --- |
| Générer les écritures | Écritures activées ; compte par défaut ; journal et compte 512 des comptes utilisés ; paramètres du réseau ; normalement, pas de lot déjà créé le jour même | Serveur ; paramétrage par Neofid | [Générer](generer-ecritures-comptables.md), [configurer](configurer-ecritures-comptables.md) |
| Retélécharger un lot | Écritures activées ; lot présent dans l'historique | Serveur | [Retélécharger](retelecharger-ecritures-comptables.md) |
| Lire ou exporter une statistique | Compte administrateur du réseau ; dates de début et de fin différentes | Serveur | [Statistiques](consulter-exporter-statistiques.md) |
| Utiliser le back-office | Compte administrateur du réseau | Contrôlé à la connexion | [Résoudre un problème de connexion](resoudre-probleme-connexion.md) |

Générer un lot d'écritures rend non supprimables les paiements créés avant lui.
Consulter ou retélécharger un lot n'a pas cet effet.

## Avec Néo

Demandez par exemple : « Que faut-il avant de générer une facture ? » ou
« Que faut-il pour qu'une demande de remboursement soit payée ? ». Néo explique
les prérequis et renvoie à la fiche de la tâche ; il ne crée ni ne modifie
aucune donnée pour les remplir. Pour une commande identifiée, il peut relire en
lecture seule son total, ses paiements et l'existence d'une facture.

Vérification au 30 octobre 2026 : conditions reprises des 73 fiches vérifiées
des lots 01 à 05 ; contrôles serveur de suppression de commande et de paiement,
d'enregistrement d'un paiement, de modification d'une commande facturée et de
génération de facture relus dans l'API. Aucune opération métier.
