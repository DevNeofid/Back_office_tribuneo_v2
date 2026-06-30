import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_function.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/views/accounting_entries.dart';
import 'package:back_office_tribuneo_v2/presentation/views/customers_content_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/dashboard_content_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/document_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/orders_content_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/partners_content_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/refund_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/sector_activity_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/stats_view.dart';
import 'package:back_office_tribuneo_v2/presentation/views/transfert_order_view.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/header_widget.dart';

class MySinglePage extends StatefulWidget {
  const MySinglePage({super.key});

  @override
  State<MySinglePage> createState() => MySinglePageState();

  static MySinglePageState of(BuildContext context) {
    return context.findAncestorStateOfType<MySinglePageState>()!;
  }
}

class MySinglePageState extends State<MySinglePage> {
  static const double _sideMenuWidth = 120;

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
      "icon": Icons.home,
    },
    1: {
      "name": "customer",
      "title": "Liste des clients",
      "short": "Clients",
      "content": CustomersContentView(),
      "icon": Icons.people,
    },
    2: {
      "name": "orders",
      "title": "Liste des commandes",
      "short": "Commandes",
      "content": const OrdersContentView(),
      "icon": Icons.list_alt,
    },
    3: {
      "name": "partner",
      "title": "Liste des magasins partenaires",
      "short": "Partenaires",
      "content": const PartnersContentView(),
      "icon": Icons.storefront,
    },
    4: {
      "name": "activitySectors",
      "title": "Secteurs d'activité",
      "short": "Secteurs",
      "content": const SectorActivityView(),
      "icon": Icons.construction,
    },
    5: {
      "name": "document",
      "title": "Documents",
      "short": "Documents",
      "content": const DocumentsContentView(),
      "icon": Icons.document_scanner_outlined,
    },
    6: {
      "name": "bankTransfertOrder",
      "title": "Historique d'ordres de virement bancaire",
      "short": "Virements",
      "content": const TranferOrderView(),
      "icon": Icons.reorder,
    },
    7: {
      "name": "refund",
      "title": "Liste des demandes de remboursement",
      "short": "Remboursement",
      "content": const RefoundShopView(),
      "icon": Icons.euro,
    },
    8: {
      "name": "accountingentries",
      "title": "Écritures comptables",
      "short": "Écritures",
      "content": const AccountingEntriesView(),
      "icon": Icons.edit,
    },
    9: {
      "name": "stats",
      "title": "Statistiques",
      "short": "Statistiques",
      "content": const StatsContentView(),
      "icon": Icons.bar_chart,
    },
  };

  Future<void> checkForNewRefunds() async {
    // Notification of new refunds
    var res = await TransferOrderUseCase().awaitRefund();
    if (res.isNotEmpty) {
      setState(() {
        showRefundNotification = true;
      });
    }
  }

  callBackMenu(int indexContent) {
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

  late SideMenu menu;
  buildMenu() {
    menu = SideMenu(
      menuItemsInfos: menuItems,
      selectedMenu: selectedMenu,
      callback: callBackMenu,
      showRefundNotification: showRefundNotification,
    );
  }

  @override
  void initState() {
    super.initState();
    dataRecovery();
    checkForNewRefunds();
  }

  /* Test Graph - End */
  @override
  Widget build(BuildContext context) {
    buildMenu();
    SizeConfig().init(context);

    return Scaffold(
      key: _drawerKey,
      drawer: SizedBox(
        width: _sideMenuWidth,
        child: menu,
      ),
      appBar: !Responsive.isDesktop(context)
          ? AppBar(
              elevation: 0,
              backgroundColor: kPWhite,
              leading: IconButton(
                  onPressed: () {
                    _drawerKey.currentState?.openDrawer();
                  },
                  icon: const Icon(Icons.menu, color: kBlue)),
              actions: const [
                // AppBarActionItems(),
              ],
            )
          : const PreferredSize(
              preferredSize: Size.zero,
              child: SizedBox(),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              SizedBox(
                width: _sideMenuWidth,
                child: menu,
              ),
            if (loadedData)
              Expanded(
                flex: 10,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Header(title: contentTitle),
                        SizedBox(
                          height: SizeConfig.blockSizeVertical * 4,
                        ),
                        content,
                      ],
                    ),
                  ),
                ),
              ),
            if (!loadedData)
              const Expanded(
                flex: 10,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (Responsive.isDesktop(context) && selectedMenu == 'dashboard')
              Expanded(
                flex: 3,
                child: SafeArea(
                  child: Container(
                    width: double.infinity,
                    height: SizeConfig.screenHeight,
                    decoration: const BoxDecoration(color: kLBlue),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                                minWidth: 220,
                                minHeight: 220,
                                maxWidth: 350,
                                maxHeight: 300),
                            decoration: const BoxDecoration(
                              color: kTransparent,
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(
                                minWidth: 220,
                                minHeight: 220,
                                maxWidth: 350,
                                maxHeight: 300),
                            decoration: const BoxDecoration(
                              color: kTransparent,
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(
                                minWidth: 220,
                                minHeight: 220,
                                maxWidth: 350,
                                maxHeight: 300),
                            decoration: const BoxDecoration(
                              color: kTransparent,
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(
                                minWidth: 220,
                                minHeight: 220,
                                maxWidth: 350,
                                maxHeight: 300),
                            decoration: const BoxDecoration(
                              color: kTransparent,
                            ),
                          ),
                          // AppBarActionItems(),
                          // PaymentDetailList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/*
----------------------------------
           OTHER FILE
----------------------------------
*/

class SideMenu extends StatefulWidget {
  const SideMenu(
      {super.key,
      required this.menuItemsInfos,
      required this.selectedMenu,
      required this.callback,
      required this.showRefundNotification});

  final Map<int, Map<String, dynamic>> menuItemsInfos;
  final String selectedMenu;
  final Function(int) callback;
  final bool showRefundNotification;

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  List<Widget> menuItems = [];
  int? hoveredMenuIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Drawer(
      elevation: 0,
      child: Container(
        width: double.infinity,
        height: SizeConfig.screenHeight,
        decoration: const BoxDecoration(color: kPLGrey2),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(
                    top: 20, bottom: 20, left: 20, right: 20),
                child: SvgPicture.asset(
                  'assets/svg/picto_tribuneo_squared.svg',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.menuItemsInfos.length,
                itemBuilder: (context, index) {
                  final bool isSelected = widget.selectedMenu ==
                      widget.menuItemsInfos[index]!['name'];
                  final bool isHovered = hoveredMenuIndex == index;

                  return InkWell(
                    onTap: () {
                      if (kDebugMode) {
                        print(
                            "###DEBUG### Menu clic on : ${widget.menuItemsInfos[index]!['title']}");
                      }
                      widget.callback(index);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => hoveredMenuIndex = index),
                      onExit: (_) => setState(() => hoveredMenuIndex = null),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOutCubic,
                        opacity: isHovered ? 0.8 : 1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutCubic,
                          height: 65,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kLBlue.withValues(alpha: 0.20)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        iconSize: 30,
                                        padding: const EdgeInsets.only(
                                            top: 10.0, bottom: 2.0),
                                        icon: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(
                                              widget.menuItemsInfos[index]![
                                                  'icon'],
                                              color: (isSelected || isHovered)
                                                  ? kBlue
                                                  : kLBlue,
                                            ),
                                            if (widget.showRefundNotification &&
                                                widget.menuItemsInfos[index]![
                                                        'name'] ==
                                                    'refund')
                                              Positioned(
                                                right: -4,
                                                top: -4,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        onPressed: null,
                                      ),
                                      Text(
                                        widget.menuItemsInfos[index]!['short'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: (isSelected || isHovered)
                                              ? kBlue
                                              : kLBlue,
                                        ),
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );
  }
}
