# Choisir le compte payeur d'un ordre de virement

## Objectif

Savoir depuis quel compte bancaire du réseau l'ordre de virement paiera les
partenaires, et le changer quand le réseau le permet. Le compte se lit et se
choisit dans le menu **Prochain virement**, sur la ligne **Compte payeur :**
de l'en-tête.

Les comptes bancaires du réseau ne se créent ni ne se modifient dans le
back-office : leur configuration n'est pas décrite ici.

## Ce qu'affiche l'écran

| Situation du réseau | Affichage |
| --- | --- |
| Un seul compte | Texte fixe « libellé — IBAN » ; aucun choix |
| Compte payeur imposé par le réseau | Texte fixe ; aucun choix |
| Plusieurs comptes, sans compte imposé | Liste déroulante |
| Liste des comptes illisible | Texte fixe issu de l'aperçu ; l'API applique le compte de remboursement du réseau |

Dans la liste déroulante, chaque compte apparaît sous la forme
« libellé — IBAN — compte comptable », sans les parties absentes. Le compte
présélectionné est le compte de remboursement du réseau.

## Changer de compte

1. Ouvrez **Prochain virement**.
2. Dans **Compte payeur :**, choisissez un autre compte. La liste est
   inactive pendant un chargement ou une génération.
3. L'aperçu est rechargé avec ce compte. Vérifiez à nouveau l'en-tête.
4. La fenêtre de confirmation de **Générer l'ordre de virement** reprend le
   **Compte payeur** : contrôlez-le avant de cliquer sur **Générer**.

Le compte envoyé à la génération est celui de l'aperçu affiché. Le choix
n'est pas mémorisé : à la prochaine ouverture, le compte de remboursement est
de nouveau présélectionné.

## Effets du compte choisi

- Son titulaire, son IBAN et son BIC forment le bloc du donneur d'ordre du
  fichier de virement.
- Son code est enregistré sur l'ordre de virement. Le menu **Virements**
  l'affiche dans la colonne **Compte** quand le réseau a plusieurs comptes.
- Les écritures comptables des remboursements utilisent ce compte. Elles sont
  traitées dans les fiches sur les écritures comptables.

## Refus possibles

| Message | Signification |
| --- | --- |
| **Le compte bancaire choisi n'existe plus. La liste des comptes a été rechargée.** | Le compte a disparu ; choisissez-en un autre |
| **Ce réseau impose le compte payeur des ordres de virement. La liste des comptes a été rechargée.** | Le réseau impose un compte |
| **Le compte bancaire du réseau est incomplet, contactez le support.** | Titulaire, IBAN ou BIC manquant ; refus à la génération |
| **Aucun compte bancaire de remboursement n'est configuré pour ce réseau, contactez le support.** | Aucun compte par défaut |

Après un des deux premiers messages, la liste est rechargée et l'aperçu est
relu une fois. Vérifiez le compte affiché avant de générer.

## Confidentialité et portée de l'aide Néo

L'écran affiche en clair l'IBAN des comptes du réseau. Ne le copiez pas dans
une conversation. Néo explique le choix du compte ; il ne choisit aucun
compte, ne génère aucun ordre et ne donne pas de conseil bancaire.

Vérification au 30 octobre 2026 : liste déroulante, règles d'affichage,
modèle des comptes, résolution du compte payeur et contrôle des champs du
donneur d'ordre côté API lus. Aucun compte changé ni ordre généré en session.
