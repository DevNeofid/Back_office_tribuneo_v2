# Générer les écritures comptables

## Objectif et prérequis

Créer un nouveau lot d'écritures et télécharger son ZIP depuis le back-office,
avec un accès administrateur du réseau. Les écritures doivent être activées
et leur [configuration vérifiée](configurer-ecritures-comptables.md).

Le déclenchement crée des fichiers et un enregistrement d'historique. Il peut
aussi rendre des paiements non supprimables. Pour récupérer un lot existant,
utilisez [le retéléchargement](retelecharger-ecritures-comptables.md).

## Étapes

1. Ouvrez **Écritures**. L'écran porte le titre **Écritures comptables**.
2. Consultez d'abord les lignes **Nom du fichier** et **Date de création** de
   l'historique pour vérifier qu'un lot répondant au besoin n'existe pas déjà.
   Aucun sélecteur de période n'est proposé.
3. Si vous souhaitez réellement créer le lot suivant, cliquez une seule fois
   sur **Déclencher les écritures comptables**. Il n'y a pas de confirmation
   intermédiaire. La fenêtre **Génération des écritures comptables...** s'ouvre.
4. Attendez le téléchargement du ZIP. Après l'opération, vérifiez le fichier
   reçu et l'historique. Le code ne rafraîchit pas explicitement le tableau après
   une génération : quittez puis rouvrez **Écritures** pour le relire si besoin.
5. En cas de message ou d'absence de fichier, vérifiez l'historique avant de
   recommencer. Une erreur visible ne garantit pas l'absence de lot enregistré.

## Période calculée

La période est calculée automatiquement ; elle ne part pas d'une date choisie
par l'utilisateur et ne correspond pas simplement aux dates de paiement.

| Situation | Bornes établies dans le code |
|---|---|
| Première génération, sans historique | Borne de départ au 31 décembre de l'année courante moins deux ans, à `23:59:59`. Le nom du lot annonce le 1er janvier suivant. Par exemple, pour une génération le 30 octobre 2026, départ SQL `2024-12-31 23:59:59`, début annoncé `2025-01-01`, fin annoncée `2026-10-29`. Exemple synthétique, sans opération réelle. |
| Générations suivantes | Le jour de création du dernier lot est relevé. La borne SQL est la veille de ce jour à `23:59:59` ; le début annoncé dans le nom est le jour de création de ce dernier lot. |
| Fin | La veille de la génération à `23:59:59` dans les requêtes de sélection. Les opérations enregistrées le jour même sont normalement destinées au lot suivant. |

Attention à la précision de la borne : les requêtes utilisent **BETWEEN**, donc
la seconde `23:59:59` du jour précédant le début annoncé est incluse. Il ne faut
pas promettre un départ strict à minuit ni l'absence de recouvrement à cette
seconde. Le calcul des dates et du nom dans l'API utilise **Europe/Paris** ; la
fin de sélection utilise `CURDATE()` dans la base SQL. Le fuseau effectif de
cette session SQL n'a pas été établi par la lecture des sources.

Les factures de commande et de frais sont sélectionnées selon leur
**date de création**. Les paiements sont eux aussi sélectionnés selon leur
date de création, puis les lignes sont datées selon leur date de paiement.
Les paiements doivent être rattachés à une facture et à des informations
comptables d'entité par les jointures du code. La génération ne crée pas les
factures manquantes.

Après une génération le jour J, un second déclenchement ce même jour est
normalement refusé : la date issue du dernier lot est déjà la veille courante.
Le contrôle compare l'égalité des dates ; il ne constitue pas un verrou de
concurrence entre deux déclenchements simultanés.

## ZIP et fichiers produits

- Le nom enregistré par l'API et visible dans l'historique est
  `ECRITURES_<début>_<fin>.zip`, avec des dates `AAAA-MM-JJ`.
- Lors du téléchargement initial, le BO impose plutôt
  `ECRITURES_<veille>.zip`. Cette veille est calculée à l'ouverture de l'écran
  selon l'horloge locale du navigateur. Le nom initial ne prouve donc pas la
  période réellement traitée. Le retéléchargement utilise le nom d'historique.
- Avec un seul compte bancaire configuré : une paire de fichiers `.csv` et
  `.TXT`, nommée avec les deux bornes, rassemble les écritures.
- Avec plusieurs comptes configurés : une paire par compte ayant des lignes,
  suffixée par le libellé nettoyé et le compte 512, ainsi qu'une paire
  `_VENTES` pour les journaux hors banque lorsqu'ils ont des lignes. Les codes
  de comptes sont ajoutés si deux suffixes seraient identiques.
- Les deux extensions reçoivent les mêmes lignes de texte, séparées par des
  virgules, sans en-tête ; l'encodage est celui du réseau, sinon UTF-8. La
  numérotation recommence par fichier. Les libellés sont limités à 40 caractères.

Une période sans écritures peut tout de même produire un ZIP contenant une
paire vide : paire sans suffixe avec un seul compte, paire `_VENTES` avec
plusieurs comptes. Ce lot vide est enregistré et avance aussi l'historique et
le seuil utilisé pour la suppression des paiements.

## Refus et résultat incertain

| Situation | Comportement lu |
|---|---|
| Écritures désactivées | Refus API 400 : `Accounting entries are not enabled for this network.` |
| Pas de nouvelle période selon le contrôle de dates | Refus API 400 : `No new accounting entries to generate.` |
| Compte par défaut absent, paramètre réseau requis vide, encodage non accepté | Refus API 400 avant création du lot. |
| Journal/512 absent sur un compte utilisé, compte inconnu ou numéro comptable requis manquant | Erreurs détaillées dans la fenêtre **Aucune écriture comptable générée**, à transmettre à Neofid. |
| Autre erreur de génération | Le BO affiche généralement **Erreur lors de la génération des écritures comptables.** ; les deux premiers refus ne sont pas nécessairement affichés dans leur texte API. |

L'enregistrement du lot précède l'ouverture du ZIP pour la réponse. Un fichier
absent, une lecture impossible ou une interruption de téléchargement peuvent
donc laisser un lot déjà créé. Ne recliquez pas pour compenser un fichier non
reçu : relisez d'abord l'historique et utilisez sa ligne de téléchargement.
Si la situation reste incohérente, signalez-la à Neofid.

## Effets sur les suppressions

La suppression d'un paiement est refusée si sa date de création est
**strictement antérieure à la date et l'heure de création du dernier lot**.
Le contrôle ne vérifie pas que ce paiement figurait réellement dans le ZIP.
Il peut donc concerner un paiement du jour, pourtant exclu de la période, ou
un paiement absent d'un lot vide. Consulter ou retélécharger un lot n'avance
pas ce seuil.

La règle souhaitée de ne pas supprimer une commande déjà facturée et exportée
ne doit pas être présentée comme un verrou API général : l'action de
suppression de commande lue vérifie les bons attribués/utilisés et ne contrôle
ni facture ni historique comptable. Cette fiche ne décrit aucun contournement
ou procédure de suppression. Les verrous de choix du compte bancaire restent
distincts et ne sont pas changés par cette génération.

## Avec Néo

Néo peut expliquer le parcours, la période, les fichiers et les refus. Il ne
déclenche pas d'écritures, ne génère pas de ZIP et ne télécharge pas ce document
à votre place. Il ne fournit pas de conseil comptable.
