# Générer l'ordre de virement des remboursements

## Objectif

Produire, en une fois, le fichier bancaire qui paie toutes les demandes de
remboursement **À payer** du menu **Prochain virement**. L'opération crée les
justificatifs et factures de frais qui manquent, enregistre l'ordre de
virement et télécharge un ZIP. Elle ne s'annule pas depuis le back-office.

## Avant de générer

- Relisez l'en-tête : période, **Compte payeur**, **Demandes à payer**,
  **Commerçants**, **Montant à virer**, **Demandes écartées**.
- Traitez si possible les demandes **Écartées** : voir
  [Traiter les demandes de remboursement écartées](traiter-demandes-remboursement-bloquees.md).
- Choisissez le compte si le réseau le permet : voir
  [Choisir le compte payeur](choisir-compte-payeur-virement.md).

Le bouton **Générer l'ordre de virement** est inactif sans demande à payer
ou pendant un chargement.

## Étapes

1. Cliquez sur **Générer l'ordre de virement**.
2. La fenêtre **Générer l'ordre de virement** rappelle le nombre de demandes
   et de commerçants, le **Montant à virer** et le **Compte payeur**. S'il y a
   des écartées, elle précise qu'elles ne seront pas payées.
3. Pour renoncer, cliquez sur **Annuler** : rien n'est envoyé. Pour lancer la
   génération, cliquez sur **Générer**.
4. Patientez pendant **Génération de l'ordre de virement...**. Ne relancez
   pas la génération.
5. Le ZIP est téléchargé par le navigateur et la fenêtre
   **Ordre de virement généré** indique le nombre de demandes payées et
   **Transmettez le fichier .SCT à votre banque.** S'il y a des écartées, elle
   renvoie au fichier `REMBOURSEMENTS_ECARTES.csv` du ZIP. Cliquez sur
   **Fermer**.
6. L'aperçu est rechargé : les demandes payées n'y figurent plus.

Le serveur refait la sélection au moment de la génération, avec la même
règle que l'aperçu. Le nombre final est celui de **Ordre de virement généré**.

## Contenu du ZIP

Le ZIP s'appelle `BTO_<date de la plus ancienne demande>_<date de la plus
récente>_<HHMMSS>.zip`, dates au format AAAA-MM-JJ. Si le navigateur ne reçoit
pas ce nom, le BO nomme le fichier `BTO_<date du jour>.zip`.

| Fichier | Contenu |
| --- | --- |
| `<JJMMAAAA_HHMMSS>.TXT.SCT` | Fichier de virement SEPA au format XML `pain.001.001.02` |
| `<AAAA-MM-JJ>.xlsx` | Récapitulatif : justificatifs, code, nom, total TTC, coordonnées bancaires |
| `REMBOURSEMENTS_ECARTES.csv` | Seulement s'il y a des écartées ; séparateur `;` |

Dans le fichier `.TXT.SCT`, chaque commerçant fait l'objet d'**un seul**
virement : ses demandes sont cumulées. Le nom, l'IBAN et le BIC du
commerçant sont ceux de sa fiche au moment de la génération. La date
d'exécution demandée est le jour de la génération.

## Ce que la génération change

- Chaque demande payée reçoit, si elle n'en a pas, un justificatif de
  réception et une facture de frais de gestion, datés du jour.
- L'ordre est enregistré et apparaît dans le menu **Virements**.
- Les demandes payées sont rattachées à cet ordre : elles ne seront plus
  jamais proposées, même si le fichier n'est pas transmis à la banque. Pour
  récupérer le fichier, voir
  [Consulter et retélécharger un ordre de virement](consulter-retelecharger-ordre-virement.md).

Générer l'ordre ne paie pas encore le partenaire. Le fichier doit être
transmis à la banque selon la procédure convenue avec elle, qui n'est pas
décrite ici ; c'est ensuite l'exécution par la banque qui crédite le
partenaire. Le back-office n'affiche ni la transmission ni l'exécution.

## Refus et échecs

| Message | Que faire |
| --- | --- |
| **Aucune demande à payer.** | Rien à générer ; l'aperçu est rechargé |
| **Le montant total à virer est nul.** | Rien n'est généré |
| **Une génération est déjà en cours, réessayez dans un instant.** | Une autre génération ou numérotation est en cours |
| **Le compte bancaire du réseau est incomplet, contactez le support.** | Compte payeur sans titulaire, IBAN ou BIC |
| **Configuration du réseau incomplète, contactez le support.** | Date de bascule manquante |
| **La génération prend plus de temps que prévu. Rechargez l'aperçu avant de réessayer : le virement a peut-être été enregistré.** | Voir ci-dessous |
| **Erreur réseau pendant la génération de l'ordre de virement. Rechargez l'aperçu avant de réessayer.** | Voir ci-dessous |
| **La génération a échoué. Aucun virement n'a été enregistré, vous pouvez réessayer.** | Voir ci-dessous |

Après un délai dépassé, une erreur réseau ou un échec, le résultat peut être
incertain. Le code lu enregistre l'ordre avant d'écrire les fichiers : même
avec le dernier message, un ordre peut exister. Avant de recommencer :

1. Rechargez **Prochain virement** et notez si les demandes ont disparu.
2. Ouvrez **Virements** et cherchez un ordre créé à cette heure-là.
3. S'il existe, retéléchargez-le plutôt que de générer à nouveau.

## Portée de l'aide Néo

Néo explique la génération ; il ne génère aucun ordre, ne transmet rien à la
banque et ne peut pas confirmer qu'un virement a été exécuté.

Vérification au 30 octobre 2026 : bouton, fenêtres, messages, repository,
action API de génération, verrou, sélection et construction des fichiers lus.
Aucune génération réelle ; fichiers non observés ; ouverture puis **Annuler**
non exécutées en session.
