# Supprimer un secteur d'activité

## Objectif et prérequis

Retirer un secteur inutilisé du catalogue commun, avec un compte administrateur.
Le catalogue et les rattachements aux entités ne sont pas séparés par réseau
dans les sources vérifiées. Un secteur utilisé par une entité, y compris hors
du réseau affiché, bloque la suppression côté API.

## Étapes

1. Ouvrez **Secteurs**, écran **Secteurs d'activité**, et identifiez précisément
   le secteur dans la liste **Secteurs** (ordre alphabétique, deux colonnes).
2. À droite de son nom, cliquez sur l'icône de corbeille rouge dont
   l'infobulle est **Supprimer** suivi du nom du secteur.
3. Lisez la confirmation, titrée **Supprimer « … » ?** avec le nom du secteur :
   **Attention, il est possible que ce secteur d'activité soit associé à des
   partenaires. Voulez-vous vraiment le supprimer ?**
4. Cliquez sur **Annuler** pour abandonner. Cliquez sur le bouton rouge
   **Supprimer** (anciennement **Confirmer**) uniquement si vous souhaitez
   réellement supprimer ce secteur.
5. Après **Le secteur d’activité a été supprimé avec succès**, contrôlez sa
   disparition de la liste.

## Effets réels et erreurs

La confirmation n'autorise pas le détachement automatique des partenaires.
L'API recherche les liens du secteur vers les entités et refuse la suppression
si elle en trouve. Elle ne supprime pas les partenaires et ne leur retire pas
automatiquement leurs secteurs. Le contrôle des liens ne se limite pas aux
partenaires visibles ou actifs du réseau courant.

En cas de **Erreur lors de la suppression du secteur d’activité**, un lien
existant peut expliquer le refus, mais le message BO est générique et ne le
prouve pas. Vérifiez la liste avant de recommencer. Si la suppression réussit
mais que le rechargement de la liste échoue, le message de réussite s'affiche
et la liste indique **Impossible de charger les secteurs d'activité.** :
cliquez sur **Réessayer** pour contrôler. Une liste vide ou ancienne ne
constitue pas à elle seule une preuve de suppression.
Le rechargement peut notamment échouer après la suppression du dernier secteur.

Si le secteur est encore utilisé, faites examiner son usage avant de décider
d'un retrait. Pour changer les secteurs d'un partenaire identifié, voir
[Attribuer des secteurs d'activité à un partenaire](attribuer-secteurs-partenaire.md).
Cette fiche ne décrit pas de retrait collectif et ne garantit pas de détecter
tous les usages depuis le seul BO du réseau.

Aucune restauration ni annulation après confirmation n'est proposée dans cet
écran. Un message de succès ne remplace pas la vérification de la liste.

## Portée de l'aide Néo

Néo explique la confirmation et les limites. Il ne supprime aucun secteur,
ne détache aucune entité et ne modifie aucun partenaire.

Vérification au 30 octobre 2026 : vue, repository, action API, recherche des
liens et suppression en base lus. Aucune confirmation ni suppression exécutée.
