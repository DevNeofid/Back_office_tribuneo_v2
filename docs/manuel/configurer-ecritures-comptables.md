# Faire configurer les écritures comptables

## Objectif et prérequis

Faire vérifier par Neofid les paramètres nécessaires à la génération des
écritures de votre réseau. Cette fiche décrit les contrôles du logiciel ; elle
ne recommande aucun journal, numéro de compte ou traitement comptable.

Le paramétrage est géré par Neofid. Aucun formulaire actif de modification du
journal ou du compte 512 du réseau n'est identifié dans le back-office lu.
Les informations bancaires d'un client ou partenaire ne remplacent pas ce
paramétrage du réseau.

## Démarche

1. Faites vérifier par Neofid que les écritures comptables sont activées pour
   votre réseau et que son compte bancaire par défaut est défini.
2. Faites vérifier le **journal** et le **compte 512** de chaque compte bancaire
   effectivement utilisé sur la période, ainsi que les paramètres de journaux
   et de comptes du réseau détaillés ci-dessous. Le choix de leurs valeurs
   appartient à votre interlocuteur compétent.
3. Si la fenêtre **Aucune écriture comptable générée** s'est déjà affichée,
   relevez la liste des manques et cliquez sur **Fermer**. Transmettez cette
   liste à Neofid sans communiquer de secret de connexion.
4. Après confirmation du paramétrage, suivez la fiche
   [Générer les écritures comptables](generer-ecritures-comptables.md).
   Aucun déclenchement de diagnostic n'est nécessaire pour suivre cette fiche.

## Champs réellement utilisés

Les noms techniques suivants permettent à Neofid d'identifier les réglages ;
ce ne sont pas des champs à saisir dans un écran de configuration du BO.

| Paramètre | Utilisation et contrôle lus |
|---|---|
| `accounting-entries` | Activation des écritures ; désactivé par défaut. Sans activation, génération, historique et retéléchargement sont refusés par l'API. |
| `bank-account.<code>.journal` et `bank-account.<code>.accounting-number` | Journal banque et compte dit « 512 » de chaque compte utilisé pour les paiements ou factures de frais de la période. Le contrôle exige une valeur non vide ; il ne vérifie pas que le numéro commence par 512, ni sa validité comptable. |
| `bank-account-default` | Compte par défaut obligatoire pour la génération, y compris pour les paiements anciens sans code de compte. Un code absent ou inconnu provoque un refus. |
| `bank-account-refund` | Compte de remboursement. À défaut de compte de remboursement résolu, le service se replie sur le compte par défaut. Utilisé pour une facture de frais sans compte de virement associé. |
| `code-refund` | Journal utilisé dans les écritures de factures clients et de frais ; valeur non vide obligatoire. |
| `accounting-number-incl-vat`, `accounting-number-vat`, `accounting-number-excl-vat` | Comptes réseau lus par la génération ; les trois valeurs sont exigées même si aucune ligne de TVA n'est produite. |
| `code-purchase` | Journal d'achat facultatif. S'il est renseigné, des lignes supplémentaires sont produites et un numéro comptable partenaire est exigé pour les factures de frais concernées. |
| `accounting-file-encoding` | Facultatif : `UTF-8` par défaut ; seules les valeurs `UTF-8` et `Windows-1252` sont acceptées. |

Le libellé du compte bancaire sert aux noms des fichiers lorsque plusieurs
comptes existent. Les coordonnées du donneur d'ordre nécessaires au SEPA ne
font pas partie du contrôle journal/512. Les verrous de choix de compte sur
les paiements et virements ne sont pas modifiés par la génération comptable.
La gestion générale des comptes réseau dépasse cette fiche.

Pour les factures clients et paiements sélectionnés, le code recherche aussi
le numéro comptable de l'entité. En présence d'un journal d'achat, il le
recherche également pour les partenaires concernés. Une jointure peut écarter
un paiement sans facture ou sans ligne d'informations comptables : l'absence
de message ne garantit donc pas l'exhaustivité des données à exporter.

## Messages et limites

La fenêtre **Aucune écriture comptable générée** demande de contacter Neofid
pour compléter les comptes utilisés sur la période. Sa liste vient de l'API,
par exemple `Bank account "<code>" is missing accounting-number, journal`.
Cette fenêtre peut aussi recevoir d'autres erreurs détaillées, telles qu'un
compte inconnu ou un numéro comptable d'entité manquant : son texte général ne
suffit pas à identifier la cause ; lisez chaque ligne.

Les refus API pour activation absente, paramètres réseau manquants ou encodage
non accepté ne sont pas tous traduits en messages précis par le BO. Le message
**Erreur lors de la génération des écritures comptables.** peut les recouvrir.
Ne déduisez pas de ce seul message quel champ est incorrect.

Un refus explicite de validation avant création n'enregistre pas de nouveau
lot et n'avance pas le seuil de suppression des paiements. Une erreur de
téléchargement après génération peut, elle, survenir après enregistrement :
vérifiez l'historique avant tout nouveau déclenchement.

## Écran concerné et aide Néo

Le menu **Écritures** ouvre **Écritures comptables**. La fenêtre de configuration
apparaît uniquement après certains refus du déclenchement ; ce n'est pas un
formulaire de modification et elle ne comporte qu'un bouton **Fermer**.

Néo explique ces prérequis et les messages documentés. Il ne modifie ni les
paramètres ni les comptes et ne choisit aucune valeur comptable pour vous.
