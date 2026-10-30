# Manuel utilisateur du back-office Tribuneo

Le manuel est construit progressivement à partir du code de l'interface. Les
fiches sont organisées par tâche et servent aussi de source à l'aide de Néo.

| Fiche | État au 29 octobre 2026 |
|---|---|
| [Rechercher une commande](rechercher-commande.md) | Libellés et fonctionnement vérifiés dans le code ; recette visuelle en préproduction à confirmer. |
| [Consulter les paiements d'une commande](consulter-paiements-commande.md) | Code vérifié, déploiement MCP et réponse du chat contrôlés ; parcours de consultation en préproduction confirmé par l'exploitant. |
| [Retélécharger une facture existante](retelecharger-facture-existante.md) | Parcours Documents → Factures → Télécharger et récupération du PDF confirmés en préproduction par l'exploitant. |
| [Créer une commande en saisie manuelle](creer-commande-manuelle.md) | Procédure du chat, refus de création par Néo et champs du formulaire confirmés par l’exploitant, sans enregistrement de commande. |
| [Enregistrer un paiement sur une commande](enregistrer-paiement-commande.md) | Guidage et champs du formulaire confirmés par l’exploitant, sans enregistrement de paiement réel. |
| [Supprimer un paiement d’une commande](supprimer-paiement-commande.md) | Parcours, confirmation et refus comptable vérifiés dans le code ; retour global positif de l’exploitant après la recette proposée avec Annuler, sans détail des scénarios transmis ni suppression réelle. |

Le [plan du manuel](../PLAN_MANUEL_UTILISATEUR.md) conserve la liste des chapitres
à rédiger. Il ne remplace pas les procédures détaillées.

Lorsqu'une vue évolue, mettre à jour sa fiche dans le même changement. Pour Néo,
publier aussi sa copie dans le catalogue du dépôt `Tribuneo_Neo` et actualiser
l'empreinte attendue : le serveur refuse de servir une copie modifiée sans mise
à jour de son catalogue. La provenance technique des fiches est consignée dans
ce dépôt Néo, sous `docs/MANUEL_*_PROVENANCE.json`.
