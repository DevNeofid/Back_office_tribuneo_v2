# Consulter les bénéficiaires d'une commande importée

## Objectif et prérequis

Retrouver les contacts enregistrés sur les bons d'une commande importée par
fichier, leur montant restant et leur attribution à un compte consommateur.
La commande existe déjà et vous disposez des droits d'administration du réseau.
La création par import relève d'une
[procédure distincte](creer-commande-import-fichier.md).

## Étapes de consultation

1. Dans **Commandes**, écran **Liste des commandes**, retrouvez la commande.
2. Sur sa ligne, ouvrez l'icône de la colonne **Gestion**, puis
   **Bénéficiaires (commande importée)**.
3. Vérifiez le numéro dans **Bénéficiaires - Commande …** et attendez le
   chargement de la liste.
4. Consultez **Prénom**, **Nom**, **E-mail**, **Mobile**, **Montant**, **Reste**,
   **Statut** et **Actions**. Faites défiler le tableau horizontalement si
   nécessaire. Une ligne correspond à un bon : le même bénéficiaire peut
   apparaître sur plusieurs lignes.
5. **En attente** signifie que le bon n'est pas attribué à un compte consommateur.
   **Attribué à …** indique son attribution ; ce statut ne confirme ni la
   réception de l'e-mail ni la consommation totale du bon.
6. Utilisez **Recharger** pour relire la liste, sans modification en cours,
   puis **Fermer** pour quitter.

## Lire la bonne liste

- Les coordonnées viennent du bon, notamment de l'import ; elles peuvent
  différer de celles du compte associé affichées dans **Gestion des bons**.
- Les donations et les bons annulés sont exclus de cette liste. Pour les dates
  d'expiration et de suppression, ouvrez
  [Gestion des bons](consulter-bons-commande.md) : la fenêtre des bénéficiaires
  ne présente pas de colonne d'expiration.
- **Reste** affiche le montant restant enregistré ; ce n'est pas une preuve
  que le bon est encore valide.
- L'entrée du menu est proposée aussi pour une commande non importée. Dans ce
  cas, **Cette commande n'a pas été importée par fichier.** s'affiche et la
  modification des lignes est indisponible. Vérifiez la commande choisie.

## Précautions de consultation

Des champs peuvent être éditables. Pour consulter seulement, ne changez pas
les valeurs et ne choisissez pas **Ajouter un bénéficiaire**, **Retirer** ou
**Enregistrer**. L'enregistrement peut envoyer des e-mails aux nouveaux
bénéficiaires et à ceux dont l'adresse change ; cette fiche n'en décrit pas
la procédure.

Une ligne attribuée est en lecture seule. Pour une commande facturée, le
bandeau précise que seuls le nom, l'e-mail et le mobile des bénéficiaires
non attribués restent modifiables. Le renvoi volontaire d'un e-mail est décrit
dans [Renvoyer un cadeau à un bénéficiaire](renvoyer-cadeau-beneficiaire.md).

Si vous avez saisi quelque chose par inadvertance, **Fermer** peut afficher
**Modifications non enregistrées**, puis **Fermer sans enregistrer ? Les
modifications seront perdues.** Choisissez **Fermer sans enregistrer** pour
abandonner ces saisies. **Recharger** relit les valeurs enregistrées et peut
aussi perdre les saisies en cours, sans cette confirmation.

## Messages et aide Néo

**Aucun bénéficiaire pour cette commande.** décrit la liste chargée après les
exclusions ci-dessus. **Impossible de charger les bénéficiaires.** est une
erreur de lecture, pas une liste vide : utilisez **Recharger** et signalez le
problème s'il persiste. Un refus d'accès nécessite de faire vérifier vos droits.

Demandez à Néo : « Où voir les bénéficiaires d'une commande importée ? ».
Néo explique cette fenêtre ; ses outils actuels ne lisent pas cette liste et
ne modifient ni les contacts ni les bénéficiaires.
