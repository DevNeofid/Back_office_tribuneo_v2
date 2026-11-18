# Comprendre le tableau de bord

## Objectif

Utiliser l'accueil et interpréter correctement ses cartes et le signal de
remboursement. Ouvrez **Accueil** dans le menu latéral. L'en-tête affiche la
date du jour au-dessus de « Bonjour » suivi du nom du réseau. Cet accueil
remplace l'ancien écran de bienvenue à tuiles (Commandes, Partenaires,
Clients, Déconnexion). La déconnexion se fait depuis la carte du réseau, en
bas du menu : voir [Se déconnecter](se-deconnecter-back-office.md).

Le bouton orange **Nouvelle commande**, à droite du titre, ouvre seulement
l'écran **Commandes**. La saisie commence ensuite avec
**Ajouter une commande** : voir
[Créer une commande en saisie manuelle](creer-commande-manuelle.md).

## À traiter

Cette section regroupe jusqu'à trois cartes. Le nombre affiché à côté du titre
compte les cartes qui demandent une action : prochain virement avec des
demandes prêtes, et import en relecture.

| Carte | Contenu | Bouton |
| --- | --- | --- |
| **PROCHAIN VIREMENT** | Montant à virer ; nombre de demandes et de commerçants, date de fin de période et mention « prêt » s'il y a des demandes à payer, sinon « Aucune demande prête à être payée » ; nombre de demandes hors virement, s'il y en a. | **Préparer le virement** ouvre **Prochain virement**. |
| **IMPORT DE COMMERÇANTS** | Affichée seulement si un lot récent est **En relecture** : fichier, date de dépôt, anomalies, lignes à relire et validées. | **Reprendre la relecture** ouvre **Import**. |
| **ÉCRITURES COMPTABLES** | Affichée dès qu'un fichier existe : nombre de fichiers, date et nom du dernier fichier généré. | **Ouvrir les écritures** ouvre **Écritures**. |

Ces boutons ouvrent seulement l'écran concerné. **Préparer le virement** ne
génère aucun ordre de virement ; la carte des écritures ne signale pas qu'une
nouvelle génération est due. Voir
[Consulter les demandes de remboursement](consulter-demandes-remboursement.md)
et [Générer les écritures comptables](generer-ecritures-comptables.md).

## Dernières commandes

Le tableau présente les cinq dernières commandes : numéro et occasion,
**Offert par**, **Montant** et **Paiement**. La pastille **Payée**,
**Non payée** ou **Écart +x €** / **Écart −x €** compare le montant payé au
total ; elle ne dit rien de la facture. Voir
[Vérifier le solde et le statut payé](verifier-solde-commande.md).

Un clic sur une ligne ouvre **Commandes**, la recherche remplie avec le numéro
de la commande. **Tout voir** ouvre la liste complète. Sans commande, le
tableau affiche « Aucune commande pour le moment. ».

## Raccourcis et derniers virements

| Élément | Destination |
| --- | --- |
| **Ajouter un client** | Écran **Clients** |
| **Ajouter un partenaire** | Écran **Magasins partenaires** |
| **Importer des commerçants** | Écran **Import de commerçants** |
| **Exporter une statistique** | Écran **Statistiques** |
| **Derniers virements** | Trois derniers ordres de virement : date, compte s'il y en a plusieurs, montant remboursé. **Historique** ouvre **Virements**. |

Les raccourcis ouvrent seulement l'écran : ils ne créent ni client, ni
partenaire, ni import, ni export. La carte **Derniers virements** est absente
tant qu'aucun ordre n'existe ; elle montre des ordres générés, pas des
virements exécutés.

## Bloc en erreur

Chaque bloc se charge séparément. Une carte **À traiter** en échec affiche
**Chargement impossible** et le bouton **Réessayer**. Les dernières commandes
affichent alors **Impossible de charger les dernières commandes.** et les
derniers virements **Impossible de charger les derniers virements.**, avec
**Réessayer**. Un bloc en erreur ou absent ne prouve pas qu'il n'y a rien à
traiter : ouvrez l'écran concerné. Voir
[Réagir à une liste vide ou à un document introuvable](reagir-liste-vide-document-introuvable.md).

## Indicateur de remboursement

La pastille orange « 1 » figure dans le menu **Prochain virement**. Elle est
activée lorsqu'un chargement de l'aperçu signale au moins une demande prête
à payer. Ce sont les demandes retenues par la sélection du prochain virement,
après ses contrôles : il ne s'agit ni de toutes les demandes reçues, ni des
seules demandes nouvellement arrivées.

Cette pastille n'est ni un montant, ni un compteur (elle affiche toujours
« 1 »), ni une preuve de virement exécuté. Ouvrir **Prochain virement** retire
le signal visuel ; cela ne paie aucune demande. Pour lire et traiter
l'aperçu, voir
[Consulter les demandes de remboursement](consulter-demandes-remboursement.md).
La génération d'un ordre et son traitement bancaire sont des étapes distinctes.

Le contrôle de la pastille a lieu à l'ouverture de la page et lors des
changements vers les autres menus. Il n'y a pas de rafraîchissement périodique
prouvé. Une lecture en erreur ne bloque pas la navigation ; une pastille déjà
allumée n'est pas systématiquement éteinte si la sélection devient vide.
Sa présence ou son absence ne remplace donc pas la vérification de l'aperçu.

## Ce que cet accueil ne fournit pas

L'accueil ne présente ni chiffre d'affaires, ni totaux de commandes, de soldes
ou de remboursements sur une période, ni graphique. Ses montants se limitent à
l'aperçu du prochain virement, aux cinq dernières commandes et aux trois
derniers ordres de virement.
Le menu **Statistiques** est l'entrée des rapports détaillés : voir
[Consulter et exporter les statistiques](consulter-exporter-statistiques.md).

## Portée de l'aide Néo

Néo explique les cartes, les raccourcis et la pastille. Il ne transforme pas ces
indicateurs en preuve de paiement et ne déclenche aucun virement.

Vérification au 30 octobre 2026 : vue, indices des callbacks, calcul de la
pastille, repository et sélection API lus. Aucun aperçu live appelé.

Libellés relus le 2 novembre 2026 : tranche 1 M15, sans changement de logique.
Recette visuelle et opérations en session non exécutées pour cette mise à jour.
