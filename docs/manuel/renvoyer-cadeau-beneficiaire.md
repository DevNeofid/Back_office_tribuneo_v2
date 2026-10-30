# Renvoyer l'e-mail cadeau à un bénéficiaire

## Objectif et prérequis

Renvoyer l'e-mail cadeau d'un bon existant à son adresse enregistrée, avec les
droits d'administration du réseau. Le bon doit être non annulé, non attribué
à un compte consommateur et comporter une adresse e-mail. Le renvoi reste
possible après facturation. Il ne crée pas un nouveau bon.

## Parcours depuis les bénéficiaires importés

1. Dans **Commandes**, retrouvez la commande, puis ouvrez
   **Gestion → Bénéficiaires (commande importée)** : voir
   [Consulter les bénéficiaires](consulter-beneficiaires-commande-importee.md).
2. Repérez la ligne du bon avec le nom, **E-mail**, **Montant** et **Statut**.
   Pour un bon **En attente** ayant un e-mail enregistré, la colonne **Actions**
   peut proposer une icône d'envoi avec l'infobulle **Renvoyer l'e-mail**.
3. Vérifiez l'adresse enregistrée. Si vous avez modifié un champ sans
   enregistrer, l'infobulle devient **Renvoyer l'e-mail (à l'adresse enregistrée)** :
   le renvoi utilise l'ancienne adresse en base, pas la saisie en cours.
   Pour un simple renvoi, partez d'une liste rechargée sans modification.
4. Cliquez une seule fois sur **Renvoyer l'e-mail** pour effectuer l'envoi.
   **Aucune confirmation n'est demandée.** Un indicateur d'attente remplace
   l'icône pendant la requête.
5. Le message **E-mail renvoyé à …** confirme le succès annoncé par le service
   d'envoi à cette adresse. Il ne garantit pas la réception dans la boîte du
   destinataire. Fermez la fenêtre avec **Fermer**.

## Autre entrée et disponibilité

**Gestion → Gestion des bons** comporte aussi une icône **Renvoyer l'e-mail**.
Elle est proposée pour un bon non désactivé, hors donation, lorsque l'e-mail
affiché est non vide. Cette fenêtre affiche les contacts du compte consommateur
associé ; elle peut donc proposer le bouton pour un bon déjà attribué, que
le serveur refusera. Pour les contacts d'import et un bon en attente, privilégiez
la fenêtre **Bénéficiaires (commande importée)**.

Une infobulle **Aucune adresse e-mail pour ce bon** dans **Gestion des bons**
ne prouve pas l'absence d'e-mail d'import : elle sert aussi lorsque le bon est
désactivé ou une donation. Vérifiez les bénéficiaires de la commande importée.

## Messages et difficultés

| Message | Suite utile |
|---|---|
| **E-mail renvoyé à …** | Succès déclaré par le service ; évitez les renvois répétés pour une simple absence dans la boîte de réception. |
| **Ces bons sont déjà attribués à des consommateurs : ils ne peuvent plus être modifiés ni retirés.** | Message générique utilisé aussi pour ce refus de renvoi : le bon est déjà attribué. |
| **Ce bénéficiaire n'a pas d'adresse e-mail.** | Aucun renvoi par e-mail n'est possible avec les données enregistrées. Un mobile seul ne suffit pas. |
| **Ce bon a été annulé.** | Le bon est désactivé ; rechargez la liste. |
| **Introuvable. Rechargez la page.** | Retrouvez la commande et le bon après rechargement. |
| **L'e-mail n'a pas pu être envoyé. Réessayez plus tard.** | Échec annoncé par le service ; vérifiez la situation avant de retenter plus tard. |
| **Erreur lors de l'envoi de l'e-mail.** | L'effet peut être incertain : faites vérifier l'envoi avant de recommencer pour éviter un doublon. |
| **Vous n'avez pas accès à cette ressource.** | Faites vérifier vos droits. |

## Avec Néo

Demandez : « Comment renvoyer l'e-mail cadeau à un bénéficiaire de commande
importée ? ». Néo explique l'action humaine et les refus ; il n'envoie aucun
e-mail ou cadeau, ne crée aucun bon et ne confirme pas une réception.
