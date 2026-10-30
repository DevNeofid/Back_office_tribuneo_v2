# Plan du manuel utilisateur du back-office Tribuneo

Plan établi le 12 octobre 2026 à partir du code du back-office (`lib/presentation/`). Le manuel est rédigé progressivement : ce document en fixe la structure. La première fiche, [Rechercher une commande](manuel/rechercher-commande.md), a été rédigée le 29 octobre 2026 à partir du code de l'interface ; sa validation visuelle sur la préproduction reste à faire.

La fiche [Consulter les paiements d'une commande](manuel/consulter-paiements-commande.md)
est également rédigée à partir du code de l'interface. L'[index du manuel](manuel/README.md)
recense les fiches disponibles et leur état de validation.

La fiche [Retélécharger une facture existante](manuel/retelecharger-facture-existante.md)
décrit le parcours Documents → Factures → Télécharger pour une facture de
commande déjà présente, distinct de la première facturation.

**Lecteur visé :** l'administrateur d'un réseau (rôle `NETWORK_ADMIN`). Il n'existe qu'un compte par réseau, éventuellement partagé par plusieurs personnes.

**Double usage :** le manuel sert aux utilisateurs **et** de base de connaissances au futur chatbot du back-office. D'où les choix ci-dessous.

---

## Principes de rédaction

- **Organisé par tâche, pas par écran.** Un chapitre = un objectif de l'utilisateur (« Créer une commande », « Rembourser les partenaires »). C'est la forme des questions posées au chatbot.
- **Une fiche par tâche**, toujours avec la même structure :
  1. **Objectif** : une phrase.
  2. **Prérequis** : ce qui doit exister avant (client, adresse, compte bancaire…).
  3. **Étapes** : numérotées, avec les libellés exacts de l'interface en gras.
  4. **Règles et limites** : ce que le back-office refuse, et pourquoi.
  5. **Messages d'erreur** : le message exact affiché, sa cause, la solution.
  6. **Écran** : nom du menu et identifiant de deep-link (à définir) pour que le chatbot puisse y renvoyer.
- **Libellés recopiés de l'interface**, sans reformulation, pour que l'utilisateur les retrouve à l'écran.
- **Markdown versionné dans ce dépôt** (`docs/manuel/`, un fichier par chapitre) : un changement d'écran met à jour la doc dans la même PR.
- **Captures d'écran** : facultatives au départ. Elles vieillissent vite et le chatbot ne les lit pas.

---

## Structure du manuel

### 0. Prise en main
- 0.1 Se connecter (identifiant, mot de passe, messages d'erreur : accès refusé, identifiants invalides, trop de tentatives). Pas de « mot de passe oublié » dans le back-office : c'est voulu. En cas d'oubli, l'administrateur contacte Neofid, qui réinitialise le mot de passe
- 0.2 Se repérer : menu latéral (10 entrées), en-tête, nom du réseau, déconnexion
- 0.3 Le tableau de bord et ses raccourcis
- 0.4 Le point rouge sur « Remboursement »
- 0.5 Glossaire : client, partenaire, commande, bon / chèque, occasion URSSAF, offert par, frais de gestion, justificatif, ordre de virement, écriture comptable, compte encaisseur / payeur

### 1. Gérer les clients (entreprises et particuliers qui achètent des chèques)
- 1.1 [Ajouter un client particulier](manuel/ajouter-client-particulier.md) — M04 intégrée localement (lot 02) ; recette à faire.
- 1.2 [Ajouter un client professionnel (recherche SIRET)](manuel/ajouter-client-professionnel.md) — M04 ; recherche SIRET interne à Tribuneo, sans registre externe établi.
- 1.3 [Rechercher et filtrer les clients](manuel/rechercher-client.md) — M04 ; les icônes « Filtres » choisissent l'onglet affiché.
- 1.4 [Modifier les informations générales](manuel/modifier-client.md) — M04 ; code client non repris par l'API.
- 1.5 [Renseigner ou modifier l'adresse](manuel/renseigner-adresse-client.md) — **indispensable pour facturer** ; M04.
- 1.6 [Renseigner les informations bancaires accessibles](manuel/renseigner-coordonnees-bancaires-client.md) — M04 ; côté client, numéro comptable et intracommunautaire seulement : IBAN, BIC et RIB réservés au type partenaire.
- 1.7 [Dupliquer un client en partenaire](manuel/dupliquer-client-en-partenaire.md) — M04 ; ajout du rôle partenaire à la même entité.
- 1.8 [Désactiver un client](manuel/desactiver-client.md) — M04 ; refus si une commande est marquée non payée ; suppression possible de l'entité commune.

### 2. Gérer les partenaires (commerces où les chèques sont dépensés)
- 2.1 [Ajouter un partenaire (recherche SIRET, reprise d'une entité existante)](manuel/ajouter-partenaire.md) — M05 intégrée localement (lot 03) ; recette à faire ; ajout partiel possible avant une erreur.
- 2.2 [Rechercher et consulter un partenaire](manuel/rechercher-consulter-partenaire.md) — M05 ; recherche sur le nom seulement ; distinction partenaire, client et bénéficiaire.
- 2.3 [Modifier les informations générales](manuel/modifier-partenaire.md) — M05 ; code partenaire obligatoire dans le formulaire mais non repris par l'action API lue.
- 2.4 [Attribuer des secteurs d'activité](manuel/attribuer-secteurs-partenaire.md) — M05 ; la sélection remplace la précédente ; **Créer** ajoute immédiatement au catalogue commun.
- 2.5 [Renseigner l'adresse](manuel/renseigner-adresse-partenaire.md) et [les informations bancaires](manuel/renseigner-coordonnees-bancaires-partenaire.md) — **indispensables pour rembourser** (rue, code postal, ville, IBAN et BIC) ; M05 ; IBAN français seulement par ce parcours.
- 2.6 [Donner accès à l'application au partenaire](manuel/donner-acces-application-partenaire.md) : QR code et lien de première connexion (copie ou envoi par e-mail) — M05 ; génération au clic, sans confirmation.
- 2.7 [Générer le QR code de réception](manuel/generer-qr-reception-partenaire.md) — M05 ; distinct du QR de première connexion et des QR de commande (6.5).
- 2.8 [Dupliquer un partenaire en client](manuel/dupliquer-partenaire-en-client.md) — M05 ; ajout du rôle client à la même entité ; refus sans message.
- 2.9 [Désactiver un partenaire](manuel/desactiver-partenaire.md) — M05 ; refus si le solde n'est pas nul ; aucune réactivation dans le BO, réversibilité non établie.

### 3. Gérer les secteurs d'activité
- 3.1 Créer un secteur (depuis le menu Secteurs ou depuis une fiche partenaire)
- 3.2 Supprimer un secteur (conséquence sur les partenaires associés)

### 4. Créer et suivre une commande
- 4.1 [Comprendre une commande](manuel/comprendre-commande.md) : offert par, occasion, lignes de chèques, date d'expiration, bons générés — M03 intégrée localement (lot 02).
- 4.2 [Créer une commande en saisie manuelle](manuel/creer-commande-manuelle.md) — fiche rédigée ; chat, refus de création par Néo et formulaire confirmés sans enregistrement de commande.
- 4.3 [Créer une commande par import CSV/XLSX](manuel/creer-commande-import-fichier.md) — M02 intégrée localement ; une ligne = un chèque, tentatives d'e-mails après création (pas une preuve de réception) ; recette distante à faire.
- 4.4 [Créer une commande depuis la fiche d'un client](manuel/creer-commande-depuis-client.md) — M03 ; icône sans libellé dans l'en-tête du client.
- 4.5 [Rechercher une commande](manuel/rechercher-commande.md) et lire la liste (colonnes, couleurs payé / non payé, pagination)
- 4.6 [Supprimer une commande](manuel/supprimer-commande.md) — M03 ; refus dès qu'un bon non annulé est attribué à un consommateur ou utilisé (y compris en papier) ; commande facturée à ne pas supprimer (règle du propriétaire, non imposée par le code lu).
- 4.7 [Modifier une commande](manuel/modifier-commande.md) — M03 ; lignes en lecture seule après facturation, import ou boutique en ligne.
- 4.8 [Changer la date de validité d'une commande](manuel/changer-validite-commande.md) — M03 ; toute la commande et ses bons non annulés.

### 5. Encaisser les paiements d'une commande
- 5.1 [Enregistrer un paiement](manuel/enregistrer-paiement-commande.md) — fiche rédigée ; guidage et champs confirmés sans enregistrement de paiement réel.
- 5.2 Choisir le compte encaisseur — cas du compte proposé ou imposé décrits dans la fiche [Enregistrer un paiement](manuel/enregistrer-paiement-commande.md).
- 5.3 Règles : pas de dépassement du total, pas de date antérieure au dernier paiement
- 5.4 [Supprimer un paiement](manuel/supprimer-paiement-commande.md) — fiche rédigée ; retour global positif de l’exploitant, sans détail des scénarios ni suppression réelle.
- 5.5 [Savoir si une commande est soldée](manuel/verifier-solde-commande.md) — M03 ; se fier aux montants si l'indicateur « payée » diverge.

### 6. Produire les documents d'une commande
- 6.1 [Générer la facture](manuel/generer-facture-commande.md) — M01 intégrée localement ; adresse préalable, référence modifiée si facture existante ; recette distante à faire.
- 6.2 Télécharger à nouveau une facture (menu Documents)
- 6.3 [Générer le bon de livraison](manuel/generer-bon-livraison-commande.md) — M01 intégrée ; facture préalable, limite URL à confirmer.
- 6.4 [Générer le récapitulatif](manuel/generer-recapitulatif-commande.md) — M01 intégrée ; CSV des bons ; recette distante à faire.
- 6.5 [Générer les QR codes (ZIP, génération en arrière-plan)](manuel/generer-qr-codes-commande.md) et [le CSV des UUID des bons](manuel/generer-csv-bons-commande.md) — M06 intégrée localement (lot 03) ; erreurs partielles possibles dans le manifeste du ZIP ; CSV distinct du récapitulatif (6.4).

### 7. Gérer les bons d'une commande
- 7.1 [Consulter les bons](manuel/consulter-bons-commande.md) (montant restant, donation, expiration, suppression) — M06 ; liste vide possible après un échec de lecture.
- 7.2 [Désactiver un bon](manuel/desactiver-bon.md) — impossible s'il est associé à un utilisateur ; M06 ; aucune réactivation proposée.
- 7.3 [Modifier la date d'expiration d'un bon](manuel/changer-expiration-bon.md) — M06 ; un seul bon, distinct de la validité de toute la commande (4.8).
- 7.4 [Consulter les bénéficiaires d'une commande importée](manuel/consulter-beneficiaires-commande-importee.md) — M06 ; fenêtre aussi éditable : consulter sans enregistrer.
- 7.5 [Renvoyer l'e-mail cadeau à un bénéficiaire](manuel/renvoyer-cadeau-beneficiaire.md) — M06 ; envoi immédiat sans confirmation, à l'adresse enregistrée.

### 8. Rembourser les partenaires
- 8.1 Comprendre le cycle : demande du partenaire → justificatif → ordre de virement SEPA
- 8.2 Éditer les justificatifs
- 8.3 Déclencher un remboursement et choisir le compte payeur
- 8.4 Remboursement bloqué : lire la liste des motifs et les corriger (justificatif, adresse, IBAN/BIC, montant nul)
- 8.5 Consulter l'historique des ordres de virement et retélécharger un fichier (menu Virements)
- 8.6 Le fichier à transmettre à la banque : le fichier `.TXT.SCT` contenu dans le ZIP `BTO_<date>.zip`. La procédure d'envoi propre à chaque banque est expliquée directement par Neofid au réseau, en amont : le manuel renvoie vers Neofid sans la détailler

### 9. Comptabilité
- 9.1 Générer les écritures comptables. Période couverte : du jour du dernier fichier généré jusqu'à **la veille** de la génération (le fichier est nommé `ECRITURES_<veille>.zip`). Les opérations du jour même seront dans le fichier suivant
- 9.2 Retélécharger un fichier d'écritures
- 9.3 Erreur de configuration (journal ou compte 512 manquant) : contacter Neofid
- 9.4 Factures de frais de gestion (menu Documents)

### 10. Statistiques et exports
- 10.1 Choisir un rapport, filtrer par période, exporter en CSV
- 10.2 Fiche par rapport : à quoi il sert, colonnes, période (11 rapports)
- 10.3 Retrouver les bons d'un bénéficiaire (rapport « Statut des QR codes par client »)

### 11. Questions fréquentes et dépannage
- Regroupe les messages d'erreur de tout le back-office, avec cause et solution (« Pensez à vérifier que votre client a une adresse… », « Le montant saisi dépasse… », « Aucun ordre de virement généré », etc.)
- Questions du type « pourquoi » : pourquoi je ne peux pas supprimer cette commande, désactiver ce client, ce bon…

### Annexes
- A. Prérequis entre écrans (voir ci-dessous)
- B. [Format du fichier d'import de commande](manuel/annexes/format-import-commande.md) — annexe M02 issue du code :
  - fichier **XLSX ou CSV** ; virgule recommandée ; points-virgules et tabulations remplacés globalement, y compris dans les valeurs ; conversion XLSX non exécutée ;
  - première ligne = en-têtes, sans tenir compte des majuscules ;
  - colonnes : `montant` (obligatoire, > 0), `email` et/ou `mobile` (au moins une des deux colonnes, et au moins une valeur par ligne ; e-mail au format valide), `prenom` et `nom` (facultatives) ;
  - une ligne = un chèque ; les lignes de même montant sont regroupées dans la commande ;
  - la date d'expiration, « Offert par » et l'occasion sont saisis dans le formulaire, pas dans le fichier ;
  - [CSV synthétique volontairement non importable](manuel/exemples/commande-import-exemple.csv) ; conserver le marqueur invalide et ne pas enregistrer pendant la recette.
- C. Ce que fait Neofid pour le réseau (comptes bancaires, journaux comptables, paramètres) et comment le contacter

---

## Prérequis entre écrans (annexe A)

| Pour… | Il faut d'abord… |
|---|---|
| Créer une commande | Un client existant (« Offert par ») |
| Générer une facture | L'adresse du client |
| Rembourser un partenaire | Adresse + IBAN/BIC du partenaire, justificatif édité, montant > 0 |
| Générer les écritures comptables | Comptes bancaires configurés par Neofid (journal, compte 512) |
| Désactiver un client | Aucune commande associée marquée non payée |
| Supprimer une commande | Aucun bon non annulé attribué ou utilisé ; commande non facturée |
| Désactiver un bon | Bon non associé à un utilisateur et non déjà désactivé |
| Désactiver un partenaire | Solde Tribuneo du partenaire nul dans le réseau |
| Renvoyer l'e-mail cadeau | Bon non annulé, non attribué, avec une adresse e-mail enregistrée |

---

## À clarifier avant la rédaction

**Informations manquantes :** aucune (réponses intégrées le 12 octobre : format d'import, période des écritures, fichier SEPA, mot de passe oublié).

**Incohérences relevées dans l'interface** (à corriger ou à documenter tel quel)
- Popup de désactivation d'un client intitulée « Désactiver le partenaire » (`customers_content_view.dart:297`).
- Tuile « Deconnexion » sans accent sur le tableau de bord.
- Formulaire d'adresse intitulé « …de ce commerçant » aussi pour les clients.
- Paiement sans méthode sélectionnée : message « Le montant saisi dépasse le montant total de la commande » au lieu de « choisissez une méthode » (`orders_content_view.dart:934-939`).
- « Code du partenaire » facultatif à la création, obligatoire à la modification (`update_partner_info_form.dart:189`) ; l'action API de mise à jour lue ne l'enregistre pas (relevé M05 du 30 octobre 2026).
- Menu Qrcode d'un partenaire : génération au clic sans confirmation, échec du QR sans message ; refus de désactivation d'un partenaire affiché par un message générique (relevé M05).
- Gestion des bons : bouton de désactivation fondé sur les contacts affichés, pas sur l'attribution vérifiée par l'API ; « Aucun bon associé à cette commande. » aussi après un échec de lecture ; ZIP QR sans affichage des erreurs partielles du manifeste (relevé M06 du 30 octobre 2026).
- Colonne « Facturé » de la liste des commandes : affiche le total de la commande, pas le montant facturé.
- Import de commande : le contrôle de l'occasion URSSAF est sauté, mais l'occasion est lue juste après (`order_form.dart:131-155`) ; un import sans occasion risque une erreur générique.
- Client professionnel : la fenêtre s'intitule « Partenaire existant », mais l'API cherche une entité par SIRET sans filtre partenaire ni réseau (relevé M04 du 30 octobre 2026). À confirmer comme voulu.

**Code non accessible depuis l'interface** (hors manuel) : `VoucherView`, `CardAction`, `list_test_widget`, `side_menu_widget.dart` (commenté), `tabbar_controller.dart`. `UpdateOrderForm` est en revanche ouvert par **Edition → Modifier** (relevé M03 du 30 octobre 2026).

---

## Ordre de rédaction suggéré

1. **Chapitres 4, 5 et 6** (commande, paiement, documents) : le cœur du métier, et le périmètre du MVP du chatbot.
2. **Chapitre 11** (dépannage) : très rentable pour le support.
3. **Chapitres 1, 2 et 8** (clients, partenaires, remboursements).
4. **Chapitres 0, 3, 7, 9 et 10**.
