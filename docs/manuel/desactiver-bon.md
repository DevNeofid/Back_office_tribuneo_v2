# Désactiver un bon d'une commande

## Objectif et prérequis

Désactiver un bon individuel depuis **Gestion des bons**, avec les droits
d'administration du réseau. La désactivation renseigne sa date de suppression.
Aucun parcours de réactivation n'est proposé dans cette fenêtre.

## Étapes

1. Dans **Commandes**, retrouvez la commande puis ouvrez
   **Gestion → Gestion des bons** : voir
   [Consulter les bons d'une commande](consulter-bons-commande.md).
2. Repérez le bon avec son **ID**, son **Montant** et son **Montant restant**.
   Contrôlez aussi **Nom**, **Email**, **Téléphone** et **Suppression**.
3. Dans **Action**, cliquez sur l'icône de blocage dont l'infobulle indique
   **Désactiver le bon**, si elle est disponible.
4. La confirmation **Désactiver un bon** rappelle le numéro du bon et son
   montant : **Êtes-vous sûr de vouloir désactiver le bon n°… de … € ?**
   Choisissez **Annuler** pour renoncer, ou **Désactiver** pour effectuer l'action.
5. Après **Bon désactivé avec succès.**, le tableau se recharge. Vérifiez la
   date dans **Suppression**, puis utilisez **Fermer**.

## Disponibilité et refus

- **Bon déjà désactivé** : le bouton est grisé si une date de suppression est
  présente.
- **Bon associé à un utilisateur, désactivation impossible** : le BO grise le
  bouton dès qu'un nom, un e-mail ou un téléphone est affiché pour le compte
  associé.
- Le serveur vérifie séparément si le bon est attribué à un compte utilisateur.
  Il peut donc refuser une désactivation même si le bouton semblait disponible,
  notamment si les informations affichées étaient incomplètes ou ont changé.
- Le montant restant n'est pas le critère qui rend ce bouton disponible. Un
  restant égal au montant initial ne prouve pas que le bon est non attribué.

## Messages et résultat incertain

| Message | Suite utile |
|---|---|
| **Bon désactivé avec succès.** | Contrôlez **Suppression** dans le tableau rechargé. |
| **Impossible de désactiver ce bon : il est associé à un utilisateur.** | Refus du serveur : ne cherchez pas à contourner l'attribution. |
| **Bon introuvable.** | Le bon est introuvable ou n'a pas pu être mis à jour ; fermez puis rouvrez la liste pour vérifier son état. |
| **Erreur lors de la désactivation du bon.** | L'effet est incertain : vérifiez d'abord **Suppression** en rouvrant la fenêtre avant toute nouvelle tentative. |

Un tableau vide après rechargement ne prouve pas le succès de l'opération ; il
peut masquer une erreur de lecture. En cas de doute, faites vérifier le bon avec
ses références.

## Portée et aide Néo

Écran **Liste des commandes**, fenêtre **Gestion des bons - Commande …**.
Cette action concerne un bon et ne constitue pas une procédure de remboursement.
La suppression de toute la commande relève de
[Supprimer une commande](supprimer-commande.md).

Demandez à Néo : « Comment désactiver un bon ? » ou « Pourquoi le bouton de
désactivation du bon est-il grisé ? ». Néo guide l'utilisateur ; il ne
désactive aucun bon et ne confirme pas un effet qu'il n'a pas vérifié.
