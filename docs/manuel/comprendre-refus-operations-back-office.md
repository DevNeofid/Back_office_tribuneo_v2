# Comprendre les refus du back-office

## Objectif

Comprendre pourquoi une opération est refusée, savoir qui la refuse et ce
qu'il faut vérifier avant d'agir. Cette fiche regroupe les refus fréquents ;
la conduite détaillée reste dans la fiche de chaque tâche.

## Trois origines à distinguer

- **Formulaire** : le back-office bloque avant l'envoi, marque un champ ou
  grise un bouton. Rien n'est envoyé. Le serveur ne refait pas toujours ce
  contrôle.
- **Serveur** : la demande est envoyée puis refusée. Le back-office traduit
  certains refus en message précis ; d'autres tombent sur un message générique
  qui ne désigne pas la cause.
- **Règle de gestion non bloquée** : consigne énoncée pour le réseau que le
  code lu n'impose pas. L'opération peut alors être acceptée : c'est à vous de
  vérifier avant de confirmer.

Un refus précis n'applique pas l'opération refusée. Un message générique, lui,
peut aussi suivre une opération déjà enregistrée : voir
[Réagir à un échec ou à un résultat incertain](reagir-echec-operation-resultat-incertain.md).

## Commandes et paiements

| Message ou signe | Cause vérifiée | Origine | Fiche |
| --- | --- | --- | --- |
| **Veuillez sélectionner une entité ("Offert par")**, **Veuillez sélectionner l'occasion (URSSAF)**, **Le montant des fonds non valide** | Client, occasion ou montant manquant | Formulaire | [Saisie manuelle](creer-commande-manuelle.md) |
| **Le montant saisi dépasse le montant total de la commande.** | Paiement supérieur au reste à payer ; s'affiche aussi sans **Méthode** choisie | Formulaire et serveur pour le plafond | [Enregistrer un paiement](enregistrer-paiement-commande.md) |
| **La date de paiement ne peut pas être antérieure à la date du dernier paiement.** | Date avant le dernier paiement | Formulaire ; contrôle non retrouvé dans l'enregistrement serveur lu | [Enregistrer un paiement](enregistrer-paiement-commande.md) |
| **Choisissez le compte sur lequel le paiement a été encaissé.** | Compte encaisseur exigé par le réseau | Formulaire et serveur | [Enregistrer un paiement](enregistrer-paiement-commande.md) |
| **Impossible de supprimer ce paiement : les écritures comptables ont déjà été générées.** | Paiement créé avant le dernier lot d'écritures, même vide | Serveur ; la corbeille reste visible | [Supprimer un paiement](supprimer-paiement-commande.md) |
| **Cette commande est facturée : …** | Une facture existe : seule la date de validité change | Serveur, avec bandeau du formulaire | [Modifier une commande](modifier-commande.md) |
| **Impossible de retirer autant de bons de … €** | Trop de bons de ce montant déjà attribués | Serveur | [Modifier une commande](modifier-commande.md) |
| **Ce bon est déjà attribué : sa date peut seulement être prolongée.** ou **Impossible d'avancer la date : …** | Un bon attribué serait avancé | Serveur | [Validité](changer-validite-commande.md), [expiration d'un bon](changer-expiration-bon.md) |
| **La date doit être au plus tôt demain.** | Date antérieure à demain, par exemple page ouverte depuis la veille | Calendrier et serveur | [Validité](changer-validite-commande.md) |
| **Erreur lors de la suppression de la commande, au moins un utilisateur a scanné son bon sur cette commande.** | Cause habituelle : bon non annulé attribué ou utilisé. Le même texte s'affiche pour tout autre échec | Serveur ; message unique | [Supprimer une commande](supprimer-commande.md) |
| **Erreur : Pensez à vérifier que votre client a une adresse de renseignée ?** | Adresse manquante possible, ou autre erreur ; le serveur lu n'a pas de refus dédié à l'adresse | Message générique | [Générer la facture](generer-facture-commande.md) |
| **Erreur lors de la génération du PDF.** (bon de livraison) | Cause attendue : aucune facture ; sinon autre erreur | Message générique | [Bon de livraison](generer-bon-livraison-commande.md) |

