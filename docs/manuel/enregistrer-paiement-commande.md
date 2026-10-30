# Enregistrer un paiement sur une commande

## Objectif

Renseigner dans le back-office un règlement associé à une commande existante,
puis vérifier son apparition dans le tableau des paiements.

## Étapes

1. Ouvrez **Commandes**, retrouvez la commande concernée, puis choisissez
   **Gestion → Paiements** sur sa ligne.
2. Attendez le chargement et contrôlez les paiements déjà affichés ainsi que
   **Montant payé:**, qui présente le cumul et le total de la commande. Si les
   données paraissent incomplètes ou incohérentes, vérifiez-les avant de saisir
   un nouveau règlement.
3. Dans la zone d'ajout, vérifiez la date affichée, initialement celle du jour.
   Pour la changer, cliquez sur le bouton portant cette date et choisissez la
   date du règlement dans le calendrier ou sa saisie **Jour/Mois/Année**.
4. Sélectionnez la **Méthode** : **Espèces**, **Chèque**, **Virement**,
   **Paiement en ligne**, **Carte bancaire** ou **Mandat administratif**.
5. Si le sélecteur **Compte encaisseur** est présent, vérifiez le compte
   présélectionné ou choisissez celui sur lequel le règlement a été encaissé.
6. Dans le champ **Ajouter un paiement**, saisissez le montant du règlement,
   strictement positif, sans dépasser le reste à payer. Utilisez un montant
   numérique avec un point pour les centimes, sans symbole monétaire.
7. Cliquez sur **Valider**. La fenêtre **Confirmation** récapitule le montant,
   la date et, lorsque le choix est proposé, le compte encaisseur. Relisez ces
   informations, puis cliquez sur **Valider** dans cette confirmation pour
   enregistrer. **Annuler** permet de revenir sans envoyer cet enregistrement.
8. Attendez la mise à jour du tableau, puis contrôlez la nouvelle ligne et
   **Montant payé:**. Cliquez sur **Fermer** pour revenir aux commandes.

## Compte encaisseur et commande soldée

- Le sélecteur de compte apparaît lorsque plusieurs comptes sont chargés et
  que le réseau autorise ce choix. Le compte par défaut peut être présélectionné.
- Quand un seul compte est disponible ou que le réseau impose son compte, ce
  sélecteur n'apparaît pas ; le compte est déterminé par la configuration.
- Un échec de chargement des comptes peut également masquer le sélecteur. Son
  absence ne permet donc pas, à elle seule, de conclure à un compte unique ou
  imposé. Si le message indique une erreur de chargement, contrôlez la situation
  avant d'enregistrer.
- La zone d'ajout est masquée lorsque le cumul affiché atteint ou dépasse le
  total de la commande. Un tableau vide ne prouve pas une absence de paiements :
  une erreur de lecture peut aussi donner ce résultat.

## Messages et difficultés

| Message ou situation | Action |
|---|---|
| « Le montant saisi dépasse le montant total de la commande. » | Vérifiez le montant restant et la Méthode : dans cette interface, l'absence de méthode sélectionnée peut aussi provoquer ce message. |
| « La date de paiement ne peut pas être antérieure à la date du dernier paiement. » | Vérifiez la date du règlement et les paiements affichés ; le sélecteur a refusé la date choisie. |
| « Choisissez le compte sur lequel le paiement a été encaissé. » | Sélectionnez le Compte encaisseur demandé. |
| « Le compte bancaire choisi n'existe plus. » | La liste est rechargée : vérifiez le nouveau choix avant toute nouvelle validation. |
| « Impossible de charger les comptes bancaires du réseau. » | Fermez puis rouvrez Paiements ; si l'erreur persiste, signalez-la à votre interlocuteur Tribuneo. |
| « Aucun compte bancaire n'est configuré pour ce réseau. Contactez Neofid. » | Faites vérifier la configuration du réseau. |
| « L'enregistrement précédent est encore en cours. Patientez quelques secondes. » | Attendez la relecture du tableau et vérifiez les lignes avant de recommencer. |
| « Erreur lors de l'enregistrement du paiement. » ou réponse incertaine | Vérifiez d'abord si le paiement apparaît déjà avant toute nouvelle tentative. |

Un indicateur d'attente remplace le bouton pendant le chargement des comptes ou
l'envoi. Le champ de montant peut rester rempli après un succès : ne revalidez
pas simplement parce qu'il contient encore le montant. Une nouvelle validation
après succès peut enregistrer un autre paiement si le reste à payer le permet.

La fermeture de la confirmation ou un tableau momentanément vide ne prouve pas
le résultat de l'enregistrement. En cas de doute, contrôlez les lignes dans la
fenêtre **Paiements**, en la rouvrant si nécessaire, avant de recommencer.

## Avec Néo

Demandez : « Comment enregistrer un paiement sur une commande dans le
back-office ? » Néo explique la saisie et la confirmation ; l'utilisateur
effectue l'enregistrement dans l'interface. Néo n'ajoute aucun paiement et ne
réalise aucune opération bancaire.

Pour lire les paiements réels d'une commande dans le chat, identifiez la commande
et demandez leur consultation. La suppression d'un paiement et la facturation
sont des procédures distinctes, non décrites dans cette fiche.
