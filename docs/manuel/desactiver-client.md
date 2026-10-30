# Désactiver un client et comprendre les refus

## Objectif et prérequis

Utiliser l'action **Désactiver ce client** de **Clients**, écran
**Liste des clients**, après avoir identifié sans ambiguïté la fiche concernée.
Cette action exige des droits de gestion et peut être refusée si des commandes
associées sont marquées non payées.

Le libellé « désactiver » ne garantit pas un simple archivage réversible.
Lorsqu'aucun rôle partenaire n'est trouvé dans le réseau courant, l'action API
lue appelle une suppression de l'entité commune. Aucun parcours de restauration
de cette action n'est établi ici. Vérifiez la portée avec votre responsable
avant de confirmer, notamment si l'entité existe dans d'autres réseaux.

## Étapes

1. Dans **Clients**, retrouvez le client et contrôlez son nom et ses informations.
2. Ouvrez le menu d'actions à trois points dans l'en-tête, puis choisissez
   **Désactiver ce client**.
3. Le dialogue est titré **Désactiver le partenaire**, bien que la question
   soit **Êtes-vous sûr de vouloir désactiver ce client ?**. Ce titre est
   incohérent : le parcours documenté reste celui de **Clients**.
4. Choisissez **Annuler** pour fermer sans opération. **Désactiver** envoie la
   demande réelle ; ne l'utilisez pas pour une recette documentaire.
5. Après **Client désactivé avec succès !**, vérifiez l'état des données avant
   de considérer l'action terminée. La seule disparition d'une fiche ne
   prouve pas sa suppression ni l'état d'un éventuel partenaire.

## Refus et portée de l'action

| Situation contrôlée par l'API | Réponse prévue |
| --- | --- |
| Entité introuvable | 404, `Entity not found` |
| Absence du type client dans le réseau courant | 404, `Entity is not a customer` |
| Au moins une commande associée non supprimée marquée non payée | 400, `Cannot delete entity with unpaid orders` |

Le contrôle de paiement lit le statut « payé » des commandes ; il ne recalcule
pas ici un solde à partir des lignes de paiement.

Pour toute réponse API autre que 200, le BO peut afficher le même message :
**Erreur lors de la désactivation du client, au moins une commande associée n'est pas totalement payée.**
Ce texte ne prouve donc pas que des impayés sont la cause réelle. Une exception
peut afficher **Erreur lors de la désactivation : …**.

Si un refus apparaît, vérifiez l'état de la fiche et, si nécessaire, consultez
les commandes et leurs paiements en lecture seule. Ne créez pas de paiement
pour tester la désactivation et ne réessayez pas automatiquement après une
réponse incertaine. Les fiches « Rechercher une commande » et « Consulter les
paiements d'une commande » couvrent ces consultations.

Si l'entité est aussi partenaire du réseau courant, l'API retire le type client
de ce réseau et conserve l'entité pour son autre rôle. Sinon, elle appelle la
suppression de l'entité commune puis retire le type client du réseau courant.
Cette branche ne constitue pas une procédure de désactivation de partenaire,
et la conservation des données ou la réversibilité ne sont pas garanties.

## Portée de l'aide Néo

Néo explique l'action et les refus ; il ne désactive ni client ni partenaire et
n'effectue aucune suppression ou opération de paiement.

Vérification au 30 octobre 2026 : interface, repository, action API et requête
des commandes non payées lus. Confirmation en session, refus réels, suppression,
effets sur d'autres réseaux et restauration non testés.
