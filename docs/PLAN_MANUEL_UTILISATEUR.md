# Plan du manuel utilisateur du back-office Tribuneo

Plan établi le 12 octobre 2026 à partir du code du back-office (`lib/presentation/`). Le manuel n'existe pas encore : ce document fixe sa structure avant la rédaction.

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
- 1.1 Ajouter un client particulier
- 1.2 Ajouter un client professionnel (recherche SIRET)
- 1.3 Rechercher et filtrer les clients (recherche, A–Z, onglets d'affichage)
- 1.4 Modifier les informations générales
- 1.5 Renseigner ou modifier l'adresse — **indispensable pour facturer**
- 1.6 Renseigner ou modifier les informations bancaires (remplissage automatique depuis l'IBAN)
- 1.7 Dupliquer un client en partenaire
- 1.8 Désactiver un client — impossible tant qu'une commande n'est pas entièrement payée

### 2. Gérer les partenaires (commerces où les chèques sont dépensés)
- 2.1 Ajouter un partenaire (recherche SIRET, reprise d'un partenaire existant)
- 2.2 Rechercher et consulter un partenaire (solde Tribuneo, secteurs, dématérialisation)
- 2.3 Modifier les informations générales — le code partenaire devient obligatoire
- 2.4 Attribuer des secteurs d'activité
- 2.5 Renseigner l'adresse et les informations bancaires — **indispensables pour rembourser**
- 2.6 Donner accès à l'application au partenaire : QR code de première connexion, lien de première connexion (copie ou envoi par e-mail)
- 2.7 Générer le QR code de réception
- 2.8 Dupliquer un partenaire en client
- 2.9 Désactiver un partenaire

### 3. Gérer les secteurs d'activité
- 3.1 Créer un secteur (depuis le menu Secteurs ou depuis une fiche partenaire)
- 3.2 Supprimer un secteur (conséquence sur les partenaires associés)

### 4. Créer et suivre une commande
- 4.1 Comprendre une commande : offert par, occasion, lignes de chèques, date d'expiration, bons générés
- 4.2 Créer une commande en saisie manuelle (une ou plusieurs valeurs de chèque, message personnalisé, personnalisation « offert par »)
- 4.3 Créer une commande par import de fichier (CSV / XLSX) : une ligne = un chèque nominatif, et le bénéficiaire reçoit un e-mail cadeau (format en annexe B)
- 4.4 Créer une commande depuis la fiche d'un client
- 4.5 Rechercher une commande et lire la liste (colonnes, couleurs payé / non payé, pagination)
- 4.6 Supprimer une commande — impossible dès qu'un bon a été scanné

### 5. Encaisser les paiements d'une commande
- 5.1 Enregistrer un paiement (date, méthode, montant, confirmation)
- 5.2 Choisir le compte encaisseur (réseau à plusieurs comptes ; cas du compte imposé)
- 5.3 Règles : pas de dépassement du total, pas de date antérieure au dernier paiement
- 5.4 Supprimer un paiement (et pourquoi c'est parfois refusé : écritures comptables déjà générées)
- 5.5 Savoir si une commande est soldée

### 6. Produire les documents d'une commande
- 6.1 Générer la facture (informations supplémentaires, référence commande) — prérequis : adresse du client
- 6.2 Télécharger à nouveau une facture (menu Documents)
- 6.3 Générer le bon de livraison
- 6.4 Générer le récapitulatif
- 6.5 Générer les QR codes (ZIP, génération en arrière-plan) et le CSV des bons

### 7. Gérer les bons d'une commande
- 7.1 Consulter les bons (montant restant, bénéficiaire, donation, expiration)
- 7.2 Désactiver un bon — impossible s'il est associé à un utilisateur
- 7.3 Modifier la date d'expiration d'un bon

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
- B. Format du fichier d'import de commande (d'après `OrderFileCreateAction.php` de l'API) :
  - fichier **XLSX ou CSV** ; en CSV, séparateur `,`, `;` ou tabulation ;
  - première ligne = en-têtes, sans tenir compte des majuscules ;
  - colonnes : `montant` (obligatoire, > 0), `email` et/ou `mobile` (au moins une des deux colonnes, et au moins une valeur par ligne ; e-mail au format valide), `prenom` et `nom` (facultatives) ;
  - une ligne = un chèque ; les lignes de même montant sont regroupées dans la commande ;
  - la date d'expiration, « Offert par » et l'occasion sont saisis dans le formulaire, pas dans le fichier ;
  - fournir un fichier exemple téléchargeable.
- C. Ce que fait Neofid pour le réseau (comptes bancaires, journaux comptables, paramètres) et comment le contacter

---

## Prérequis entre écrans (annexe A)

| Pour… | Il faut d'abord… |
|---|---|
| Créer une commande | Un client existant (« Offert par ») |
| Générer une facture | L'adresse du client |
| Rembourser un partenaire | Adresse + IBAN/BIC du partenaire, justificatif édité, montant > 0 |
| Générer les écritures comptables | Comptes bancaires configurés par Neofid (journal, compte 512) |
| Désactiver un client | Toutes ses commandes payées |
| Supprimer une commande | Aucun bon scanné |
| Désactiver un bon | Bon non associé à un utilisateur |

---

## À clarifier avant la rédaction

**Informations manquantes :** aucune (réponses intégrées le 12 octobre : format d'import, période des écritures, fichier SEPA, mot de passe oublié).

**Incohérences relevées dans l'interface** (à corriger ou à documenter tel quel)
- Popup de désactivation d'un client intitulée « Désactiver le partenaire » (`customers_content_view.dart:297`).
- Tuile « Deconnexion » sans accent sur le tableau de bord.
- Formulaire d'adresse intitulé « …de ce commerçant » aussi pour les clients.
- Paiement sans méthode sélectionnée : message « Le montant saisi dépasse le montant total de la commande » au lieu de « choisissez une méthode » (`orders_content_view.dart:934-939`).
- « Code du partenaire » facultatif à la création, obligatoire à la modification (`update_partner_info_form.dart:189`).
- Colonne « Facturé » de la liste des commandes : affiche le total de la commande, pas le montant facturé.
- Import de commande : le contrôle de l'occasion URSSAF est sauté, mais l'occasion est lue juste après (`order_form.dart:131-155`) ; un import sans occasion risque une erreur générique.
- Client professionnel : la recherche SIRET passe par la recherche de **partenaire**. À confirmer comme voulu.

**Code non accessible depuis l'interface** (hors manuel) : `VoucherView`, `UpdateOrderForm`, `CardAction`, `list_test_widget`, `side_menu_widget.dart` (commenté), `tabbar_controller.dart`.

---

## Ordre de rédaction suggéré

1. **Chapitres 4, 5 et 6** (commande, paiement, documents) : le cœur du métier, et le périmètre du MVP du chatbot.
2. **Chapitre 11** (dépannage) : très rentable pour le support.
3. **Chapitres 1, 2 et 8** (clients, partenaires, remboursements).
4. **Chapitres 0, 3, 7, 9 et 10**.
