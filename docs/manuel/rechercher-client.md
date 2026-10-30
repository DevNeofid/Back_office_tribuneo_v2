# Rechercher et filtrer un client

## Objectif

Retrouver une fiche dans **Clients**, écran **Liste des clients**, puis consulter
ses informations. Ce parcours porte sur les clients du réseau courant.

## Étapes

1. Ouvrez **Clients** dans le menu latéral et attendez la fin du chargement.
2. Saisissez tout ou partie du nom dans **Rechercher...**. La liste se met à
   jour après une courte pause de saisie, d'environ une demi-seconde.
3. Repérez le nom dans l'en-tête de la fiche et vérifiez les informations
   affichées pour distinguer les homonymes.
4. Pour parcourir la liste par initiale, cliquez sur l'une des lettres ou
   l'un des chiffres proposés au-dessus des fiches. Ce clic efface la recherche
   et affiche le groupe choisi. Seuls les groupes reçus non vides sont proposés.
5. Sur une fiche, consultez **Informations générales**, **Adresse** ou
   **Informations bancaires**.

## Fonctionnement des filtres et du tri

- La recherche porte uniquement sur le nom, par présence du texte saisi, sans
  distinction entre majuscules et minuscules. Elle parcourt tous les clients
  chargés, au-delà de l'initiale sélectionnée. Une recherche par e-mail,
  téléphone, code ou SIRET n'est pas proposée par ce champ.
- Effacer le texte ramène au dernier groupe d'initiale sélectionné.
- La liste est regroupée par initiale du nom et triée par nom à l'intérieur
  des groupes par l'API. Aucun bouton de tri ascendant ou descendant n'est
  établi dans cet écran ; le classement des accents n'est pas garanti comme
  un tri linguistique français.
- Sous **Filtres :**, les trois icônes personnes, cible et argent choisissent
  respectivement l'onglet **Informations générales**, **Adresse** ou
  **Informations bancaires** à afficher sur les fiches. Elles ne filtrent pas
  les clients selon la présence d'une adresse, d'un compte ou leur statut.
- **Aucune adresse enregistrée pour le moment** et
  **Aucune information bancaire enregistrée pour le moment** décrivent les
  informations reçues pour la fiche, sans établir l'absence dans toute la base.

Si vous ne trouvez pas le client, vérifiez le nom saisi et l'initiale affichée.
Une liste vide, un problème de chargement ou une lecture en erreur ne prouvent
pas l'absence du client : n'en créez pas un nouveau sur ce seul constat.

Depuis la fiche trouvée, la première icône de l'en-tête, en forme de liste,
ouvre **Ajouter une commande** pour ce client : voir
[Créer une commande depuis la fiche d'un client](creer-commande-depuis-client.md).

## Portée de l'aide Néo

Néo peut aider à rechercher ou expliquer l'écran avec ses outils de lecture
disponibles. Il ne modifie pas la fiche. Ce guide de navigation ne prouve pas
qu'une recherche effective a été exécutée ni qu'un client est absent.

Vérification au 30 octobre 2026 : code de l'interface et API lus. Rendu visuel,
recherche avec données et comportement des accents non testés en session.
