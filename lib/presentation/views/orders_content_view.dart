import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/payment_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/orders_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/date_formater.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/orders/order_form.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';

enum SampleItem { itemOne, itemTwo, itemThree, itemFour, itemFive, itemSix }

enum SampleItem2 { itemOne, itemTwo, itemThree }

class OrdersContentView extends StatefulWidget {
  const OrdersContentView({super.key});

  @override
  State<OrdersContentView> createState() => _OrdersContentViewState();
}

class _OrdersContentViewState extends State<OrdersContentView> {
  final TextEditingController _searchController = TextEditingController();
  final OrderUseCase _orderUseCase = OrderUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  late final OrderDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = OrderDataSource(
      orderUseCase: _orderUseCase,
      onShowPayments: _showPayments,
      onCreateQRCode: _createQRCode,
      onCreateCsv: _createCsv,
      onCreateDeliveryNote: _createDeliveryNote,
      onCreateInvoice: _createInvoice,
      onCreateSummary: _createSummary,
      onDelete: _deleteOrder,
    );
  }

  Future<void> _addOrder() async {
    final result = await showDialog(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return const OrderForm(idEntity: -1, entityName: '');
        });
    if (result == true) {
      _dataSource.refreshDatasource();
    }
  }

  void _createQRCode(OrderModel order) {
    snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text(
          'Génération en arrière-plan, vous pouvez continuer à naviguer.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: kGreen,
        duration: Duration(seconds: 3)));
    _processQRCodeGeneration(order);
  }

  Future<void> _processQRCodeGeneration(OrderModel order) async {
    try {
      final String name = order.entityName!.replaceAll(' ', '_');
      String? number = order.orderNumber;

      dynamic res = await _orderUseCase.createQRCode(order.id!);

      if (res != null) {
        List<dynamic> listDynamic = res;

        BuildContext? currentContext = navigatorKey.currentState?.context;
        if (currentContext != null) {
          showDialog(
              context: currentContext,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Génération terminée'),
                  content: Text(
                      'Les QR Codes pour la commande $number sont prêts. Le téléchargement commence.'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Fermer'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        }

        FileDownloader.downloadLargeFile(
            listDynamic, '${name}_$number', 'application/zip',
            fileExtension: 'zip');
      } else {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
            content: Text('Erreur lors de la génération des QRcode.'),
            backgroundColor: kRed));
      }
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération des QRcode.'),
          backgroundColor: kRed));
    }
  }

  Future<void> _createCsv(OrderModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Téléchargement du fichier CSV...');
      },
    );
    try {
      final String name = order.entityName!.replaceAll(' ', '_');
      String? number = order.orderNumber;

      dynamic res = await _orderUseCase.createCsv(order.id!);
      List<dynamic> listDynamic = res;

      FileDownloader.downloadLargeFile(
          listDynamic, '${name}_$number', 'text/csv',
          fileExtension: 'csv');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération du CSV.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  Future<void> _showPayments(OrderModel order) async {
    final result = await showDialog(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return ShowPayment(order: order);
        });

    if (result == true) {
      _dataSource.refreshDatasource();
    }
  }

  Future<void> _createInvoice(OrderModel order) async {
    String infos = '';
    try {
      infos = await _orderUseCase.getInvoiceInfos(order.id!);
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text(
            'Erreur : Pensez à vérifier que votre client a une adresse de renseignée ?'),
        backgroundColor: kRed,
      ));
      return;
    }
    String? additionalInfo = await _showAdditionalInfoDialog(infos);
    if (additionalInfo == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    showDialog(
      context: navigatorKey.currentState!.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(loadingText: 'Création de la facture...');
      },
    );

    Map<String, dynamic> invoice = {
      'id_order': order.id,
      'comment': additionalInfo,
      'justDownload': 0,
    };
    try {
      dynamic res = await _orderUseCase.createInvoice(invoice);
      final String name = order.entityName!.replaceAll(' ', '_');
      String? number = order.orderNumber;
      List<dynamic> listDynamic = res;

      FileDownloader.downloadLargeFile(
          listDynamic, 'Facture_${name}_$number', 'application/pdf',
          fileExtension: 'pdf');

      _dataSource.refreshDatasource();
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text(
            'Erreur : Pensez à vérifier que votre client a une adresse de renseignée ?'),
      ));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  Future<void> _createSummary(OrderModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Téléchargement du fichier récapitulatif...');
      },
    );
    try {
      final String name = order.entityName!.replaceAll(' ', '_');
      String? number = order.orderNumber;

      dynamic res = await _orderUseCase.createSummary(order.id!);
      List<dynamic> listDynamic = res;

      FileDownloader.downloadLargeFile(
          listDynamic, '${name}_${number}_summary', 'text/csv',
          fileExtension: 'csv');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération du récapitulatif.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  Future<String?> _showAdditionalInfoDialog(String invoiceInfos) async {
    String? additionalInfo;
    TextEditingController textEditingController =
        TextEditingController(text: invoiceInfos);

    bool? dialogResult = await showDialog<bool>(
      context: navigatorKey.currentState!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              'Voulez-vous ajouter des informations supplémentaires ?'),
          content: SizedBox(
            width: 500,
            height: 200,
            child: TextField(
              controller: textEditingController,
              decoration: const InputDecoration(hintText: 'Référence commande'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Annuler',
                style: TextStyle(
                    color: kRed, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                'Générer la facture',
                style: TextStyle(
                    color: kBlue, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () {
                additionalInfo = textEditingController.text;
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    textEditingController.dispose();

    if (dialogResult == true) {
      return additionalInfo;
    }
    return null;
  }

  Future<void> _createDeliveryNote(OrderModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Génération du bon de livraison...');
      },
    );

    try {
      dynamic res = await _orderUseCase.createDeliveryNote(order.id!);

      final String name = order.entityName!.replaceAll(' ', '_');
      String? number = order.orderNumber;

      List<dynamic> file = res;

      FileDownloader.downloadLargeFile(
          file, 'BL_${name}_$number', 'application/pdf',
          fileExtension: 'pdf');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération du PDF.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  void _deleteOrder(int id) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Supprimer une commande'),
            content: const Text(
                'Êtes-vous sûr de vouloir supprimer cette commande ?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Supprimer'),
                onPressed: () async {
                  bool deleted = await _orderUseCase.deleteOrder(id);
                  if (deleted) {
                    Navigator.of(context).pop(true);
                    snackbarKey.currentState?.showSnackBar(const SnackBar(
                        content: Text('Commande supprimée avec succès.'),
                        backgroundColor: kGreen));
                  } else {
                    Navigator.of(context).pop(true);
                    snackbarKey.currentState?.showSnackBar(const SnackBar(
                        content: Text(
                            'Erreur lors de la suppression de la commande, au moins un utilisateur a scanné son bon sur cette commande.'),
                        backgroundColor: kRed));
                  }
                },
              ),
            ],
          );
        });

    if (result == true) {
      _dataSource.refreshDatasource();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final bool isCompact = MediaQuery.of(context).size.width < 1500;
    _dataSource.isCompact = isCompact;

    return Column(
      children: [
        Text('Ajouter une commande', style: GoogleFonts.poppins(fontSize: 20)),
        const SizedBox(height: 10),
        Center(
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(kOrange),
              iconColor: WidgetStateProperty.all(kWhite),
            ),
            onPressed: () => _addOrder(),
            child: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 50),
        SizedBox(
          width: SizeConfig.screenWidth * 0.3,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: kBlue),
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              labelText: "Rechercher",
              labelStyle: TextStyle(color: kBlue),
              iconColor: kBlue,
              hintText: "Rechercher par numéro de commande, offert par, etc.",
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
            ),
            onChanged: (value) {
              _dataSource.updateSearch(value);
            },
          ),
        ),
        const SizedBox(height: 50),
        ValueListenableBuilder<int>(
          valueListenable: _dataSource.currentPageItemCount,
          builder: (context, itemCount, _) {
            final double tableHeight =
                54.0 + (itemCount.clamp(1, 50) * 53.0) + 70.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: tableHeight,
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dataTableTheme: DataTableThemeData(
                      headingRowColor: WidgetStateProperty.all(kBlue),
                      headingTextStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kWhite,
                      ),
                      dataTextStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: kBlueEnd,
                      ),
                      dividerThickness: 0.6,
                      dataRowMinHeight: 50,
                      dataRowMaxHeight: 56,
                      headingRowHeight: 54,
                    ),
                  ),
                  child: AsyncPaginatedDataTable2(
                    wrapInCard: false,
                    columnSpacing: isCompact ? 16 : 22,
                    horizontalMargin: isCompact ? 10 : 14,
                    minWidth: isCompact ? 980 : 1180,
                    rowsPerPage: 50,
                    showCheckboxColumn: false,
                    loading: const Center(
                      child: CircularProgressIndicator(color: kBlue),
                    ),
                    columns: const [
                      DataColumn2(
                        size: ColumnSize.S,
                        label: Expanded(
                            child: Center(
                                child:
                                    Text('N°', textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.L,
                        label: Expanded(
                            child: Center(
                                child: Text('Offert par',
                                    textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.L,
                        label: Expanded(
                            child: Center(
                                child: Text('Occasion',
                                    textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.S,
                        label: Expanded(
                            child: Center(
                                child:
                                    Text('Qté', textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.S,
                        label: Expanded(
                            child: Center(
                                child:
                                    Text('Payé', textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.S,
                        label: Expanded(
                            child: Center(
                                child: Text('Facturé',
                                    textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.M,
                        label: Expanded(
                            child: Center(
                                child: Text('Création',
                                    textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.M,
                        label: Expanded(
                            child: Center(
                                child: Text('Expiration',
                                    textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.S,
                        label: Expanded(
                            child: Center(
                                child: Text('Gestion',
                                    textAlign: TextAlign.center))),
                      ),
                      DataColumn2(
                        size: ColumnSize.S,
                        label: Expanded(
                            child: Center(
                                child: Text('Edition',
                                    textAlign: TextAlign.center))),
                      ),
                    ],
                    source: _dataSource,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class OrderDataSource extends AsyncDataTableSource {
  final OrderUseCase _orderUseCase;
  final void Function(OrderModel) onShowPayments;
  final void Function(OrderModel) onCreateQRCode;
  final void Function(OrderModel) onCreateCsv;
  final void Function(OrderModel) onCreateDeliveryNote;
  final void Function(OrderModel) onCreateInvoice;
  final void Function(OrderModel) onCreateSummary;
  final void Function(int) onDelete;
  List<OrderModel> _cachedOrders = [];
  bool _needsReload = true;
  String _searchQuery = '';
  bool isCompact = false;
  final ValueNotifier<int> currentPageItemCount = ValueNotifier<int>(50);

  OrderDataSource({
    required OrderUseCase orderUseCase,
    required this.onShowPayments,
    required this.onCreateQRCode,
    required this.onCreateCsv,
    required this.onCreateDeliveryNote,
    required this.onCreateInvoice,
    required this.onCreateSummary,
    required this.onDelete,
  }) : _orderUseCase = orderUseCase;

  void updateSearch(String query) {
    _searchQuery = query;
    super.refreshDatasource();
  }

  @override
  void refreshDatasource() {
    _needsReload = true;
    super.refreshDatasource();
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    if (_needsReload) {
      final result = await _orderUseCase.getOrders(limit: 10000, offset: 0);
      _cachedOrders = result.items;
      _needsReload = false;
    }

    final String query = _searchQuery.toLowerCase();
    final List<OrderModel> filtered = query.isEmpty
        ? _cachedOrders
        : _cachedOrders
            .where((o) =>
                (o.orderNumber?.toLowerCase().contains(query) ?? false) ||
                (o.giftFrom?.toLowerCase().contains(query) ?? false) ||
                (o.giftReason?.toLowerCase().contains(query) ?? false))
            .toList();

    final List<OrderModel> pageItems =
        filtered.skip(startIndex).take(limit).toList();

    final List<DataRow> rows = [];
    for (int i = 0; i < pageItems.length; i++) {
      final order = pageItems[i];
      final int rowIndex = startIndex + i;
      final isEvenRow = rowIndex % 2 == 0;
      final bool isPaid = order.paid == order.totalAmount;
      final double cellWidth = isCompact ? 120.0 : 170.0;

      rows.add(DataRow(
        color: isEvenRow
            ? WidgetStateProperty.all(kWhite)
            : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
        cells: [
          DataCell(Center(
              child: SelectableText(order.orderNumber ?? '',
                  textAlign: TextAlign.center))),
          DataCell(Center(
            child: SizedBox(
              width: cellWidth,
              child: Tooltip(
                message: order.giftFrom ?? '',
                child: Text(
                  order.giftFrom ?? '',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          )),
          DataCell(Center(
            child: SizedBox(
              width: cellWidth,
              child: Tooltip(
                message: order.orderItems != null
                    ? order.orderItems!.map((e) => e.persoMsg).join(', ')
                    : '',
                child: Text(
                  order.giftReason ?? '',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          )),
          DataCell(Center(
              child: Text(order.fundQuantity?.toString() ?? '',
                  textAlign: TextAlign.center))),
          DataCell(Center(
              child: Text(
            (order.paid ?? 0).toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: TextStyle(color: isPaid ? kGreen : kRed),
          ))),
          DataCell(Center(
              child: Text(
            (order.totalAmount ?? 0).toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: TextStyle(color: isPaid ? kGreen : kRed),
          ))),
          DataCell(Center(
              child: Text(
                  DateFormater().modifyDate(order.createdDate!.date!) ?? '',
                  textAlign: TextAlign.center))),
          DataCell(Center(
              child: Text(
                  DateFormater().modifyDate(order.fundExpiryDate!.date!) ?? '',
                  textAlign: TextAlign.center))),
          DataCell(
            Center(
              child: PopupMenuButton<SampleItem>(
                icon: const Icon(Icons.call_to_action_outlined),
                onSelected: (SampleItem item) {
                  if (item == SampleItem.itemOne) {
                    onShowPayments(order);
                  } else if (item == SampleItem.itemTwo) {
                    onCreateQRCode(order);
                  } else if (item == SampleItem.itemThree) {
                    onCreateCsv(order);
                  } else if (item == SampleItem.itemFour) {
                    onCreateDeliveryNote(order);
                  } else if (item == SampleItem.itemFive) {
                    onCreateInvoice(order);
                  } else if (item == SampleItem.itemSix) {
                    onCreateSummary(order);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<SampleItem>>[
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.itemOne,
                    child: Text('Paiements'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.itemTwo,
                    child: Text('Générer les QR Code'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.itemThree,
                    child: Text('Générer le CSV'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.itemFour,
                    child: Text('Générer le bon de livraison'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.itemFive,
                    child: Text('Générer la Facture'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.itemSix,
                    child: Text('Générer le récapitulatif'),
                  ),
                ],
              ),
            ),
          ),
          DataCell(
            Center(
              child: PopupMenuButton<SampleItem2>(
                onSelected: (SampleItem2 item) {
                  if (item == SampleItem2.itemTwo) {
                    onDelete(order.id!);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<SampleItem2>>[
                  const PopupMenuItem<SampleItem2>(
                    value: SampleItem2.itemTwo,
                    child: Text('Supprimer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentPageItemCount.value = pageItems.length;
    });

    return AsyncRowsResponse(filtered.length, rows);
  }
}

class PaymentMethod {
  final int id;
  final String name;

  PaymentMethod(this.id, this.name);
}

class ShowPayment extends StatefulWidget {
  final OrderModel order;

  const ShowPayment({Key? key, required this.order}) : super(key: key);

  @override
  ShowPaymentState createState() => ShowPaymentState();
}

class ShowPaymentState extends State<ShowPayment> {
  OrderUseCase orderUseCase = OrderUseCase();
  PaymentMethod? _selectedPaymentMethod;
  late OrderModel order;
  List<PaymentModel> _payments = [];
  bool _hasModifiedData = false;
  bool _isSubmitting = false;
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(1, "CASH"),
    PaymentMethod(2, "CHECK"),
    PaymentMethod(3, "BANK_TRANSFER"),
    PaymentMethod(4, "ONLINE_PAYMENT"),
    PaymentMethod(5, "CREDIT_AND_DEBIT_CARDS"),
    PaymentMethod(6, "ADMINISTRATIVE_MANDATE"),
  ];
  final TextEditingController paymentDateController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();

  @override
  void initState() {
    order = widget.order;
    selectedDate = DateTime.now();
    paymentDateController.text =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
    _refreshPayments();
    super.initState();
  }

  _refreshPayments() async {
    List<PaymentModel> response =
        await orderUseCase.getPayments(widget.order.id!);
    setState(() {
      _payments = response;
    });
  }

  traduction(String payment) {
    if (payment == 'CASH') return 'Espèces';
    if (payment == 'CHECK') return 'Chèque';
    if (payment == 'BANK_TRANSFER') return 'Virement';
    if (payment == 'ONLINE_PAYMENT') return 'Paiement en ligne';
    if (payment == 'CREDIT_AND_DEBIT_CARDS') return 'Carte bancaire';
    if (payment == 'ADMINISTRATIVE_MANDATE') return 'Mandat administratif';
    return '';
  }

  DateTime selectedDate = DateTime.now();
  _selectDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: kBlue),
          ),
          child: child!,
        );
      },
      fieldHintText: "Jour/Mois/Année",
      locale: const Locale("fr", "FR"),
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(3000),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (selected != null && selected != selectedDate) {
      DateTime lastPaymentDate = selected;
      if (_payments.isNotEmpty) {
        lastPaymentDate = DateTime.parse(_payments.last.paymentDate!.toString())
            .subtract(const Duration(hours: 12));
      }
      if (selected.isAfter(lastPaymentDate) ||
          selected.isAtSameMomentAs(lastPaymentDate)) {
        setState(() {
          selectedDate = selected;
          paymentDateController.text = _getDisplayableDate(selectedDate);
        });
      } else {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
            content: Text(
                "La date de paiement ne peut pas être antérieure à la date du dernier paiement.")));
      }
    }
  }

  String _getDisplayableDate(DateTime date) {
    String day = date.day > 9 ? date.day.toString() : "0${date.day.toString()}";
    String month =
        date.month > 9 ? date.month.toString() : "0${date.month.toString()}";
    return "$day/$month/${date.year}";
  }

  bool _validatePayment(double amount) {
    num sumOfPayments = _payments.fold<num>(0, (sum, p) => sum + p.amount!);
    return (sumOfPayments + amount) <= order.totalAmount!;
  }

  void _submitPayment([String? value]) {
    if (value != null) {
      double paymentAmount = double.parse(value);
      if (_validatePayment(paymentAmount) && _selectedPaymentMethod != null) {
        _sendPayment(paymentAmount);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Le montant saisi dépasse le montant total de la commande.")));
      }
    }
  }

  Future<void> _sendPayment(double amount) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: Text(
                'Vous allez envoyer un paiement de ${_paymentAmountController.text} € à la date du ${_getDisplayableDate(selectedDate)} ?'),
            actions: <Widget>[
              TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(false)),
              TextButton(
                  child: const Text('Valider'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  }),
            ],
          );
        });

    if (result == true) {
      await _addPayment(amount);
    }
  }

  Future _addPayment(double amount) async {
    setState(() => _isSubmitting = true);
    try {
      var inputFormat = DateFormat('dd/MM/yyyy');
      var inputDate = inputFormat.parse(paymentDateController.text);
      var outputFormat = DateFormat('yyyy-MM-dd');
      String dateFormated = outputFormat.format(inputDate);
      Map payment = {
        'id_entity': order.idEntity,
        'id_order': order.id,
        'payment_date': dateFormated,
        'amount': amount,
        'id_payment_method': _selectedPaymentMethod!.id
      };
      await orderUseCase.addPayment(payment);
      _hasModifiedData = true;
      await _refreshPayments();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future _deletePayment(PaymentModel payment) async {
    final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Supprimer un paiement'),
            content: Text(
                'Êtes-vous sûr de vouloir supprimer le paiement de ${payment.amount!.toStringAsFixed(2)} € du ${DateFormater().modifyDate(payment.paymentDate!.toString())} ?'),
            actions: <Widget>[
              TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(false)),
              TextButton(
                  child: const Text('Supprimer'),
                  onPressed: () => Navigator.of(context).pop(true)),
            ],
          );
        });

    if (confirmed != true) return;

    try {
      await orderUseCase.deletePayment(payment.id!);
      _hasModifiedData = true;
      await _refreshPayments();
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Paiement supprimé avec succès.'),
          backgroundColor: kGreen));
    } on ApiException catch (e) {
      snackbarKey.currentState?.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kRed));
    } catch (_) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la suppression du paiement.'),
          backgroundColor: kRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    num sumOfPayments = _payments.fold<num>(0, (sum, p) => sum + p.amount!);

    return AlertDialog(
      title: const SelectableText('Paiements'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(
                border: TableBorder(
                  horizontalInside:
                      BorderSide(width: 1, color: Colors.grey.shade300),
                  verticalInside:
                      BorderSide(width: 1, color: Colors.grey.shade300),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  const TableRow(
                    children: [
                      Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(child: Text('Date'))),
                      Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(child: Text('Méthode'))),
                      Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(child: Text('Montant'))),
                      Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(child: Text('Action'))),
                    ],
                  ),
                  ..._payments
                      .map((payment) => TableRow(
                            children: [
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                      child: Text(
                                          '${DateFormater().modifyDate(payment.paymentDate!.toString())}'))),
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                      child: Text(traduction(
                                    _paymentMethods
                                        .firstWhere(
                                          (m) =>
                                              m.id == payment.idPaymentMethod,
                                          orElse: () => PaymentMethod(0, ''),
                                        )
                                        .name,
                                  )))),
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                      child: Text(
                                          payment.amount!.toStringAsFixed(2)))),
                              Center(
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: kRed),
                                  tooltip: 'Supprimer le paiement',
                                  onPressed: () => _deletePayment(payment),
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ],
              ),
              const SizedBox(height: 20),
              if (_payments.fold<num>(0, (sum, p) => sum + p.amount!) <
                  order.totalAmount!)
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: NeoButton(
                          width: 100,
                          height: 40,
                          verticalPadding: 0,
                          horizontalPadding: 0,
                          fontSize: 14,
                          text: "Date",
                          backgroundColor: kBlue,
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: DropdownButton<PaymentMethod>(
                            underline: const SizedBox(),
                            isExpanded: true,
                            hint: const Text("Méthode"),
                            value: _selectedPaymentMethod,
                            onChanged: (PaymentMethod? newValue) => setState(
                                () => _selectedPaymentMethod = newValue),
                            items: _paymentMethods.map((PaymentMethod method) {
                              return DropdownMenuItem<PaymentMethod>(
                                  value: method,
                                  child: Text(traduction(method.name)));
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Ajouter un paiement'),
                          keyboardType: TextInputType.number,
                          controller: _paymentAmountController,
                          onFieldSubmitted: (value) => _submitPayment(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 40,
                                child: Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: kOrange),
                                  ),
                                ),
                              )
                            : NeoButton(
                                width: 100,
                                height: 40,
                                onPressed: () => _submitPayment(
                                    _paymentAmountController.text),
                                text: "Valider"),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SelectableText('Montant payé:'),
                  SelectableText('$sumOfPayments / ${order.totalAmount}')
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(_hasModifiedData),
            child: const Text('Fermer')),
      ],
    );
  }
}
