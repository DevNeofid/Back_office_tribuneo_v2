# Désactiver un partenaire et comprendre les refus

## Objectif et prérequis

Retirer un commerce de la liste des partenaires du réseau courant avec l'action
**Désactiver ce partenaire** de **Partenaires**, écran
**Liste des magasins partenaires**. Identifiez sans ambiguïté la fiche et
contrôlez son **Solde Tribuneo actuel** dans l'onglet **Informations générales** :
l'API refuse la désactivation tant que le solde du commerçant dans le réseau
n'est pas nul. Ce contrôle utilise une requête différente de celle de
l'affichage ; le solde affiché est un repère, pas une garantie.

## Étapes

1. Retrouvez le partenaire avec
   [Rechercher et consulter un partenaire](rechercher-consulter-partenaire.md)
   et vérifiez son nom et son SIRET.
2. Ouvrez le menu à trois points (**Afficher le Menu**), puis
   **Désactiver ce partenaire**.
3. La boîte **Désactiver le partenaire** demande :
   **Êtes-vous sûr de vouloir désactiver ce partenaire ?**
4. **Annuler** ferme sans opération. **Désactiver** envoie la demande réelle ;
   ne l'utilisez pas pour une vérification.
5. Après **Partenaire désactivé avec succès !**, la liste se recharge et le
   partenaire n'y apparaît plus.

## Refus prévus par l'API

| Situation | Réponse de l'API |
| --- | --- |
| Aucun compte d'application commerçant lié à l'entité | 404, `No shop admin user found for this entity.` |
| Solde Tribuneo du partenaire dans le réseau supérieur à zéro | 409, motif `FUND_NOT_EMPTY` avec le montant |
| Entité non rattachée au réseau, ou rôle partenaire déjà désactivé | erreur serveur |

Le BO affiche le même message pour toutes ces réponses :
**Erreur lors de la désactivation du partenaire.** Il ne précise ni la cause ni
le montant restant. Une exception peut afficher
**Erreur lors de la désactivation du partenaire : …**.

En cas de refus, consultez le solde de la carte. Un solde restant relève du
remboursement du partenaire, qui n'est pas décrit ici. Ne créez pas d'opération
pour vider artificiellement un solde et ne réessayez pas en boucle.

## Portée réelle de l'action

D'après le code lu, l'action marque comme supprimé le seul rôle partenaire de
l'entité **dans le réseau courant**. Elle ne supprime pas l'entité, ne retire
pas son éventuel rôle client, et ne modifie ni son adresse, ni ses
coordonnées bancaires, ni ses secteurs, ni son compte d'application.

Cela ne constitue pas une garantie d'archivage réversible :

- aucune réactivation n'est proposée dans le BO ;
- l'effet sur la connexion du commerçant à l'application et sur ses opérations
  en cours n'est pas établi par les sources lues ;
- l'absence d'effet dans d'autres réseaux n'a pas été vérifiée par un essai.

N'annoncez donc pas au commerçant une remise en service possible. Si l'entité
est aussi cliente, ce rôle se gère séparément ; la désactivation d'un client
obéit à d'autres règles, décrites dans
[Désactiver un client](desactiver-client.md).

## Portée de l'aide Néo

Néo explique l'action et ses refus ; il ne désactive aucun partenaire et
n'effectue aucun remboursement.

Vérification au 30 octobre 2026 : menu, confirmation, repository, action API,
requêtes de contrôle du solde et de désactivation lus. Désactivation réelle,
refus en session, effets sur l'application et restauration non testés.
