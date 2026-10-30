# Manuel utilisateur du back-office Tribuneo

Le manuel est construit progressivement à partir du code de l'interface. Les
fiches sont organisées par tâche et servent aussi de source à l'aide de Néo.

| Fiche | État au 30 octobre 2026 |
|---|---|
| [Rechercher une commande](rechercher-commande.md) | Libellés et fonctionnement vérifiés dans le code ; recette visuelle en préproduction à confirmer. |
| [Consulter les paiements d'une commande](consulter-paiements-commande.md) | Code vérifié, déploiement MCP et réponse du chat contrôlés ; parcours de consultation en préproduction confirmé par l'exploitant. |
| [Retélécharger une facture existante](retelecharger-facture-existante.md) | Parcours Documents → Factures → Télécharger et récupération du PDF confirmés en préproduction par l'exploitant. |
| [Créer une commande en saisie manuelle](creer-commande-manuelle.md) | Procédure du chat, refus de création par Néo et champs du formulaire confirmés par l’exploitant, sans enregistrement de commande. |
| [Enregistrer un paiement sur une commande](enregistrer-paiement-commande.md) | Guidage et champs du formulaire confirmés par l’exploitant, sans enregistrement de paiement réel. |
| [Supprimer un paiement d’une commande](supprimer-paiement-commande.md) | Parcours, confirmation et refus comptable vérifiés dans le code ; retour global positif de l’exploitant après la recette proposée avec Annuler, sans détail des scénarios transmis ni suppression réelle. |
| [Générer la facture d'une commande](generer-facture-commande.md) | Lot 01 (M01) publié ; retour global du propriétaire « C'est validé ! », sans détail des scénarios transmis ni facturation réelle revendiquée. |
| [Générer le bon de livraison](generer-bon-livraison-commande.md) | Lot 01 (M01) ; même retour global ; fonctionnement de l'URL à double barre oblique non vérifié en préproduction. |
| [Générer le récapitulatif](generer-recapitulatif-commande.md) | Lot 01 (M01) ; même retour global ; parcours et format lus dans le code. |
| [Créer une commande par import CSV/XLSX](creer-commande-import-fichier.md) | Lot 01 (M02) ; même retour global ; aucun import réel revendiqué. |
| [Format du fichier d'import](annexes/format-import-commande.md) | Lot 01 (M02) ; CSV d'exemple volontairement non importable ; conversion XLSX non exécutée. |
| [Comprendre les informations d'une commande](comprendre-commande.md) | Lot 02 (M03) intégré localement par M12 ; code lu, tests locaux réussis ; déploiement et recette chat/visuelle à faire. |
| [Vérifier le solde et le statut payé d'une commande](verifier-solde-commande.md) | Lot 02 (M03) ; l'indicateur « payée » peut différer des montants après modification du total. |
| [Créer une commande depuis la fiche d'un client](creer-commande-depuis-client.md) | Lot 02 (M03) ; icône sans libellé à confirmer visuellement ; aucun enregistrement réel. |
| [Modifier une commande](modifier-commande.md) | Lot 02 (M03) ; restrictions après facturation, import et bons attribués lues dans l'API. |
| [Changer la date de validité d'une commande](changer-validite-commande.md) | Lot 02 (M03) ; envoi dès la validation du calendrier : recette par annulation du calendrier uniquement. |
| [Supprimer une commande](supprimer-commande.md) | Lot 02 (M03) ; refus d'une commande facturée énoncé par le propriétaire, non imposé par le code lu ; aucune restauration dans le BO. |
| [Ajouter un client particulier](ajouter-client-particulier.md) | Lot 02 (M04) intégré localement par M12 ; code et API lus ; déploiement et recette à faire. |
| [Ajouter un client professionnel et rechercher son SIRET](ajouter-client-professionnel.md) | Lot 02 (M04) ; recherche SIRET interne à Tribuneo, non exécutée. |
| [Rechercher et filtrer un client](rechercher-client.md) | Lot 02 (M04) ; les icônes « Filtres » choisissent l'onglet affiché, sans filtrer. |
| [Modifier les informations générales d'un client](modifier-client.md) | Lot 02 (M04) ; code client non repris par l'API et préférence de dématérialisation envoyée à faux. |
| [Renseigner ou modifier l'adresse d'un client](renseigner-adresse-client.md) | Lot 02 (M04) ; adresse nécessaire à la facturation. |
| [Renseigner les informations bancaires accessibles pour un client](renseigner-coordonnees-bancaires-client.md) | Lot 02 (M04) ; numéro comptable et intracommunautaire seulement, aucun IBAN client. |
| [Dupliquer un client en partenaire](dupliquer-client-en-partenaire.md) | Lot 02 (M04) ; message de succès possiblement anticipé, à vérifier. |
| [Désactiver un client et comprendre les refus](desactiver-client.md) | Lot 02 (M04) ; suppression possible de l'entité commune, non testée ; message d'impayés trop général. |

Le [plan du manuel](../PLAN_MANUEL_UTILISATEUR.md) conserve la liste des chapitres
à rédiger. Il ne remplace pas les procédures détaillées.

Lorsqu'une vue évolue, mettre à jour sa fiche dans le même changement. Pour Néo,
publier aussi sa copie dans le catalogue du dépôt `Tribuneo_Neo` et actualiser
l'empreinte attendue : le serveur refuse de servir une copie modifiée sans mise
à jour de son catalogue. La provenance technique des fiches est consignée dans
ce dépôt Néo, sous `docs/MANUEL_*_PROVENANCE.json`.

Les provenances M01/M02 et le raccordement M12 sont dans le dépôt Néo sous
`docs/livrables/M01/`, `M02/` et `M12/`. Le [CSV d'exemple](exemples/commande-import-exemple.csv)
est une ressource inerte : conserver `NE_PAS_IMPORTER_M02`, sélectionner puis
fermer sans enregistrer pour la recette. Les résultats M00 des six fiches
existantes restent inchangés.

Après publication, déploiement et recette du lot 01, le propriétaire a déclaré
« C'est validé ! ». Ce retour global ne détaille pas les scénarios vérifiés et
ne vaut pas opération métier réelle. Les livrables du lot 02 (M03 commandes,
M04 clients) et leur raccordement sont sous `docs/livrables/M03/`, `M04/` et
`M12/lot-02/` du dépôt Néo. Aucun déploiement n'est revendiqué pour le lot 02.
