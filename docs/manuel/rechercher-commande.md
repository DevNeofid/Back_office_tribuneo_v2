# Rechercher une commande

## Objectif

Retrouver une commande existante dans le back-office à partir de son numéro,
de la mention « Offert par » ou de son occasion.

## Prérequis

- Être connecté au back-office du réseau concerné.
- Disposer du numéro commercial de la commande ou d'un texte présent dans
  **Offert par** ou **Occasion**.

## Étapes

1. Dans le menu latéral, ouvrez **Commandes**. L'écran porte le titre
   **Liste des commandes**.
2. Repérez le champ **Rechercher**, dont l'indication est
   **Rechercher par numéro de commande, offert par, etc.**
3. Saisissez le numéro commercial de la commande, en entier ou en partie.
   Vous pouvez aussi saisir un texte présent dans **Offert par** ou **Occasion**.
4. La liste se filtre pendant la saisie : il n'est pas nécessaire de valider
   avec la touche Entrée. Vérifiez la colonne **N°** et les informations de la
   ligne pour identifier la bonne commande.
5. Si plusieurs commandes correspondent, parcourez les pages du tableau.
   Si vous étiez sur une page avancée avant de rechercher, revenez à la première
   page des résultats.
6. Pour retirer la recherche, effacez entièrement le contenu du champ
   **Rechercher**. La liste des commandes chargées est de nouveau affichée.

## Lire le résultat

- **N°** : numéro commercial de la commande.
- **Offert par** : mention renseignée pour la commande ; elle ne désigne pas
  nécessairement le nom de la fiche client.
- **Occasion** : occasion renseignée sur la commande.
- **Qté** : quantité de bons de la commande.
- **Payé** : montant déjà payé.
- **Facturé** : montant total de la commande affiché dans cette liste.
- **Création** et **Expiration** : dates de création et de fin de validité.

Les montants **Payé** et **Facturé** sont verts lorsque le montant payé est égal
au total de la commande ; sinon, ils sont rouges. La seule présence d'un montant
dans **Facturé** ne prouve pas qu'un document de facture a été généré.

## Règles et limites

- La recherche accepte une partie du texte et ne distingue pas les majuscules
  des minuscules. Si nécessaire, reprenez les accents du libellé recherché.
- Les champs recherchés sont le numéro de commande, **Offert par** et
  **Occasion**. La recherche de cette liste ne porte pas directement sur le nom
  de la fiche client.
- Cet écran ne propose pas de filtre de recherche par date ou par état payé/non
  payé. Ne cherchez pas un filtre qui n'y est pas affiché.
- Le tableau affiche initialement 50 lignes par page.
- La recherche porte sur les commandes chargées dans la liste. Une absence de
  résultat ne suffit pas à établir qu'une commande n'existe pas dans l'ensemble
  de l'historique du réseau.
- Rechercher et lire une ligne ne crée, ne modifie et ne supprime aucune commande.

## Si la commande n'apparaît pas

1. Vérifiez le numéro commercial et essayez une partie de celui-ci.
2. Effacez le champ pour vérifier que la liste affiche bien des commandes, puis
   refaites la recherche depuis la première page du tableau.
3. Si vous recherchez avec un nom de client, utilisez plutôt le numéro de la
   commande ou une mention effectivement présente dans **Offert par**.
4. Si une commande connue reste absente, rechargez la page et refaites la
   recherche. Un résultat vide peut aussi correspondre à un problème de
   chargement ; cette vue ne fournit pas de message de recherche détaillé.
5. Si le problème persiste, signalez-le à votre interlocuteur Tribuneo avec
   le numéro commercial concerné, sans communiquer de mot de passe ni de jeton.

## Écran concerné

Menu **Commandes**, écran **Liste des commandes**.

## Avec Néo

Pour obtenir cette procédure, demandez : « Comment rechercher une commande dans
le back-office Tribuneo ? »

Pour demander à Néo de consulter les données directement dans le chat, formulez
plutôt une recherche précise : « Retrouve la commande portant le numéro
commercial [numéro] ». Cette consultation est distincte de la recherche dans
l'interface décrite ci-dessus. Une recherche par nom de client dans le chat
utilise un outil métier différent du champ **Rechercher** de cet écran.
