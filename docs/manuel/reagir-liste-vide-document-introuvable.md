# Réagir à une liste vide ou à un document introuvable

## Objectif

Savoir quoi vérifier quand un tableau est vide ou qu'un élément attendu
n'apparaît pas, avant de recréer, de régénérer ou de conclure à une absence.

## Le principe

- Un tableau vide ne prouve pas l'absence de données : plusieurs écrans
  affichent une liste vide lorsque leur lecture a échoué, souvent sans message.
- Un document non visible ne prouve pas qu'il n'existe pas : il peut être sur
  une autre page, dans un autre onglet ou dans un autre écran.
- Ne créez pas de doublon et ne relancez pas une génération sur ce seul constat.

## Vérifications générales

1. Vérifiez l'écran et l'onglet : par exemple **Factures** ou
   **Frais de gestion** dans **Documents**.
2. Effacez la recherche et les filtres, revenez à la première page, puis
   parcourez la pagination.
3. Fermez puis rouvrez la fenêtre, ou rechargez la page, et attendez la fin du
   chargement.
4. Cherchez avec une autre référence : numéro commercial, nom exact, date.
5. Si l'élément reste introuvable alors qu'il devrait exister, arrêtez-vous et
   signalez-le avec ses références plutôt que de le recréer.

## Selon l'écran

| Écran ou élément | Pourquoi il peut sembler absent | Que vérifier | Fiche |
| --- | --- | --- | --- |
| **Liste des commandes** | Nombre limité de commandes chargées ; recherche sur les seules commandes chargées, par numéro, **Offert par** ou occasion | Le numéro commercial ; la première page ; le rechargement | [Rechercher une commande](rechercher-commande.md) |
| Fenêtre **Paiements** | Chargement en cours ou en échec ; colonne **Compte** masquée si les comptes ne sont pas chargés | Attendre, fermer et rouvrir | [Consulter les paiements](consulter-paiements-commande.md) |
| **Gestion des bons** | **Aucun bon associé à cette commande.** peut suivre un échec de lecture | Le numéro de commande ; rouvrir la fenêtre | [Consulter les bons](consulter-bons-commande.md) |
| **Bénéficiaires (commande importée)** | Donations et bons annulés exclus ; commande non importée | Distinguer **Aucun bénéficiaire pour cette commande.** et **Impossible de charger les bénéficiaires.** | [Bénéficiaires](consulter-beneficiaires-commande-importee.md) |
| Coordonnées vides dans **Gestion des bons** | Elles viennent du compte associé, pas de l'import | La fenêtre **Bénéficiaires** | [Consulter les bons](consulter-bons-commande.md) |
| **Liste des clients** | Recherche sur le nom seulement ; initiale choisie ; lecture en erreur | Le nom saisi ; la lettre affichée | [Rechercher un client](rechercher-client.md) |
| **Liste des magasins partenaires** | Recherche sur le nom seulement ; initiale accentuée ; partenaire désactivé absent | **Rechercher...** ; rouvrir **Partenaires** | [Rechercher un partenaire](rechercher-consulter-partenaire.md) |
| **Documents → Factures** | Dix lignes par page, sans recherche ; mauvais onglet ; lecture en erreur | La pagination ; l'onglet **Factures** | [Retélécharger une facture](retelecharger-facture-existante.md) |
| Bon de livraison | Il n'apparaît jamais dans **Documents** | **Commandes → Gestion → Générer le bon de livraison** | [Bon de livraison](generer-bon-livraison-commande.md) |
| **Documents → Frais de gestion** | Pagination ; lecture refusée ou en échec | La pagination ; rouvrir l'onglet | [Factures de frais](consulter-telecharger-factures-frais-gestion.md) |
| **Prochain virement** | Demande faite aujourd'hui, visible demain ; demande antérieure à la date de bascule ; demande déjà payée par un ordre | Distinguer **Aucune demande de remboursement en attente.** et **Impossible de charger l'aperçu du prochain virement.** | [Demandes de remboursement](consulter-demandes-remboursement.md) |
| **Virements** | Lecture en erreur | Rouvrir l'écran | [Ordres de virement](consulter-retelecharger-ordre-virement.md) |
| **Écritures comptables** | Lecture en erreur ; historique non rafraîchi après une génération | Quitter puis rouvrir **Écritures** ; la pagination | [Retélécharger les écritures](retelecharger-ecritures-comptables.md) |
| **Statistiques** | Même date en début et en fin ; droits insuffisants ; pagination restée sur une page avancée ; recherche non validée | Les dates ; **Rechercher** ; les premières pages | [Statistiques](consulter-exporter-statistiques.md) |
| **Toutes les infos clients** ou **partenaires** | Une fiche sans adresse, coordonnées bancaires, informations comptables ou code n'y figure pas | La fiche dans **Clients** ou **Partenaires** | [Infos clients](statistiques-informations-clients.md), [infos partenaires](statistiques-informations-partenaires.md) |
| **Secteurs d'activité** | Échec de chargement sans message | Rouvrir l'écran avant d'ajouter | [Créer un secteur](creer-secteur-activite.md) |
| Fichier téléchargé | Téléchargement bloqué ou enregistré ailleurs par le navigateur | Les téléchargements du navigateur | [QR codes](generer-qr-codes-commande.md) |

## Cas qui demandent une prudence particulière

- **Facture non visible** : elle peut avoir été créée malgré une erreur de
  téléchargement. Cherchez-la dans **Documents → Factures** avant toute
  nouvelle génération. Voir [Générer la facture](generer-facture-commande.md).
- **Paiement absent** : ne le ressaisissez pas avant d'avoir rouvert
  **Paiements** ; une nouvelle saisie enregistrerait un second paiement.
- **Ordre de virement absent** : rechargez **Prochain virement** et ouvrez
  **Virements** avant tout nouvel essai ; les demandes payées ne réapparaissent
  pas. Voir [Générer l'ordre de virement](generer-ordre-virement.md).
- **Lot d'écritures absent** : relisez l'historique avant de déclencher de
  nouveau ; un lot peut être enregistré sans que le ZIP soit reçu.
- **Client ou partenaire introuvable** : ne recréez pas la fiche ; pour un
  partenaire, refaites la recherche par SIRET de l'ajout.
- **Commande introuvable** : la liste chargée est limitée ; une commande
  ancienne peut exister sans y figurer.

## Lectures faites par Néo

Néo lit en lecture seule certaines données : clients, partenaires, commandes,
paiements, factures de commande, moyens de paiement et comptes bancaires du
réseau. Une réponse vide ou en erreur de ces lectures ne prouve pas davantage
l'absence de données. Les autres écrans de cette fiche ne sont pas lus par Néo.

## Signaler

Si l'élément reste introuvable, transmettez à votre interlocuteur habituel
l'écran, la référence recherchée (numéro commercial, numéro de facture,
nom de fichier, date) et ce que vous avez déjà vérifié. Ne communiquez ni mot
de passe, ni jeton, ni IBAN complet.

## Avec Néo

Demandez par exemple : « Le tableau des paiements est vide, est-ce que la
commande n'a pas de paiement ? » ou « Je ne trouve pas la facture dans
Documents. ». Néo indique les vérifications utiles et la fiche de la tâche ;
il ne recrée ni ne régénère aucun élément.

Vérification au 30 octobre 2026 : comportements de liste vide, de pagination,
de recherche et de chargement repris des 73 fiches vérifiées des lots 01 à 05.
Aucune opération métier ni appel réseau.
