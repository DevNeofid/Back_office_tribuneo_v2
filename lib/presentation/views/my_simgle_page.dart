import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tribuneo_backoffice/config/responsive.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/domain/usecases/transfer_order_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/views/accounting_entries.dart';
import 'package:tribuneo_backoffice/presentation/views/customers_content_view.dart';
import 'package:tribuneo_backoffice/presentation/views/dashboard_content_view.dart';
import 'package:tribuneo_backoffice/presentation/views/document_view.dart';
import 'package:tribuneo_backoffice/presentation/views/orders_content_view.dart';
import 'package:tribuneo_backoffice/presentation/views/partners_content_view.dart';
import 'package:tribuneo_backoffice/presentation/views/refund_view.dart';
import 'package:tribuneo_backoffice/presentation/views/sector_activity_view.dart';
import 'package:tribuneo_backoffice/presentation/views/stats_view.dart';
import 'package:tribuneo_backoffice/presentation/views/transfert_order_view.dart';
import 'package:tribuneo_backoffice/presentation/widgets/header_widget.dart';

class MySimplePage extends StatefulWidget {
  const MySimplePage({super.key});

  @override
  State<MySimplePage> createState() => MySimplePageState();

  static MySimplePageState of(BuildContext context) {
    return context.findAncestorStateOfType<MySimplePageState>()!;
  }
}

class MySimplePageState extends State<MySimplePage> {
  String selectedMenu = 'dashboard';
  String contentTitle = 'Dashboard';
  late Widget content = const DashboardContentView();

  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey();

  LocalDataHelper localDataHelper = LocalDataHelper();
  bool loadedData = false;
  bool showRefundNotification = false;

