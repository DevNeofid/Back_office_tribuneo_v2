# Composants locaux E08

Implémentation : `lib/presentation/widgets/merchant_enrichment/ui/enrichment_dialog.dart`.
Portée : dialogues enrichissement et import seulement. Aucune modification de
ThemeData global, de common.dart, de NeoButton ou du rendu global de l'assistant.

## API

| Composant | Responsabilité |
| --- | --- |
| EnrichmentDialog | title, content, actions, largeur maximale, contenu défilant ou contraint, fermeture facultative |
| EnrichmentNotice | Surface d'information/erreur avec icône, bordure et liveRegion pour l'erreur |
| EnrichmentBadge | Bilan/statut textuel sur fond clair |
| EnrichmentComparison | Présenter les DataColumn/DataRow existants en colonnes ou cartes |

EnrichmentDialog réutilise kBlue/kBlueEnd, kOrange, kPWhite, kLGrey, kLBlue,
kBlack et kRed. Rayons 12–16, espacements 8/12/16/20. Le thème local utilise
`Poppins_regular`, famille déjà enregistrée par GoogleFonts dans les pages BO,
sans déclencher de chargement de police supplémentaire. Vérifier la police réelle
dans la recette M12 ; le test peut substituer Segoe UI hors ligne.

## Contraintes et responsabilité

- La route Dialog conserve son traitement Flutter des insets/clavier et de la
  zone sûre. Marge de 12 px, largeur maximale propre au dialogue, aucun couple
  largeur/hauteur fixe 1000×620, 900×500 ou 720×690.
- `scrollable: true` donne un corps défilant indépendant du pied d'actions ;
  `false` permet les listes/onglets ou l'AssistantPanel avec leurs contraintes.
- Le panneau principal distribue la hauteur entre un résumé défilant et les
  onglets ; le bouton de recherche reste dans la partie fixe de l'onglet sélection.
- Les onglets défilent horizontalement localement, jamais toute la page.
- Le formulaire passe en deux colonnes à 520 px disponibles ; la comparaison
  passe en colonnes à 700 px disponibles. Les actions utilisent Wrap.
- Les URL, dates, sources, avertissements, valeurs et consentements restent
  dans le corps défilant. Aucun champ n'est sélectionné par le composant.
- Le titre a trois lignes maximum ; le contenu garde l'identité complète.
- Les boutons Flutter conservent leurs états enabled/disabled/focus. `onClose`
  est fourni par le parent selon ses gardes ; le composant n'en crée aucune autre.
- EnrichmentComparison réutilise chaque DataCell et sa Checkbox, sans décider
  de l'applicabilité, du couplage lat/lng, de la TVA ou de l'application.

Les méthodes/classes/callbacks de parcours et ValueKeys restent dans les vues.
E07 fournit le catalogue de messages ; ce composant n'importe aucun catalogue
fictif et ne prend aucune décision réseau/métier.

## Vérification

`test/merchant_enrichment/ui_layout_test.dart` exerce les vrais widgets et
usecases avec des dépôts synthétiques. Quatre tailles à 130 %, 21 scénarios :
sélection, confirmation, résultats, TVA, erreur, formulaire/clavier/busy/fermeture,
AssistantPanel, focus/Échap/GPS et dialogues d'import.
`ui_prepare.py` prépare un SUT vérifié hors ligne sous `.dart_tool/e08-ui-*`,
sans .env/env.g.dart, clé ni résolution de dépendances. Le manifeste SHA-256 et
les preuves livrées dans Néo identifient exactement les sources testées.
