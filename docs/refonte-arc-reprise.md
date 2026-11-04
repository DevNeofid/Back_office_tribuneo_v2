# Refonte « Arc » du back-office : où on en est

Branche `feat/design-arc`, créée depuis `dev`. Rien n'est commité : l'utilisateur commite lui-même. La branche ne doit pas être fusionnée dans `dev`, elle sert aux tests en préprod.

Maquettes et design system : https://claude.ai/artifact/U7uWzLQTrhxJDs4QSCJwvn (lien privé). Les sources HTML des maquettes (`*.dc.html`) sont copiées dans `docs/maquettes-arc/`. Ce sont des fichiers HTML avec styles en ligne : `Main` et `Composants` décrivent le design system, les autres un écran chacun.

## Terminé et vérifié (analyse propre, 263 tests verts avant le travail sur les écrans)

- `lib/presentation/utils/common.dart` :
  - `kOrange` passe à `#F8AA36` ;
  - nouvelles couleurs `kNavy50…950`, `kOrange50…700`, neutres (`kInk`, `kText2`, `kText3`, `kBorder*`, `kCanvas`, `kSurface*`) et couleurs de statut (`kSuccess/Warning/Danger/Info/Neutral` + `Text`/`Bg`) ;
  - rayons, hauteurs, largeur du menu (248) et largeur max du contenu (1280).
