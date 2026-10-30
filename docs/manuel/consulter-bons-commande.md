# Consulter les bons d'une commande

## Objectif et prérequis

Consulter le montant restant, la donation, les coordonnées affichées et la date
d'expiration de chaque bon depuis une commande existante. Ce parcours nécessite
les droits d'administration du réseau.

## Étapes

1. Ouvrez **Commandes**, écran **Liste des commandes**, et retrouvez la commande
   avec **Rechercher** : voir [Rechercher une commande](rechercher-commande.md).
2. Sur sa ligne, ouvrez l'icône de la colonne **Gestion**, puis **Gestion des bons**.
3. Attendez le chargement de **Gestion des bons - Commande …** et vérifiez le
   numéro de commande dans le titre.
4. Lisez les colonnes ci-dessous. Si nécessaire, faites défiler le tableau
   horizontalement pour atteindre **Expiration**, **Suppression** et **Action**.
5. Utilisez **Fermer** pour revenir aux commandes.

| Colonne | Lecture |
|---|---|
| **ID** | Identifiant composé du réseau, du bon et de la commande. Il diffère du numéro commercial de commande. |
| **Montant** | Valeur du bon. |
| **Montant restant** | Reste enregistré pour ce bon. Ce chiffre ne garantit pas à lui seul que le bon est encore utilisable : regardez aussi son expiration et sa suppression. |
| **Donation** | **Oui** si le bon est marqué comme donation, **Non** sinon. Ce n'est pas un bouton pour faire un don. |
| **Nom**, **Email**, **Téléphone** | Coordonnées du compte consommateur associé, lorsqu'il est retrouvé. Elles ne reprennent pas les coordonnées d'import d'un bon encore non attribué. |
| **Expiration** | Date propre à ce bon ; un tiret est affiché si la date est absente. |
| **Suppression** | Date de désactivation lorsqu'elle est renseignée ; un tiret sinon. Les bons désactivés peuvent rester visibles dans ce tableau. |

## Bénéficiaire et limites de lecture

Des coordonnées vides ne prouvent pas l'absence de bénéficiaire prévu. Pour les
contacts enregistrés sur des bons importés, ouvrez plutôt
[Bénéficiaires (commande importée)](consulter-beneficiaires-commande-importee.md).
Cette seconde liste exclut les donations et les bons annulés : les deux tableaux
n'ont donc pas nécessairement le même nombre de lignes.

**Aucun bon associé à cette commande.** peut aussi apparaître après un échec de
lecture, car cette vue reçoit alors une liste vide. Vérifiez la commande,
fermez puis rouvrez la fenêtre ; si le doute persiste, faites vérifier le
chargement avant de conclure qu'il n'existe aucun bon. Ce tableau ne constitue
pas un historique exhaustif des bons du réseau.

La colonne **Expiration** de la liste des commandes concerne toute la commande.
La date d'un bon peut différer : voir
[Changer l'expiration d'un bon](changer-expiration-bon.md). Pour les règles
globales, voir [Changer la validité d'une commande](changer-validite-commande.md).

## Autres actions et aide Néo

La colonne **Action** propose, selon le bon, la
[désactivation](desactiver-bon.md), le changement d'expiration et le
[renvoi d'e-mail cadeau](renvoyer-cadeau-beneficiaire.md).

Demandez à Néo : « Où consulter le montant restant d'un bon de commande ? ».
Néo explique les colonnes et le parcours ; ses outils actuels ne lisent pas
cette liste de bons et n'effectuent aucune de ces actions.
