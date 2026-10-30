# Modifier une commande

## Objectif

Changer les lignes, l'occasion ou la date de validité d'une commande existante,
dans les limites fixées par la facturation, l'origine de la commande et les bons
déjà attribués.

## Ce qui peut être modifié

| Situation de la commande | Ce que permet le formulaire **Modifier** |
|---|---|
| Saisie à la main, non facturée | Lignes, **Pour l'occasion de** et date de validité. |
| Importée par fichier, non facturée | Occasion et date ; les lignes passent par l'écran **Bénéficiaires**, non décrit dans cette fiche. |
| Issue de la boutique en ligne, non facturée | Occasion et date ; les lignes ne sont pas modifiables. |
| Facturée | Lecture seule ; seule la date de validité peut être changée, via **Changer la date de validité**. |

Dans tous les cas, le champ **Offert par** est en lecture seule : le client et
le texte « Offert par » ne se modifient pas ici. Un bon attribué à un
consommateur, par exemple scanné ou utilisé, n'est jamais retiré.

## Étapes

1. Ouvrez **Commandes** et retrouvez la commande : voir
   [Rechercher une commande](rechercher-commande.md).
2. Dans la colonne **Edition**, ouvrez le menu de sa ligne et choisissez
   **Modifier**. Le message **Chargement de la commande...** s'affiche pendant
   la lecture de son état.
3. La fenêtre **Modifier la commande** suivie du numéro commercial s'ouvre.
   Lisez l'éventuel bandeau orange en haut du formulaire (voir plus bas).
4. Pour changer la date de validité, cliquez sur **Choisir une date** ou sur le
   champ **Date d'expiration**, puis choisissez la date dans le calendrier. La
   date la plus proche possible est celle de demain. Les règles de date sont
   détaillées dans [Changer la date de validité d'une commande](changer-validite-commande.md).
5. Si les lignes sont modifiables, ajustez **Montant par chèque**, **Nombre de
   chèque** et **Message personnalisé**. Le montant doit être strictement
   positif, avec un point et au plus deux décimales ; la quantité est un entier
   d'au moins un. Cochez **Différents fonds ?** pour gérer plusieurs lignes,
   puis utilisez **+** pour ajouter une ligne et **−** pour retirer la dernière.
6. Si nécessaire, changez **Pour l'occasion de**.
7. Cliquez sur **Enregistrer**. Si la modification retire des chèques d'un
   montant, la fenêtre **Retrait de bons** s'affiche : « Les bons retirés
   seront les derniers créés parmi ceux qui ne sont pas encore attribués. Si
   leurs QR ont déjà été imprimés et distribués, ils ne seront plus valables.
   Continuer ? ». **Annuler** revient au formulaire sans enregistrer ;
   **Continuer** envoie la modification.
8. En cas de succès, le formulaire se ferme et le message **Commande modifiée :**
   indique le nombre de bons créés et retirés. La liste se recharge : contrôlez
   **Qté**, **Facturé**, **Occasion** et **Expiration**.

Pour quitter sans enregistrer, cliquez sur **Fermer** : les changements non
enregistrés sont perdus.

## Effets d'une modification

- **Quantité augmentée** : de nouveaux bons du montant concerné sont créés.
- **Quantité diminuée** : les derniers bons créés de ce montant qui n'ont jamais
  été attribués sont retirés. S'il n'y en a pas assez, la modification est
  refusée en entier.
- **Montant d'une ligne changé** : la modification est traitée montant par
  montant. Passer une ligne d'un montant à un autre retire les bons de l'ancien
  montant et crée ceux du nouveau ; la fenêtre **Retrait de bons** s'affiche
  donc aussi dans ce cas.
- **Total** : il est recalculé à partir des lignes. Les paiements déjà
  enregistrés ne sont pas contrôlés par la modification : après un changement
  de total, vérifiez le solde avec
  [Vérifier le solde d'une commande](verifier-solde-commande.md).
- **Date de validité** : la nouvelle date s'applique à la commande et à tous
  ses bons non annulés, y compris ceux dont la date avait été changée bon par bon.
- **Message personnalisé** vide : le nom de l'occasion est utilisé.

## Bandeaux du formulaire

| Bandeau | Signification |
|---|---|
| « Cette commande est facturée : seule la date de validité peut encore être modifiée (et, pour une commande importée, le contact des bénéficiaires non attribués). » | Le formulaire est en lecture seule, sans **Enregistrer**. Le bouton **Changer la date de validité** ouvre le changement de date pour toute la commande. |
| « Commande importée par fichier : les montants et les quantités se modifient depuis l'écran Bénéficiaires. » | Les lignes sont en lecture seule. Le bouton **Bénéficiaires** ouvre un autre écran, non décrit dans cette fiche. |
| « Commande de la boutique en ligne : les lignes ne sont pas modifiables. » | Les lignes sont en lecture seule. |

Si l'état de la commande n'a pas pu être lu, le formulaire s'ouvre sans bandeau
et reste modifiable ; un éventuel refus est alors signalé à l'enregistrement et
le formulaire s'aligne sur ce refus.

## Messages et refus

| Message | Cause et action |
|---|---|
| « Le montant des fonds non valide » / « Le nombre de fond non valide » | Corrigez le montant ou la quantité de la ligne signalée. |
| « La date doit être au plus tôt demain. » | Choisissez une date à partir de demain. |
| « Ce bon est déjà attribué : sa date peut seulement être prolongée. » | Au moins un bon attribué serait avancé. Choisissez une date égale ou postérieure à la date actuelle de ces bons. |
| « Impossible de retirer autant de bons de … € : seuls … ne sont pas encore attribués. » | Trop de bons de ce montant sont déjà attribués. Réduisez moins la quantité. |
| « Cette commande est facturée : … » | Une facture existe : seule la date peut changer, via **Changer la date de validité**. |
| « Commande importée : modifiez les bénéficiaires depuis l'écran Bénéficiaires. » | Les lignes d'une commande importée ne se modifient pas ici. |
| « Commande de la boutique en ligne : les lignes ne sont pas modifiables. » | Laissez les lignes inchangées. |
| « Introuvable. Rechargez la page. » | La commande n'existe plus ou a été supprimée : rechargez la page. |
| « Vous n'avez pas accès à cette ressource. » | Votre compte n'a pas accès à cette opération ; adressez-vous à votre interlocuteur Tribuneo. |
| « Erreur lors de la modification de la commande. » | Résultat incertain : rechargez la page et contrôlez la commande avant toute nouvelle tentative. |

Après un refus, le formulaire reste ouvert avec les valeurs saisies. Aucune
modification n'est appliquée lorsqu'un refus métier est affiché.

## Avec Néo

Demandez : « Comment modifier une commande dans le back-office ? » ou
« Pourquoi je ne peux pas modifier les lignes de cette commande ? ». Néo
explique la procédure et les refus ; la modification est effectuée par
l'utilisateur dans l'interface. Néo ne modifie aucune commande. Il peut relire
en lecture seule les lignes, le total et le montant payé d'une commande avant ou
après la modification.
