# Se déconnecter du back-office

## Objectif

Quitter votre session de gestion lorsque vous avez terminé votre travail.

## Étapes

1. En bas du menu latéral bleu marine, repérez la carte du réseau : un rond
   orange avec les deux premières lettres du réseau, son nom et une icône de
   sortie. Sur un écran étroit, ouvrez d'abord le menu avec le bouton
   ☰ **Menu** en haut à gauche.
2. Cliquez sur cette carte ; son infobulle indique **Se déconnecter**.
   L'action est immédiate, sans fenêtre de confirmation.
3. Vérifiez le retour à l'écran de connexion **BACKOFFICE**, avec les champs
   **Nom d'utilisateur**, **Mot de passe** et le bouton **Se connecter**.

Cette carte remplace l'ancien menu **Déconnexion** du haut de page et l'ancienne
tuile de l'accueil. Un clic n'importe où sur la carte déconnecte : ne cliquez
pas dessus pour seulement vérifier le nom du réseau.

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

Néo peut indiquer où se trouve la carte **Se déconnecter** ; il ne ferme pas
votre session à votre place.

Vérification au 30 octobre 2026 : en-tête actif, raccourci, repository et action
API lus. Aucune déconnexion réelle effectuée.

Libellés relus le 2 novembre 2026 : tranche 1 M15, sans changement de logique.
Recette visuelle et opérations en session non exécutées pour cette mise à jour.
