import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/core/notifiers/screen_open_requests.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/domain/models/assistant_model.dart';
import 'package:back_office_tribuneo_v2/domain/repositories/assistant_repository.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/main_usecase.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/invoice_download.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/url_opener.dart';
import 'package:back_office_tribuneo_v2/presentation/views/accounting_entries.dart';
import 'package:back_office_tribuneo_v2/presentation/views/customers_content_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/dashboard_content_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/merchant_import_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/document_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/next_transfer_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/orders_content_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/partners_content_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/sector_activity_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/stats_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/transfert_order_view.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_controller.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_deep_link.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_docked_panel.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/assistant/assistant_overlay.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';

class MySinglePage extends StatefulWidget {
  const MySinglePage({super.key});

  @override
  State<MySinglePage> createState() => MySinglePageState();

  static MySinglePageState of(BuildContext context) {
    return context.findAncestorStateOfType<MySinglePageState>()!;
  }

  static MySinglePageState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MySinglePageState>();
  }
}

class MySinglePageState extends State<MySinglePage> {
  String selectedMenu = 'dashboard';
  String contentTitle = 'Dashboard';
  late Widget content = const DashboardContentView();

  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey();

  final StorageFunction _storageFunction = StorageFunction();
  bool loadedData = false;
  bool showRefundNotification = false;

  dataRecovery() async {
    await _storageFunction.readLastViewedMenu().then((lastView) => {
          if (lastView != null &&
              (lastView.toString() != selectedMenu ||
                  lastView.toString() == 'dashboard'))
            {
              selectedMenu = lastView.toString(),
              for (int i = 0; i < menuItems.length; i++)
                {
                  if (menuItems[i]!['name'] == selectedMenu)
                    {
                      contentTitle = menuItems[i]!['title'],
                      content = menuItems[i]!['content'],
                    }
                },
              setState(() {
                loadedData = true;
              })
            }
          else
            {
              setState(() {
                loadedData = true;
              })
            }
        });
  }

  final Map<int, Map<String, dynamic>> menuItems = {
    0: {
      "name": "dashboard",
      "title": "Tableau de bord",
      "short": "Accueil",
      "content": const DashboardContentView(),
      "icon": Icons.home_rounded,
    },
    1: {
      "name": "customer",
      "title": "Liste des clients",
      "short": "Clients",
      "content": CustomersContentView(),
      "icon": Icons.people_alt_outlined,
    },
    2: {
      "name": "orders",
      "title": "Liste des commandes",
      "short": "Commandes",
      "content": const OrdersContentView(),
      "icon": Icons.receipt_long_outlined,
    },
    3: {
      "name": "partner",
      "title": "Liste des magasins partenaires",
      "short": "Partenaires",
      "content": const PartnersContentView(),
      "icon": Icons.storefront_outlined,
    },
    4: {
      "name": "merchantImport",
      "title": "Import de commerçants",
      "short": "Import",
      "content": const MerchantImportView(),
      "icon": Icons.upload_file_outlined,
      // La grille d'import gère son propre défilement : pas de défilement de
      // page, le contenu occupe la hauteur restante.
      "fullHeight": true,
    },
    5: {
      "name": "activitySectors",
      "title": "Secteurs d'activité",
      "short": "Secteurs",
      "content": const SectorActivityView(),
      "icon": Icons.sell_outlined,
    },
    6: {
      "name": "document",
      "title": "Documents",
      "short": "Documents",
      "content": const DocumentsContentView(),
      "icon": Icons.description_outlined,
    },
    7: {
      "name": "bankTransfertOrder",
      "title": "Historique d'ordres de virement bancaire",
      "short": "Virements",
      "content": const TranferOrderView(),
      "icon": Icons.swap_horiz_rounded,
    },
    // Nom « refund » conservé : c'est lui qui est mémorisé comme dernier menu ouvert.
    8: {
      "name": "refund",
      "title": "Prochain virement",
      "short": "Prochain virement",
      "content": const NextTransferView(),
      "icon": Icons.euro_rounded,
    },
    9: {
      "name": "accountingentries",
      "title": "Écritures comptables",
      "short": "Écritures",
      "content": const AccountingEntriesView(),
      "icon": Icons.table_chart_outlined,
    },
    10: {
      "name": "stats",
      "title": "Statistiques",
      "short": "Statistiques",
      "content": const StatsContentView(),
      "icon": Icons.bar_chart_rounded,
    },
  };

  /// Ordre et groupes du menu latéral (noms de [menuItems]).
  static const List<(String?, List<String>)> _menuGroups = [
    (null, ['dashboard']),
    ('RÉSEAU', ['customer', 'partner', 'orders', 'merchantImport', 'activitySectors']),
    ('FINANCE', ['refund', 'bankTransfertOrder', 'accountingentries', 'document']),
    ('ANALYSE', ['stats']),
  ];

