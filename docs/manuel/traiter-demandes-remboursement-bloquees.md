# Traiter les demandes de remboursement écartées

## Objectif

Comprendre pourquoi une demande de remboursement figure dans la section
**Écartées** du menu **Prochain virement**, et la rendre payable quand c'est
possible depuis le back-office.

Une demande écartée ne bloque pas les autres : le virement paie les demandes
**À payer** et laisse les écartées de côté. Elles sont reprises
automatiquement au virement suivant dès que leur motif a disparu. Plusieurs
virements le même jour sont possibles.

## Motifs et actions

| Motif affiché | Cause | Action possible dans le BO |
| --- | --- | --- |
| **Adresse du commerçant incomplète** | Rue, code postal ou ville vide | **Compléter la fiche** |
| **IBAN ou BIC du commerçant manquant** | IBAN ou BIC vide | **Compléter la fiche** |
| **Mise en attente** | Suspendue par un administrateur, motif éventuel en italique | **Libérer** |
| **Montant net nul après frais de gestion** | Frais égaux ou supérieurs au montant | Aucune ; contactez le support |
| **Commerçant introuvable, contactez le support** | Commerçant de la demande non retrouvé | Aucune |

Une demande peut cumuler plusieurs motifs ; tous doivent disparaître. Un code
inconnu du back-office est affiché tel quel.

## Compléter la fiche du commerçant

1. Dans **Écartées**, sur la ligne de la demande, cliquez sur
   **Compléter la fiche**.
2. Le BO affiche **Chargement de la fiche du commerçant...**, puis ouvre
   directement le formulaire manquant : adresse, coordonnées bancaires, ou
   les deux l'un après l'autre.
3. Renseignez le formulaire comme décrit dans
   [Renseigner l'adresse d'un partenaire](renseigner-adresse-partenaire.md)
   ou [Renseigner les coordonnées bancaires d'un partenaire](renseigner-coordonnees-bancaires-partenaire.md),
   puis **Enregistrer**.
4. L'aperçu est rechargé si un formulaire a été enregistré. Vérifiez que la
   demande est passée dans **À payer**.

Si la fiche n'est pas retrouvée, le message est
**Fiche du commerçant introuvable. Complétez-la depuis le menu Partenaires.**
Passez alors par **Partenaires**.

L'adresse et les coordonnées bancaires sont rattachées à l'entité du
commerçant : la correction vaut aussi pour ses autres rôles et réseaux. Seul
un IBAN français peut être saisi par ce parcours.

## Lever une mise en attente

Cliquez sur **Libérer**, puis confirmez. Voir
[Mettre en attente ou libérer une demande de remboursement](mettre-en-attente-liberer-demande-remboursement.md).

## Écartée au moment de la génération

Le serveur refait la sélection quand vous générez l'ordre de virement. Si une
fiche est devenue incomplète entre l'aperçu et la génération, la demande est
écartée à ce moment-là. Le ZIP de l'ordre contient alors
`REMBOURSEMENTS_ECARTES.csv`, avec le numéro, la date, le code et le nom du
commerçant, le montant, les motifs et le motif de mise en attente.

## Ce qui n'est pas une demande écartée

- Une demande faite aujourd'hui : elle apparaîtra demain.
- Une demande antérieure à la date de bascule du réseau : jamais reprise.
- Un écran en erreur : **Impossible de charger l'aperçu du prochain
  virement.** ne dit rien des demandes ; utilisez **Réessayer**.

## Portée de l'aide Néo

Néo explique les motifs et les corrections. Il ne modifie aucune fiche, ne
libère aucune demande et ne relance aucun virement.

Vérification au 30 octobre 2026 : section Écartées, libellés des motifs,
ouverture des formulaires, règle des données manquantes et reprise à la
génération lus dans le BO et l'API. Aucune correction ni génération réelle.
