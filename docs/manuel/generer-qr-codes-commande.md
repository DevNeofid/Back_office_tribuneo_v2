# Générer et télécharger les QR codes d'une commande

## Objectif et prérequis

Obtenir une archive ZIP des QR codes des bons d'une commande existante, avec
les droits d'administration du réseau. La commande doit comporter des bons non
annulés et la génération doit être disponible pour son réseau. Il s'agit des
QR de commande ; les QR d'accès ou de réception d'un partenaire relèvent d'un
autre parcours.

## Étapes

1. Ouvrez **Commandes**, écran **Liste des commandes**, puis retrouvez la
   commande et vérifiez son numéro.
2. Ouvrez l'icône de la colonne **Gestion**, puis choisissez
   **Générer les QR Code** une seule fois. **Cette sélection lance directement
   la génération, sans confirmation.**
3. Le message **Génération en arrière-plan, vous pouvez continuer à naviguer.**
   apparaît. Il annonce le lancement, pas un ZIP prêt. Vous pouvez naviguer
   dans le BO ; gardez la page de l'application ouverte pendant l'attente.
4. Le BO suit automatiquement la génération. Aucun pourcentage ni écran
   d'historique des générations n'est proposé dans ce parcours. Attendez
   **Génération terminée**, puis **Les QR Codes pour la commande … sont prêts.
   Le téléchargement commence.**
5. Le navigateur reçoit un ZIP nommé
   `<nom du client>_<numéro de commande>.zip`, avec les espaces du nom remplacés
   par des tirets bas. Vous pouvez fermer le message avec **Fermer**.
6. Vérifiez dans les téléchargements du navigateur que le fichier est réellement
   enregistré et s'ouvre. Le message du BO ne confirme pas cette dernière étape.
   Contrôlez aussi le contenu et les éventuelles erreurs du manifeste avant
   d'utiliser les documents ; aucun scan n'est nécessaire pour ce contrôle.

## Attente, erreurs et récupération

| Situation | Conduite à tenir |
|---|---|
| Message de lancement uniquement | La génération peut être en attente ou en cours. Ce message ne confirme ni la réussite ni l'exhaustivité du ZIP. Ne multipliez pas les lancements. |
| **Génération terminée**, mais aucun fichier visible | Consultez les téléchargements et les éventuels blocages du navigateur avant de relancer. Le BO ne vérifie pas l'enregistrement du fichier sur votre poste. |
| **Erreur lors de la génération des QRcode.** | Message générique : vérifiez d'abord si un téléchargement a commencé. Si aucun résultat n'est récupérable, signalez le numéro de commande et le message à votre interlocuteur Tribuneo avant de recommencer. |
| Attente anormalement longue ou page fermée/rechargée | Aucun bouton de reprise d'un ancien résultat n'est proposé. Faites vérifier la génération avant un nouveau lancement ; sa poursuite côté serveur et sa récupération dans le navigateur sont deux choses différentes. |

## Limites

- Le suivi automatique attend la fin de la génération puis récupère son
  résultat. Une demande acceptée en arrière-plan ne vaut pas téléchargement.
- Des erreurs partielles peuvent figurer dans `manifest.json`, ou dans les
  manifestes par réseau d'un ZIP assemblé. Le BO ne les affiche pas. Un ZIP
  téléchargé ne garantit donc pas un document réussi pour chaque bon.
- Les bons annulés sont exclus de la génération. Ce téléchargement ne constitue
  pas une vérification de la validité ou de la bonne lecture de chaque QR.
- Pour les UUID sous forme de texte, voir
  [Générer le CSV](generer-csv-bons-commande.md). Pour les montants et coordonnées,
  voir [Générer le récapitulatif](generer-recapitulatif-commande.md).

## Avec Néo

Demandez : « Comment télécharger le ZIP des QR codes d'une commande ? ».
Néo explique le parcours ; il ne lance pas de génération, ne suit pas les jobs
et ne récupère ni ne joint le ZIP avec ses outils actuels.