  Future<void> checkForNewRefunds() async {
    // Pastille : au moins une demande prête à être payée au prochain virement.
    // Ce poll tourne à chaque changement de menu et peut légitimement échouer
    // (timeout réseau, réseau mal configuré) : il ne doit jamais remonter d'erreur
    // non capturée ni bloquer la navigation.
    try {
      final bool hasRefundsToPay =
          await TransferOrderUseCase().hasRefundsToPay();
      if (hasRefundsToPay && mounted) {
        setState(() {
          showRefundNotification = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('###DEBUG### checkForNewRefunds ignoré : $e');
      }
    }
  }

  /// Écran affiché avant de quitter le menu courant : `false` pour rester
  /// (ex. corrections de l'import encore en cours d'enregistrement).
  Future<bool> Function()? _leaveGuard;

  /// Branché par l'écran affiché ; [guard] `null` le retire.
  void setLeaveGuard(Future<bool> Function()? guard) => _leaveGuard = guard;

  /// Retire [guard] s'il est encore celui en place.
  void clearLeaveGuard(Future<bool> Function() guard) {
    if (_leaveGuard == guard) _leaveGuard = null;
  }

  /// Affiche le menu nommé [name] (`menuItems[*]['name']`).
  void openMenu(String name) {
    final int? index = menuItems.entries
        .where((entry) => entry.value['name'] == name)
        .firstOrNull
        ?.key;
    if (index != null) callBackMenu(index);
  }

  Future<void> callBackMenu(int indexContent) async {
    final Future<bool> Function()? guard = _leaveGuard;
    if (guard != null && menuItems[indexContent]!['name'] != selectedMenu) {
      if (!await guard() || !mounted) return;
      _leaveGuard = null;
    }
    if (kDebugMode) {
      print("###DEBUG###");
      print(
          "###DEBUG### CALL BACK MENU clickedMenu = ${menuItems[indexContent]!['name']}");
      print("###DEBUG###");
    }
    _storageFunction
        .saveLastViewedMenu(menuItems[indexContent]!['name'].toString());
    setState(() {
      selectedMenu = menuItems[indexContent]!['name'];
      content = menuItems[indexContent]!['content'];
      contentTitle = menuItems[indexContent]!['title'];
      // Notification of new refunds
      if (selectedMenu == 'refund') {
        showRefundNotification = false;
      } else {
        checkForNewRefunds();
      }
    });
  }

  Widget _buildMenu() {
    Map<String, dynamic> item(String name) =>
        menuItems.values.firstWhere((entry) => entry['name'] == name);
    return ArcSidebar(
      selected: selectedMenu,
      onSelect: openMenu,
      userName: globalNetworkName,
      onSignOut: _signOut,
      groups: [
        for (final (title, names) in _menuGroups)
          ArcNavGroup(title, [
            for (final name in names)
              ArcNavItem(
                name: name,
                label: item(name)['short'],
                icon: item(name)['icon'],
                badge: name == 'refund' && showRefundNotification ? '1' : null,
              ),
          ]),
      ],
    );
  }

  Future<void> _signOut() async {
    await MainUseCase().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// Assistant : son état vit avec la page, il survit donc au changement
  /// d'écran et disparaît à la déconnexion (conversation effacée).
  late final AssistantController _assistant = AssistantController()
    ..onNavigate = _openAssistantLink
    ..onDownloadDocument = _downloadAssistantDocument
    ..onOpenUrl = openExternalUrl;
  final ScreenOpenRequests _openRequests = ScreenOpenRequests();

  /// Conversation Néo contextuelle (comparaison de l'import de commerçants)
  /// affichée dans le bouton flottant.
  final AssistantDockedPanel _dockedAssistant = AssistantDockedPanel();

  /// Deep-link de l'assistant : affiche le menu cible et lui transmet la
  /// demande d'ouverture (élément, onglet) s'il y en a une.
  void _openAssistantLink(AssistantLinkBlock link) {
    final AssistantDeepLink? target = AssistantDeepLink.fromLink(link);
    if (target == null) return;
    final int? index = menuItems.entries
        .where((entry) => entry.value['name'] == target.menu)
        .firstOrNull
        ?.key;
    if (index == null) return;
    if (target.request != null) _openRequests.request(target.request!);
    callBackMenu(index);
  }

  void _downloadAssistantDocument(AssistantDocumentBlock document) {
    downloadOrderInvoice(context, document.idOrder,
        fallbackName: 'Facture_${document.idOrder}');
  }

  @override
  void initState() {
    super.initState();
    dataRecovery();
    checkForNewRefunds();
    _assistant.load();
  }

  @override
  void dispose() {
    _assistant.dispose();
    _openRequests.dispose();
    _dockedAssistant.dispose();
    super.dispose();
  }

  /* Test Graph - End */
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AssistantController>.value(value: _assistant),
        ChangeNotifierProvider<ScreenOpenRequests>.value(value: _openRequests),
      ],
      child: AssistantRepository.visible
          ? AssistantDockedScope(
              docked: _dockedAssistant, child: _buildScaffold(context))
          : _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final bool desktop = Responsive.isDesktop(context);
    return Scaffold(
      key: _drawerKey,
      drawer: desktop ? null : Drawer(width: kSidebarWidth, child: _buildMenu()),
      appBar: desktop
          ? null
          : AppBar(
              backgroundColor: kNavy900,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const ArcWordmark(height: 20),
              leading: IconButton(
                  tooltip: 'Menu',
                  onPressed: () => _drawerKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu_rounded, color: Colors.white)),
            ),
      body: Stack(
        children: [
          _buildContent(context, desktop),
          if (AssistantRepository.visible)
            Positioned.fill(child: AssistantOverlay(docked: _dockedAssistant)),
        ],
      ),
    );
  }

  /// Le menu affiché gère son propre défilement (grille d'import).
  bool get _isFullHeight => menuItems.values.any(
      (item) => item['name'] == selectedMenu && item['fullHeight'] == true);

  /// Marges du contenu ; chaque écran affiche son propre [ArcPageHeader].
  static const EdgeInsets _contentPadding = EdgeInsets.fromLTRB(40, 36, 40, 48);

  Widget _buildContent(BuildContext context, bool desktop) {
    final Widget body;
    if (!loadedData) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_isFullHeight) {
      body = content;
    } else {
      body = SingleChildScrollView(
        padding: _contentPadding,
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
            child: content,
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (desktop) _buildMenu(),
        Expanded(child: SafeArea(child: body)),
      ],
    );
  }
}
