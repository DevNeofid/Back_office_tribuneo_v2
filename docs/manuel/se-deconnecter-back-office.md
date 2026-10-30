# Se déconnecter du back-office

## Objectif

Quitter votre session de gestion lorsque vous avez terminé votre travail.

## Étapes

1. En haut de page, cliquez sur le nom du réseau accompagné de l'icône de
   personne.
2. Dans le menu qui s'ouvre, cliquez sur **Déconnexion**. L'action est immédiate,
   sans fenêtre de confirmation.
3. Vérifiez le retour à l'écran **Backoffice**, avec les champs
   **Nom d'utilisateur**, **Mot de passe** et le bouton **Connexion**.

Depuis **Accueil**, la tuile **Deconnexion** mène à la même action. Ce libellé
est sans accent dans le tableau de bord, contrairement à celui du menu supérieur.

## Effets et limites

La déconnexion demande au serveur de révoquer la session, puis efface les
informations locales d'accès et le dernier menu mémorisé. La page de gestion
et la conversation Néo qui lui est attachée sont quittées. Les préférences
locales d'affichage de l'assistant peuvent être conservées.

Si la demande au serveur échoue, le code efface tout de même les informations
locales et revient à l'écran de connexion, sans message d'erreur spécifique.
Ce retour ne suffit donc pas à prouver que la révocation côté serveur a réussi.
Fermer simplement un onglet n'est pas la procédure de déconnexion décrite ici.

## Portée de l'aide Néo

Néo peut indiquer où se trouve **Déconnexion** ; il ne ferme pas votre session
à votre place.

Vérification au 30 octobre 2026 : en-tête actif, raccourci, repository et action
API lus. Aucune déconnexion réelle effectuée.
