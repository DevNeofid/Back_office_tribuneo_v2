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
| [Générer la facture d'une commande](generer-facture-commande.md) | M01 intégrée localement par M12 ; code lu, tests locaux réussis ; déploiement et recette chat/visuelle à faire. |
| [Générer le bon de livraison](generer-bon-livraison-commande.md) | M01 intégrée ; facture préalable ; fonctionnement de l'URL à double barre oblique non vérifié en préproduction. |
| [Générer le récapitulatif](generer-recapitulatif-commande.md) | M01 intégrée ; parcours et format lus dans le code ; recette distante à faire. |
| [Créer une commande par import CSV/XLSX](creer-commande-import-fichier.md) | M02 intégrée ; occasion et e-mails documentés ; aucun import réel ni recette visuelle/chat exécuté. |
| [Format du fichier d'import](annexes/format-import-commande.md) | Annexe M02 intégrée ; CSV d'exemple volontairement non importable ; conversion XLSX non exécutée. |

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
existantes restent inchangés. Aucun déploiement n'est revendiqué pour le lot 01.
