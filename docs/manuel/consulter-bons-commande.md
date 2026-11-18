# Consulter les bons d'une commande

## Objectif et prérequis

Consulter le montant restant, la donation, les coordonnées affichées et la date
d'expiration de chaque bon depuis une commande existante. Ce parcours nécessite
les droits d'administration du réseau.

## Étapes

1. Ouvrez **Commandes** et retrouvez la commande avec la recherche
   **Rechercher par numéro de commande, offert par, etc.** : voir
   [Rechercher une commande](rechercher-commande.md).
2. Sur sa ligne, ouvrez l'icône de la colonne **Gestion**, puis **Gestion des bons**.
3. Le panneau **Bons de la commande** s'ouvre à droite (anciennement
   **Gestion des bons - Commande …**). Attendez le chargement et vérifiez le
   numéro de commande affiché au-dessus du titre, suivi de l'offrant et de
   l'occasion. Une pastille indique le nombre de bons et leur montant total.
4. Lisez les colonnes ci-dessous. Si nécessaire, faites défiler le tableau
   horizontalement pour atteindre **Expiration**, **État** et **Action**.
5. Fermez le panneau avec le bouton ✕ **Fermer** en haut à droite, ou cliquez
   en dehors du panneau, pour revenir aux commandes.

| Colonne | Lecture |
|---|---|
| **Bon** | Identifiant composé du réseau, du bon et de la commande. Il diffère du numéro commercial de commande. |
| **Bénéficiaire** | Nom et e-mail du compte consommateur associé, lorsqu'il est retrouvé ; sans e-mail, **Aucune adresse e-mail pour ce bon** s'affiche. Ces coordonnées ne reprennent pas celles d'import d'un bon encore non attribué. |
| **Téléphone** | Téléphone de ce même compte associé, s'il est renseigné. |
| **Montant** | Valeur du bon. |
| **Restant** | Reste enregistré pour ce bon (anciennement **Montant restant**). Ce chiffre ne garantit pas à lui seul que le bon est encore utilisable : regardez aussi son expiration et son état. |
| **Expiration** | Date propre à ce bon ; la case reste vide si la date est absente. |
| **État** | **Désactivé** si le bon a une date de désactivation (l'infobulle la donne : « Désactivé le … ») ; sinon **Associé à un utilisateur** dès qu'un nom, un e-mail ou un téléphone est affiché, ou **Actif**. Les bons désactivés peuvent rester visibles dans ce tableau. Une pastille **Don** s'ajoute si le bon est marqué comme donation (anciennement colonne **Donation**) ; ce n'est pas un bouton pour faire un don. |

## Bénéficiaire et limites de lecture

Des coordonnées vides ne prouvent pas l'absence de bénéficiaire prévu. Pour les
contacts enregistrés sur des bons importés, ouvrez plutôt
[Bénéficiaires (commande importée)](consulter-beneficiaires-commande-importee.md).
Cette seconde liste exclut les donations et les bons annulés : les deux tableaux
n'ont donc pas nécessairement le même nombre de lignes.

**Aucun bon associé à cette commande.** peut aussi apparaître après un échec de
lecture, car cette vue reçoit alors une liste vide. Vérifiez la commande,
fermez puis rouvrez le panneau ; si le doute persiste, faites vérifier le
chargement avant de conclure qu'il n'existe aucun bon. Ce tableau ne constitue
pas un historique exhaustif des bons du réseau.

La colonne **Expiration** de la liste des commandes concerne toute la commande.
La date d'un bon peut différer : voir
[Changer l'expiration d'un bon](changer-expiration-bon.md). Pour les règles
globales, voir [Changer la validité d'une commande](changer-validite-commande.md).

## Autres actions et aide Néo

Dans la colonne **Action**, le bouton **…** (infobulle **Actions du bon**)
propose **Renvoyer l'e-mail**
([renvoi d'e-mail cadeau](renvoyer-cadeau-beneficiaire.md)),
**Modifier la date d'expiration** et **Désactiver le bon**
([désactivation](desactiver-bon.md)). Un choix indisponible reste visible,
grisé, avec sa raison en dessous.

Demandez à Néo : « Où consulter le montant restant d'un bon de commande ? ».
Néo explique les colonnes et le parcours ; ses outils actuels ne lisent pas
cette liste de bons et n'effectuent aucune de ces actions.
