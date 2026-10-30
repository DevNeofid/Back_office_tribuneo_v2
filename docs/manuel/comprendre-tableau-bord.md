# Comprendre le tableau de bord

## Objectif

Utiliser l'accueil et interpréter correctement le signal de remboursement.
Ouvrez **Accueil** dans le menu latéral. La vue affiche le message
**Bienvenue sur votre espace de gestion**.

## Raccourcis actifs

| Tuile | Destination |
| --- | --- |
| **Commandes** | **Liste des commandes**, comme le menu **Commandes**. |
| **Partenaires** | **Liste des magasins partenaires**, comme le menu **Partenaires**. |
| **Clients** | **Liste des clients**, comme le menu **Clients**. |
| **Deconnexion** | Déconnexion immédiate et retour à l'écran de connexion, sans confirmation. |

Les trois premières tuiles ouvrent leurs listes ; elles ne créent ni client,
ni partenaire, ni commande. Ne cliquez sur **Deconnexion** que pour quitter
votre session. La procédure figure dans
[Se déconnecter](se-deconnecter-back-office.md).

## Indicateur de remboursement

La pastille rouge figure dans le menu **Prochain virement**. Elle est activée
lorsqu'un chargement de l'aperçu signale au moins une demande prête à payer.
Ce sont les demandes retenues par la sélection du prochain virement, après
ses contrôles : il ne s'agit ni de toutes les demandes reçues, ni des seules
demandes nouvellement arrivées.

Cette pastille n'est ni un montant, ni un compteur, ni une preuve de virement
exécuté. Ouvrir **Prochain virement** retire le signal visuel ; cela ne paie
aucune demande. Pour lire et traiter l'aperçu, voir
[Consulter les demandes de remboursement](consulter-demandes-remboursement.md).
La génération d'un ordre et son traitement bancaire sont des étapes distinctes.

Le contrôle de la pastille a lieu à l'ouverture de la page et lors des
changements vers les autres menus. Il n'y a pas de rafraîchissement périodique
prouvé. Une lecture en erreur ne bloque pas la navigation ; une pastille déjà
allumée n'est pas systématiquement éteinte si la sélection devient vide.
Sa présence ou son absence ne remplace donc pas la vérification de l'aperçu.

## Ce que cet accueil ne fournit pas

Le tableau de bord actif ne présente pas de totaux chiffrés de ventes,
commandes, soldes ou remboursements, ni de graphiques actifs. Des composants
anciens ou commentés ne constituent pas des indicateurs disponibles.
Le menu **Statistiques** est l'entrée des rapports détaillés.

## Portée de l'aide Néo

Néo explique les raccourcis et la pastille. Il ne transforme pas cet indicateur
en preuve de paiement et ne déclenche aucun virement.

Vérification au 30 octobre 2026 : vue, indices des callbacks, calcul de la
pastille, repository et sélection API lus. Aucun aperçu live appelé.