Un paiement n'est pas exigé pour facturer, et une facture n'est pas exigée pour
enregistrer un paiement.

## Bons

| Message ou signe | Cause vérifiée | Origine | Fiche |
| --- | --- | --- | --- |
| Infobulle **Bon associé à un utilisateur, désactivation impossible** | Contacts affichés pour le compte associé | Formulaire | [Désactiver un bon](desactiver-bon.md) |
| **Impossible de désactiver ce bon : il est associé à un utilisateur.** | Bon attribué, même si le bouton semblait actif | Serveur | [Désactiver un bon](desactiver-bon.md) |
| **Ces bons sont déjà attribués à des consommateurs : …** | Renvoi d'e-mail demandé pour un bon attribué | Serveur ; texte commun à plusieurs refus | [Renvoyer l'e-mail cadeau](renvoyer-cadeau-beneficiaire.md) |
| **Ce bénéficiaire n'a pas d'adresse e-mail.** | Aucun e-mail enregistré ; un mobile ne suffit pas | Serveur | [Renvoyer l'e-mail cadeau](renvoyer-cadeau-beneficiaire.md) |
| **Ce bon a été annulé.** | Bon désactivé | Serveur | [Expiration d'un bon](changer-expiration-bon.md) |
| **Erreur lors de la génération du CSV.** | Commande, bons ou liens QR introuvables, entre autres | Serveur, message générique | [CSV des UUID](generer-csv-bons-commande.md) |

## Clients, partenaires et secteurs

| Message ou signe | Cause vérifiée | Origine | Fiche |
| --- | --- | --- | --- |
| **🚩 Numéro SIRET invalide**, **🚩 Numéro de mobile non valide**, **🚩 Texte non valide** | Format ou champ vide | Formulaire | [Client professionnel](ajouter-client-professionnel.md), [partenaire](ajouter-partenaire.md) |
| **Erreur lors de l’inscription : …** ou **Erreur lors de l'ajout du client : …** | Notamment une entité qui a déjà ce rôle dans le réseau (`An entity with the same siret and type already exists`) | Serveur | [Ajouter un partenaire](ajouter-partenaire.md), [client professionnel](ajouter-client-professionnel.md) |
| **Erreur lors de la désactivation du client, au moins une commande associée n'est pas totalement payée.** | Une commande marquée non payée est une cause possible ; le même texte couvre tout autre refus | Serveur, sur l'indicateur « payée » ; message générique | [Désactiver un client](desactiver-client.md) |
| **Erreur lors de la désactivation du partenaire.** | Solde Tribuneo non nul, compte d'application absent ou rôle déjà désactivé | Serveur, message générique | [Désactiver un partenaire](desactiver-partenaire.md) |
| **Erreur lors de la modification du partenaire** | Champ vide, SIRET invalide ou déjà utilisé, entre autres | Serveur, message générique | [Modifier un partenaire](modifier-partenaire.md) |
| Fenêtre **Ajouter ce Partenaire comme Client** restée ouverte, sans message | Rôle client déjà présent ou entité introuvable | Serveur, sans message | [Dupliquer en client](dupliquer-partenaire-en-client.md) |
| **Erreur lors de la suppression du secteur d’activité** | Secteur lié à une entité, tous réseaux confondus ; ou échec du rechargement | Serveur, message générique | [Supprimer un secteur](supprimer-secteur-activite.md) |
| **Erreur lors de l’ajout du secteur d’activité** | Nom déjà existant, entre autres ; l'unicité vient de la base | Base de données, message générique | [Créer un secteur](creer-secteur-activite.md) |

## Remboursements et virements

| Message ou signe | Cause vérifiée | Origine | Fiche |
| --- | --- | --- | --- |
| Section **Écartées** et ses motifs | Adresse incomplète, IBAN ou BIC manquant, mise en attente, net nul, commerçant introuvable | Sélection du serveur | [Demandes écartées](traiter-demandes-remboursement-bloquees.md) |
| **Aucune demande à payer.**, **Le montant total à virer est nul.** | Rien à générer | Serveur | [Générer l'ordre](generer-ordre-virement.md) |
| **Une génération est déjà en cours, réessayez dans un instant.** | Autre génération ou numérotation en cours | Serveur | [Générer l'ordre](generer-ordre-virement.md) |
| **Le compte bancaire du réseau est incomplet, contactez le support.** | Compte payeur sans titulaire, IBAN ou BIC | Serveur | [Compte payeur](choisir-compte-payeur-virement.md) |
| **Ce réseau impose le compte payeur des ordres de virement. …** | Choix de compte non autorisé | Serveur | [Compte payeur](choisir-compte-payeur-virement.md) |
| **Cette demande a déjà été payée.** | Demande rattachée à un ordre | Serveur | [Mise en attente](mettre-en-attente-liberer-demande-remboursement.md) |

## Comptabilité, statistiques et connexion

| Message ou signe | Cause vérifiée | Origine | Fiche |
| --- | --- | --- | --- |
| Fenêtre **Aucune écriture comptable générée** | Paramètres manquants, détaillés ligne par ligne | Serveur | [Configurer les écritures](configurer-ecritures-comptables.md) |
| **Erreur lors de la génération des écritures comptables.** | Écritures non activées, aucune nouvelle période, paramètre réseau manquant, entre autres | Serveur, message générique | [Générer les écritures](generer-ecritures-comptables.md) |
| Tableau vide et **Erreur: Exception: Aucune donnée CSV reçue** | Même date en début et en fin, droits insuffisants, aucune ligne ou échec de lecture | Serveur, message générique | [Statistiques](consulter-exporter-statistiques.md) |
| **Accès refusé : votre compte n'est pas un compte administrateur.** | Compte autre qu'administrateur du réseau | Contrôle à la connexion | [Problème de connexion](resoudre-probleme-connexion.md) |
| **Trop de tentatives de connexion. Veuillez réessayer dans …** | Délai imposé après plusieurs échecs | Contrôle à la connexion | [Problème de connexion](resoudre-probleme-connexion.md) |

## Règles non bloquées et écarts connus

Ces points ne sont pas des refus garantis. Ne les présentez pas comme tels.

- **Commande facturée ou exportée en comptabilité** : sa suppression est
  énoncée comme interdite pour le réseau, mais le serveur lu contrôle seulement
  les bons attribués ou utilisés. Vérifiez la facture avant de confirmer. Aucune
  règle n'est établie pour une commande payée mais non facturée.
- **Bouton actif, refus possible** : la corbeille d'un paiement, le bouton de
  désactivation d'un bon et **Renvoyer l'e-mail** dans **Gestion des bons**
  peuvent être proposés alors que le serveur refusera.
- **Libérer la demande** annonce une inclusion au prochain virement, même si
  un autre motif l'écarte encore.
- **Message de succès sans effet garanti** : le code client ou partenaire
  modifié n'est pas enregistré ; **Client dupliqué en partenaire avec succès !**
  peut s'afficher avant la réponse du serveur.
- **Désactiver un client** peut supprimer l'entité commune ; **Désactiver un
  partenaire** n'offre aucune réactivation. La réversibilité n'est pas établie.

## Après un refus

1. Relevez le message exact et l'écran.
2. Identifiez son origine avec les tableaux ci-dessus. Pour un message
   générique, vérifiez les données avant de conclure à une cause.
3. Ne contournez pas le contrôle : pas de paiement fictif, pas d'opération
   pour vider un solde, pas de facture générée uniquement pour débloquer une
   autre action.
4. Si le refus reste incompris, transmettez à votre interlocuteur habituel le
   message, l'heure, l'écran et la référence concernée (numéro de commande, de
   facture ou de demande), sans mot de passe, jeton ni IBAN complet.

## Avec Néo

Demandez par exemple : « Pourquoi le back-office refuse de supprimer ce
paiement ? » ou « Que signifie le message sur l'adresse du client lors de la
facturation ? ». Néo explique la cause documentée et son origine ; il ne
contourne aucun contrôle et ne relance aucune opération.

Vérification au 30 octobre 2026 : messages et causes repris des 73 fiches
vérifiées des lots 01 à 05 ; origine relue dans le BO (traduction des codes de
refus, contrôles du formulaire de paiement) et dans l'API (suppression de
commande et de paiement, enregistrement d'un paiement, modification d'une
commande facturée, génération de facture). Aucune opération métier.