- `lib/presentation/utils/arc_theme.dart` : `ArcTheme.light()`, `ArcText` (Bricolage Grotesque pour les titres et chiffres, Poppins pour l'interface, Martian Mono pour les données) et `ArcTone`.
- `lib/main.dart` : l'app utilise `ArcTheme.light()`.
- `lib/presentation/widgets/arc/` : composants partagés, exportés par `arc.dart` :
  - `ArcPageHeader`, `ArcCard`, `ArcTableCard`, `ArcSectionTitle`, `ArcCount`, `ArcPagination`, `ArcKpiTile`, `ArcAvatar`, `ArcEmptyState`, `ArcDefinitionList` ;
  - `ArcSegmented`, `ArcSearchField`, `ArcIconAction`, `ArcFilterChip` ;
  - `ArcDialog`, `showArcConfirm`, `arcDangerButtonStyle` ;
  - `ArcPill`, `ArcWordmark`, `ArcPicto`, `ArcSidebar`.
- `lib/presentation/views/my_single_page.dart` :
  - menu latéral navy (`ArcSidebar`) avec les groupes Réseau, Finance et Analyse, la pastille de Prochain virement et la déconnexion dans la carte utilisateur ;
  - plus d'en-tête global : chaque écran affiche son propre `ArcPageHeader` ;
  - le panneau lavande du tableau de bord est retiré.
- `header_widget.dart` est supprimé. `NeoButton` (texte navy, sans relief, 44 px) et `NeoInput` (bordures du thème) sont alignés sur le design system.

## Reprise du 4 novembre 2026

La compilation a été rétablie et les écrans existants ont été relus face aux sources HTML. Aucun commit, aucun push et aucun changement de branche : `feat/design-arc` reste active.

### Commandes

- `orders_content_view.dart` : import Arc et formatage de la date de paiement rétablis ; `ArcPageHeader`, recherche dans `ArcTableCard`, en-tête clair, lignes de 52 px, montants en Martian Mono alignés à droite, statut de paiement calculé depuis les montants existants, expiration signalée en couleur, pagination `ArcPagination` pilotant le même tableau asynchrone. Dialogues de paiements et confirmations Arc ; tous les menus de gestion et d’édition sont conservés.
- `voucher_view.dart` : présentation alignée sur Arc. Cette ancienne vue n’est pas référencée par la navigation et son corps était déjà incomplet ; aucune donnée ni route n’a été inventée. La gestion effective des bons est `widgets/orders/show_vouchers.dart`.
- `forms/orders/{order_form,update_order_form}.dart`, `orders/{order_sheet,beneficiaries_dialog,order_expiry_date,show_vouchers}.dart` : panneaux de commande, formulaires manuel/import, confirmations, bénéficiaires et bons relus ; actions et garde-fous conservés.
- Écarts assumés : les colonnes Création, Gestion et Edition restent accessibles séparément ; les nouveaux filtres de commandes de la maquette ne sont pas ajoutés à la logique existante. Les montants et statuts sont issus des commandes chargées.

### Clients et partenaires

- `customers_content_view.dart`, `partners_content_view.dart`, `check_siret_dialog.dart` et les formulaires `customers`, `partners`, `addresses`, `bank_informations` : fiches, cartes, tableaux, recherche, formulaires et confirmations Arc relus. `forms/customers/arc_form_panel.dart` fournit les sections, grilles et actions des panneaux.
- Les trois anciens filtres ronds des clients sont bien les onglets Général / Adresse / Banque de la fiche. Les actions d’édition, nouvelle commande, duplication et désactivation restent disponibles.
- La dernière facture, les liens vers des factures filtrées et les autres données/actions absentes de la fiche chargée ne sont pas simulés. La création partenaire conserve ses dialogues successifs et leurs validations existantes.

### Finance

- `next_transfer_view.dart`, `transfert_order_view.dart`, `accounting_entries.dart`, `document_view.dart`, `hold_refund_dialog.dart`, `accounting_entries_config_dialog.dart` : indicateurs, cartes de demandes, choix du compte payeur, listes paginées, montants, fichiers et dialogues relus face aux maquettes.
- Les périodes sont affichées seulement lorsqu’elles sont lisibles dans les données existantes. La période future des écritures et le montant du prochain virement ne sont pas fabriqués sur les écrans qui ne les chargent pas.
- Documents conserve ses deux listes et ses téléchargements individuels : la sélection et le téléchargement groupé ainsi qu’une nouvelle recherche ne sont pas ajoutés.
- `ArcDialog` accepte un contenu défilant dans la hauteur disponible, en conservant les actions visibles.

### Accueil, statistiques, secteurs et connexion

- `dashboard_content_view.dart` : revue des cartes À traiter, dernières commandes, raccourcis et derniers virements ; utilise les use cases déjà présents. Les blocs sans résultat disponible sont omis ; les erreurs réelles ont un état de reprise. Navigation par `MySinglePage.maybeOf(context)?.openMenu(...)`.
- `stats_view.dart`, `sector_activity_view.dart`, `login_view.dart`, `export_to_csv_button.dart` : catalogue de rapports, export, listes de secteurs, confirmations et connexion relus. Sur petit écran, le motif de la connexion est atténué pour préserver le contraste du titre blanc.
- Aucun indicateur, graphique ou résultat métier fictif ajouté pour remplir les maquettes.

### Import et Néo

- `merchant_import_view.dart` : en-tête Arc, modèle de fichier en carte, tableau clair des lots, pastilles de statut, source en Martian Mono et défilement horizontal lorsque nécessaire. Création par le même sélecteur CSV/XLSX, mêmes callbacks Ouvrir / Abandonner / Recharger / Afficher plus de lots.
- `widgets/merchant_import/merchant_import_grid.dart` : en-tête Relecture du lot, source et date réelles, statut, bouton principal orange à texte navy, tableau `ArcTableCard` avec en-tête clair et lignes de 52 px, pastilles `ArcPill`, pagination `ArcPagination`, confirmation dangereuse framboise. Filtres et libellés testés, clés, navigation au clavier, colonnes figées, défilement synchronisé et file de sauvegarde conservés.
- `merchant_import_shortcut.dart` : action principale `FilledButton`, secondaire navy. `my_single_page.dart` laisse la vue d’import gérer ses propres marges pour éviter de les doubler.
- Les panneaux `merchant_enrichment` et `assistant` ont été relus : critères publics, choix manuel, comparaison, application explicite et confirmations sont conservés. `NeoAiButton` garde sa bordure arc-en-ciel et sa rotation au survol ; les pastilles `EnrichmentChip` restent présentes. Carte Plan IGN : halo orange, repère proposé framboise, repère choisi navy et légendes cohérentes.
- Les actions absentes de l’implémentation (dépôt par glisser-déposer, téléchargement d’un modèle) ne sont pas présentées comme disponibles. Les outils de relecture supplémentaires existants restent accessibles.

### Polices locales

- `assets/fonts/arc/` et `pubspec.yaml` : neuf variantes officielles de Bricolage Grotesque, Poppins et Martian Mono embarquées. Empreintes SHA-256 et tailles vérifiées contre les descripteurs de la version verrouillée de `google_fonts`. Les trois licences OFL sont conservées ; voir `assets/fonts/arc/README.md`.
- Les API du socle `ArcText` / `ArcTheme` restent les mêmes. Les variantes utilisées n’ont plus besoin d’être téléchargées au rendu.

### Vérification et limites

- `flutter analyze` : propre.
- `flutter test --reporter failures-only` : **263 tests verts** après la refonte et les corrections de rendu avec les polices locales.
- `flutter build web --no-pub` : compilation web réussie, y compris le contrôle Wasm automatique.
- Contrôle visuel supplémentaire avec le thème Arc réel : **23 parcours** d’import/Néo à 130 % (1366×768, 1024×768, 768×1024, 390×844), et **2 contrôles** de connexion (1366×900, 390×844, dont validation d’un identifiant vide). Captures inspectées ; données de test synthétiques. Les scripts temporaires de capture ont été supprimés après vérification.
- Un seul test conservé a changé : `test/merchant_enrichment/messages_rendered_test.dart` cherche désormais `FilledButton` au lieu de `ElevatedButton` pour le bouton « Importer ». Seul le type visuel change, aucune assertion métier n’est retirée.
- `test/zz_tmp_finance_arc_smoke_test.dart` a été supprimé comme demandé.
- La vérification manuelle dans un navigateur authentifié reste à faire : l’autorisation de contrôle de Chrome a expiré ; le navigateur intégré ne pouvait pas joindre le serveur local. Aucun identifiant utilisé et aucune opération effectuée sur un réseau réel. Les contrôles source, analyse, tests, captures Flutter et compilation web ne remplacent pas une recette sur les données du réseau.

### Règles conservées

Présentation uniquement ; pas de nouveau modèle ni de nouvel endpoint. Réutilisation des use cases et composants existants, clés et callbacks conservés. Les modifications en cours avant cette reprise restent dans l’arbre de travail ; rien n’a été réinitialisé ni commité.
