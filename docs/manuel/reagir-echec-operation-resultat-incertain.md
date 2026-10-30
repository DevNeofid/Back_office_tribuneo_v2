# Réagir à un échec ou à un résultat incertain

## Objectif

Savoir quoi faire après un message d'erreur, une attente anormale ou une
fenêtre fermée sans confirmation, sans risquer de faire deux fois la même
opération.

## Le principe

- Un message d'échec ne prouve pas que rien n'a été enregistré : plusieurs
  opérations enregistrent des données avant de produire un fichier ou de
  relire l'écran.
- Un message de succès ne remplace pas le contrôle du résultat.
- **Vérifiez avant de répéter.** Une seconde tentative peut créer un doublon,
  envoyer un second e-mail ou consommer une étape qui ne s'annule pas.

## Vérifier avant de répéter

1. Notez le message exact, l'heure et la référence concernée.
2. Ne recliquez pas. Fermez la fenêtre si nécessaire, puis rechargez la page.
3. Contrôlez l'élément à l'endroit indiqué ci-dessous.
4. Si l'opération est faite, ne la refaites pas : récupérez le document ou
   poursuivez. Si elle ne l'est pas, réessayez une seule fois.
5. Si le résultat reste incohérent, arrêtez les tentatives et signalez-le.

## Où contrôler selon l'opération

| Opération | Ce qui peut déjà être fait malgré l'erreur | Où contrôler | Fiche |
| --- | --- | --- | --- |
| Générer la facture | Facture créée, PDF non reçu | **Documents → Factures** ; retéléchargez plutôt que régénérer | [Générer la facture](generer-facture-commande.md) |
| Générer l'ordre de virement | Ordre enregistré avant ses fichiers, même avec **La génération a échoué. Aucun virement n'a été enregistré…** | **Prochain virement** puis **Virements** | [Générer l'ordre](generer-ordre-virement.md) |
| Déclencher les écritures comptables | Lot enregistré avant l'envoi du ZIP | Historique de **Écritures**, après réouverture | [Générer les écritures](generer-ecritures-comptables.md) |
| Télécharger une facture de frais de gestion | Facture et justificatif numérotés avant l'échec du PDF | Liste **Documents → Frais de gestion** | [Factures de frais](consulter-telecharger-factures-frais-gestion.md) |
| Créer une commande à la main | Commande enregistrée ; formulaire fermé sans message clair | **Liste des commandes** | [Saisie manuelle](creer-commande-manuelle.md) |
| Importer une commande | Commande créée et e-mails envoyés ; aucune protection contre un second envoi | **Liste des commandes** avant tout nouvel import | [Import](creer-commande-import-fichier.md) |
| Enregistrer un paiement | Paiement enregistré ; le montant reste dans le champ | Lignes de **Paiements**, fenêtre rouverte | [Enregistrer un paiement](enregistrer-paiement-commande.md) |
| Supprimer un paiement ou une commande | Suppression faite malgré un message ou une fenêtre restée ouverte | **Paiements** rouverte ; liste des commandes rechargée | [Paiement](supprimer-paiement-commande.md), [commande](supprimer-commande.md) |
| Modifier une commande, changer une date | Changement enregistré ; la date part dès la validation du calendrier | Colonnes **Qté**, **Facturé**, **Expiration** ; **Gestion des bons** | [Modifier](modifier-commande.md), [validité](changer-validite-commande.md) |
| Désactiver un bon | Bon désactivé | Colonne **Suppression** après réouverture | [Désactiver un bon](desactiver-bon.md) |
| Renvoyer l'e-mail cadeau | E-mail déjà parti | Faites vérifier l'envoi avant de renvoyer | [Renvoyer](renvoyer-cadeau-beneficiaire.md) |
| Générer le ZIP des QR codes | Génération poursuivie côté serveur | Téléchargements du navigateur ; faites vérifier avant un nouveau lancement | [QR codes](generer-qr-codes-commande.md) |
| Ajouter un client ou un partenaire | Fiche créée ; pour un partenaire, ajout partiel possible | Recherche par nom, puis par SIRET | [Client](ajouter-client-professionnel.md), [partenaire](ajouter-partenaire.md) |
| Dupliquer un client en partenaire | Message de succès affiché avant la réponse du serveur | **Partenaires** et **Clients** | [Dupliquer](dupliquer-client-en-partenaire.md) |
| Modifier coordonnées bancaires, adresse ou secteurs d'un partenaire | Coordonnées enregistrées puis erreur ; secteurs retirés puis non rajoutés ; un nouvel ajout d'adresse peut créer une seconde adresse | Onglets de la carte partenaire | [Coordonnées](renseigner-coordonnees-bancaires-partenaire.md), [adresse](renseigner-adresse-partenaire.md), [secteurs](attribuer-secteurs-partenaire.md) |
| Ajouter ou supprimer un secteur | Opération faite, rechargement en échec | Liste **Secteurs d'activité** rouverte | [Créer](creer-secteur-activite.md), [supprimer](supprimer-secteur-activite.md) |
| Mettre en attente ou libérer une demande | Effet non précisé par le message d'erreur | Section de la demande dans **Prochain virement** rechargé | [Mise en attente](mettre-en-attente-liberer-demande-remboursement.md) |

## À ne pas faire pour compenser

- Régénérer une facture pour contourner un téléchargement : cela remplace la
  référence enregistrée.
- Générer un nouvel ordre de virement pour remplacer un ZIP manquant :
  retéléchargez l'ordre existant depuis **Virements**.
- Déclencher de nouveau les écritures comptables parce que le ZIP n'est pas
  arrivé : utilisez la ligne de l'historique.
- Supprimer un autre paiement, ou en saisir un second, pour corriger un cumul
  supposé faux.
- Transmettre deux fois à la banque le même fichier de virement : vérifiez
  qu'il ne l'a pas déjà été.

## Interruption de connexion

Si la session a expiré pendant une opération, reconnectez-vous puis contrôlez
le résultat dans l'écran concerné avant de recommencer : une erreur de
connexion ne garantit pas l'absence d'effet. Voir
[Résoudre un problème de connexion](resoudre-probleme-connexion.md).

## Signaler

Arrêtez les tentatives et signalez la situation à votre interlocuteur habituel
chez Tribuneo ou Neofid lorsque le résultat reste incohérent après contrôle.
Transmettez le message exact, l'heure approximative, l'écran, la référence
(numéro de commande, de facture, de demande ou nom du fichier) et ce que vous
avez vérifié. Ne communiquez ni mot de passe, ni jeton, ni IBAN complet.
Cette fiche n'indique aucune adresse de support : passez par votre
interlocuteur habituel.

## Avec Néo

Demandez par exemple : « La génération de l'ordre de virement a échoué, puis-je
relancer ? » ou « J'ai eu une erreur en enregistrant un paiement, que
vérifier ? ». Néo indique où contrôler le résultat et la fiche à suivre. Il ne
relance aucune opération et ne peut pas confirmer un effet qu'il n'a pas lu ;
pour une commande, il peut relire en lecture seule ses paiements et sa facture.

Vérification au 30 octobre 2026 : comportements après erreur repris des 73
fiches vérifiées des lots 01 à 05 ; ordre d'enregistrement de la facture relu
dans l'API. Aucune opération métier ni appel réseau.