  dataRecovery() async {
    await localDataHelper.getByKey('last_viewed', 1).then((lastView) => {
          if (lastView != null &&
              (lastView.toString() != selectedMenu ||
                  lastView.toString() == 'dashboard'))
            {
              selectedMenu = lastView.toString(),
              // for each search the same name of selectedMenu in the list of menu
              // and get the title and the content
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
              localDataHelper.addKey('last_viewed', 'dashboard', 1),
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
    // 5: {
    //   "name": "Coupons",
    //   "title": "Coupons",
    //   "short": "Coupons",
    //   "content": const VoucherView(),
    //   "icon": Icons.qr_code,
    // },
    // 5: {
    //   "name": "Campaigns",
    //   "title": "Campagnes",
    //   "short": "Campagnes",
    //   "content": const DocumentsContentView(),
    //   "icon": Icons.campaign,
    // },
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
    // 10: {
    //   "name": "notification",
    //   "title": "Campagne de notification",
    //   "short": "Notifications",
    //   "content": const ComingSoonView(),
    //   "icon": Icons.notification_add,
    // },
    // 11: {
    //   "name": "settings",
    //   "title": "Paramètres",
    //   "short": "Paramètres",
    //   "content": const ComingSoonView(),
    //   "icon": Icons.settings,
    // }
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
    localDataHelper.addKey('last_viewed', menuItems[indexContent]!['name'], 1);
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
    /* Test Graph - Start */

    // ignore: unused_local_variable
    const dataByYears = [
      {"type": "Total injecté", "year": 2019, "value": 236500},
      {"type": "Total consommé", "year": 2019, "value": 175000},
      {"type": "Total injecté", "year": 2020, "value": 425000},
      {"type": "Total consommé", "year": 2020, "value": 360890},
      {"type": "Total injecté", "year": 2021, "value": 460000},
      {"type": "Total consommé", "year": 2021, "value": 395750},
      {"type": "Total injecté", "year": 2022, "value": 510000},
      {"type": "Total consommé", "year": 2022, "value": 425000},
    ];

    // if (kDebugMode) {
    //   print("###DEBUG### MySimplePage->build : selectedMenu = $selectedMenu");
    // }
    buildMenu();
    SizeConfig().init(context);

    return Scaffold(
      key: _drawerKey,
      // drawer: drawer,
      drawer: SizedBox(
        width: 100,
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
              Expanded(
                flex: 1,
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
                          // Container(
                          //   constraints: const BoxConstraints(
                          //       minWidth: 220,
                          //       minHeight: 220,
                          //       maxWidth: 400,
                          //       maxHeight: 400),
                          //   decoration: const BoxDecoration(
                          //     color: kTransparent,
                          //     // borderRadius: BorderRadius.all(
                          //     //   Radius.circular(20),
                          //     // ),
                          //   ),
                          //   child: Chart(
                          //     data: data,
                          //     variables: {
                          //       'category': Variable(
                          //         accessor: (Map map) =>
                          //             map['category'] as String,
                          //       ),
                          //       'sales': Variable(
                          //         accessor: (Map map) => map['sales'] as num,
                          //       ),
                          //     },
                          //     elements: [IntervalElement()],
                          //     axes: [
                          //       Defaults.horizontalAxis,
                          //       Defaults.verticalAxis,
                          //     ],
                          //   ),
                          // ),
                          Container(
                            constraints: const BoxConstraints(
                                minWidth: 220,
                                minHeight: 220,
                                maxWidth: 350,
                                maxHeight: 300),
                            decoration: const BoxDecoration(
                              color: kTransparent,
                              // borderRadius: BorderRadius.all(
                              //   Radius.circular(20),
                              // ),
                            ),
                            // child: Chart(
                            //   padding: (_) =>
                            //       const EdgeInsets.fromLTRB(40, 5, 10, 40),
                            //   data: dataByYears,
                            //   variables: {
                            //     'year': Variable(
                            //       accessor: (Map map) => map['year'].toString(),
                            //     ),
                            //     'type': Variable(
                            //       accessor: (Map map) => map['type'] as String,
                            //     ),
                            //     'value': Variable(
                            //       accessor: (Map map) => map['value'] as num,
                            //     ),
                            //   },
                            //   elements: [
                            //     IntervalElement(
                            //       position: Varset('year') *
                            //           Varset('value') /
                            //           Varset('type'),
                            //       color: ColorAttr(
                            //           variable: 'type', values: graphColors),
                            //       size: SizeAttr(value: 10),
                            //       modifiers: [DodgeModifier(ratio: 0.16)],
                            //     )
                            //   ],
                            //   axes: [
                            //     Defaults.horizontalAxis..tickLine = TickLine(),
                            //     Defaults.verticalAxis,
                            //   ],
                            //   selections: {
                            //     'tap': PointSelection(
                            //       variable: 'value',
                            //     )
                            //   },
                            //   tooltip: TooltipGuide(multiTuples: true),
                            //   crosshair: CrosshairGuide(),
                            //   annotations: [
                            //     MarkAnnotation(
                            //       relativePath: Path()
                            //         ..addRect(Rect.fromCircle(
                            //             center: const Offset(0, 0), radius: 5)),
                            //       style: Paint()..color = kOrange,
                            //       anchor: (size) => const Offset(50, 290),
                            //     ),
                            //     TagAnnotation(
                            //       label: Label(
                            //         'Total injecté',
                            //         LabelStyle(
                            //             style: Defaults.textStyle,
                            //             align: Alignment.centerRight),
                            //       ),
                            //       anchor: (size) => const Offset(60, 290),
                            //     ),
                            //     MarkAnnotation(
                            //       relativePath: Path()
                            //         ..addRect(Rect.fromCircle(
                            //             center: const Offset(0, 0), radius: 5)),
                            //       style: Paint()..color = kBlue,
                            //       anchor: (size) => const Offset(200, 290),
                            //     ),
                            //     TagAnnotation(
                            //       label: Label(
                            //         'Total consommé',
                            //         LabelStyle(
                            //             style: Defaults.textStyle,
                            //             align: Alignment.centerRight),
                            //       ),
                            //       anchor: (size) => const Offset(210, 290),
                            //     ),
                            //   ],
                            // ),
                          ),
                          Container(
                            constraints: const BoxConstraints(
                                minWidth: 220,
                                minHeight: 220,
                                maxWidth: 350,
                                maxHeight: 300),
                            decoration: const BoxDecoration(
                              color: kTransparent,
                              // borderRadius: BorderRadius.all(
                              //   Radius.circular(20),
                              // ),
                            ),
                            // child: Chart(
                            //   padding: (_) =>
                            //       const EdgeInsets.fromLTRB(40, 5, 10, 40),
                            //   data: dataByYears,
                            //   variables: {
                            //     'year': Variable(
                            //       accessor: (Map map) => map['year'].toString(),
                            //     ),
                            //     'type': Variable(
                            //       accessor: (Map map) => map['type'] as String,
                            //     ),
                            //     'value': Variable(
                            //       accessor: (Map map) => map['value'] as num,
                            //     ),
                            //   },
                            //   elements: [
                            //     IntervalElement(
                            //       position: Varset('year') *
                            //           Varset('value') /
                            //           Varset('type'),
                            //       color: ColorAttr(
                            //           variable: 'type', values: graphColors),
                            //       size: SizeAttr(value: 10),
                            //       modifiers: [DodgeModifier(ratio: 0.16)],
                            //     )
                            //   ],
                            //   axes: [
                            //     Defaults.horizontalAxis..tickLine = TickLine(),
                            //     Defaults.verticalAxis,
                            //   ],
                            //   selections: {
                            //     'tap': PointSelection(
                            //       variable: 'value',
                            //     )
                            //   },
                            //   tooltip: TooltipGuide(multiTuples: true),
                            //   crosshair: CrosshairGuide(),
                            //   annotations: [
                            //     MarkAnnotation(
                            //       relativePath: Path()
                            //         ..addRect(Rect.fromCircle(
                            //             center: const Offset(0, 0), radius: 5)),
                            //       style: Paint()..color = kOrange,
                            //       anchor: (size) => const Offset(50, 290),
                            //     ),
                            //     TagAnnotation(
                            //       label: Label(
                            //         'Total injecté',
                            //         LabelStyle(
                            //             style: Defaults.textStyle,
                            //             align: Alignment.centerRight),
                            //       ),
                            //       anchor: (size) => const Offset(60, 290),
                            //     ),
                            //     MarkAnnotation(
                            //       relativePath: Path()
                            //         ..addRect(Rect.fromCircle(
                            //             center: const Offset(0, 0), radius: 5)),
                            //       style: Paint()..color = kBlue,
                            //       anchor: (size) => const Offset(200, 290),
                            //     ),
                            //     TagAnnotation(
                            //       label: Label(
                            //         'Total consommé',
                            //         LabelStyle(
                            //             style: Defaults.textStyle,
                            //             align: Alignment.centerRight),
                            //       ),
                            //       anchor: (size) => const Offset(210, 290),
                            //     ),
                            //   ],
                            // ),
                          ),
                          Container(
                            constraints: const BoxConstraints(
                                minWidth: 220,
                                minHeight: 220,
                                maxWidth: 350,
                                maxHeight: 300),
                            decoration: const BoxDecoration(
                              color: kTransparent,
                              // borderRadius: BorderRadius.all(
                              //   Radius.circular(20),
                              // ),
                            ),
                            // child: Chart(
                            //   padding: (_) =>
                            //       const EdgeInsets.fromLTRB(40, 5, 10, 40),
                            //   data: dataByYears,
                            //   variables: {
                            //     'year': Variable(
                            //       accessor: (Map map) => map['year'].toString(),
                            //     ),
                            //     'type': Variable(
                            //       accessor: (Map map) => map['type'] as String,
                            //     ),
                            //     'value': Variable(
                            //       accessor: (Map map) => map['value'] as num,
                            //     ),
                            //   },
                            //   elements: [
                            //     IntervalElement(
                            //       position: Varset('year') *
                            //           Varset('value') /
                            //           Varset('type'),
                            //       color: ColorAttr(
                            //           variable: 'type', values: graphColors),
                            //       size: SizeAttr(value: 10),
                            //       modifiers: [DodgeModifier(ratio: 0.16)],
                            //     )
                            //   ],
                            //   axes: [
                            //     Defaults.horizontalAxis..tickLine = TickLine(),
                            //     Defaults.verticalAxis,
                            //   ],
                            //   selections: {
                            //     'tap': PointSelection(
                            //       variable: 'value',
                            //     )
                            //   },
                            //   tooltip: TooltipGuide(multiTuples: true),
                            //   crosshair: CrosshairGuide(),
                            //   annotations: [
                            //     MarkAnnotation(
                            //       relativePath: Path()
                            //         ..addRect(Rect.fromCircle(
                            //             center: const Offset(0, 0), radius: 5)),
                            //       style: Paint()..color = kOrange,
                            //       anchor: (size) => const Offset(50, 290),
                            //     ),
                            //     TagAnnotation(
                            //       label: Label(
                            //         'Total injecté',
                            //         LabelStyle(
                            //             style: Defaults.textStyle,
                            //             align: Alignment.centerRight),
                            //       ),
                            //       anchor: (size) => const Offset(60, 290),
                            //     ),
                            //     MarkAnnotation(
                            //       relativePath: Path()
                            //         ..addRect(Rect.fromCircle(
                            //             center: const Offset(0, 0), radius: 5)),
                            //       style: Paint()..color = kBlue,
                            //       anchor: (size) => const Offset(200, 290),
                            //     ),
                            //     TagAnnotation(
                            //       label: Label(
                            //         'Total consommé',
                            //         LabelStyle(
                            //             style: Defaults.textStyle,
                            //             align: Alignment.centerRight),
                            //       ),
                            //       anchor: (size) => const Offset(210, 290),
                            //     ),
                            //   ],
                            // ),
                          ),
                          Container(
                            constraints: const BoxConstraints(
                                minWidth: 220,
                                minHeight: 220,
                                maxWidth: 350,
                                maxHeight: 300),
                            decoration: const BoxDecoration(
                              color: kTransparent,
                              // borderRadius: BorderRadius.all(
                              //   Radius.circular(20),
                              // ),
                            ),
                            // child: Chart(
                            //   padding: (_) =>
                            //       const EdgeInsets.fromLTRB(40, 5, 10, 40),
                            //   data: dataByYears,
                            //   variables: {
                            //     'year': Variable(
                            //       accessor: (Map map) => map['year'].toString(),
                            //     ),
                            //     'type': Variable(
                            //       accessor: (Map map) => map['type'] as String,
                            //     ),
                            //     'value': Variable(
                            //       accessor: (Map map) => map['value'] as num,
                            //     ),
                            //   },
                            //   elements: [
                            //     IntervalElement(
                            //       position: Varset('year') *
                            //           Varset('value') /
                            //           Varset('type'),
                            //       color: ColorAttr(
                            //           variable: 'type', values: graphColors),
                            //       size: SizeAttr(value: 10),
                            //       modifiers: [DodgeModifier(ratio: 0.16)],
                            //     )
                            //   ],
                            //   axes: [
                            //     Defaults.horizontalAxis..tickLine = TickLine(),
                            //     Defaults.verticalAxis,
                            //   ],
                            //   selections: {
                            //     'tap': PointSelection(
                            //       variable: 'value',
                            //     )
                            //   },
                            //   tooltip: TooltipGuide(multiTuples: true),
                            //   crosshair: CrosshairGuide(),
                            //   annotations: [
                            //     MarkAnnotation(
                            //       relativePath: Path()
                            //         ..addRect(Rect.fromCircle(
                            //             center: const Offset(0, 0), radius: 5)),
                            //       style: Paint()..color = kOrange,
                            //       anchor: (size) => const Offset(50, 290),
                            //     ),
                            //     TagAnnotation(
                            //       label: Label(
                            //         'Total injecté',
                            //         LabelStyle(
                            //             style: Defaults.textStyle,
                            //             align: Alignment.centerRight),
                            //       ),
                            //       anchor: (size) => const Offset(60, 290),
                            //     ),
                            //     MarkAnnotation(
                            //       relativePath: Path()
                            //         ..addRect(Rect.fromCircle(
                            //             center: const Offset(0, 0), radius: 5)),
                            //       style: Paint()..color = kBlue,
                            //       anchor: (size) => const Offset(200, 290),
                            //     ),
                            //     TagAnnotation(
                            //       label: Label(
                            //         'Total consommé',
                            //         LabelStyle(
                            //             style: Defaults.textStyle,
                            //             align: Alignment.centerRight),
                            //       ),
                            //       anchor: (size) => const Offset(210, 290),
                            //     ),
                            //   ],
                            // ),
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
  // bool showRefundNotification = false;

  @override
  void initState() {
    super.initState();
    // showRefundNotification = widget.showRefundNotification;
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
                      child: SizedBox(
                        height: 65,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      iconSize: 30,
                                      padding: const EdgeInsets.only(
                                          top: 10.0, bottom: 2.0),
                                      icon: Stack(
                                        children: [
                                          Icon(
                                            widget
                                                .menuItemsInfos[index]!['icon'],
                                            color: widget.selectedMenu ==
                                                    widget.menuItemsInfos[
                                                        index]!['name']
                                                ? kBlue
                                                : kLBlue,
                                          ),
                                          // Conditionnellement afficher un cercle rouge si les notifications doivent être montrées
                                          if (widget.showRefundNotification &&
                                              widget.menuItemsInfos[index]![
                                                      'name'] ==
                                                  'refund')
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(1),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 12,
                                                  minHeight: 12,
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
                                        color: (widget.selectedMenu ==
                                                widget.menuItemsInfos[index]![
                                                    'name'])
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
