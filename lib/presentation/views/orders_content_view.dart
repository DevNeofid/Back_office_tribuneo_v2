// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'dart:developer';
import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/domain/models/order_model.dart';
import 'package:tribuneo_backoffice/domain/models/payment_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/orders_usecase.dart';
import 'package:tribuneo_backoffice/env/env.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/widgets/date_formater.dart';
import 'package:tribuneo_backoffice/presentation/widgets/forms/orders/order_form.dart';
import 'package:tribuneo_backoffice/presentation/widgets/loading.dart';
import 'package:tribuneo_backoffice/presentation/widgets/neo_button.dart';
import 'package:tribuneo_backoffice/presentation/utils/file_downloader.dart';

enum SampleItem { itemOne, itemTwo, itemThree, itemFour, itemFive, itemSix }

enum SampleItem2 { itemOne, itemTwo, itemThree }

class OrdersContentView extends StatefulWidget {
  const OrdersContentView({super.key});

  @override
  State<OrdersContentView> createState() => _OrdersContentViewState();
}

class _OrdersContentViewState extends State<OrdersContentView> {
  LocalDataHelper localDataHelper = LocalDataHelper();
  final TextEditingController _searchController = TextEditingController();
  final OrderUseCase _orderUseCase = OrderUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  List<OrderRecModel> _orders = [];
  List<OrderRecModel> _allOrders = [];
  SampleItem? selectedMenu;
  SampleItem2? selectedMenu2;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  _refreshOrders() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    _orders = [];
    await _orderUseCase.getOrders().then((value) {
      setState(() {
        _orders = value
            .map((e) => OrderRecModel(
                  id: e.id,
                  orderNumber: e.orderNumber,
                  giftFrom: e.giftFrom,
                  giftReason: e.giftReason,
                  idUrssaf: e.idUrssaf,
                  fundQuantity: e.fundQuantity,
                  totalAmount: e.totalAmount,
                  paid: e.paid,
                  idEntity: e.idEntity,
                  orderItems: e.orderItems,
                  fundExpiryDate: e.fundExpiryDate,
                  createdDate: e.createdDate,
                  updatedDate: e.updatedDate,
                ))
            .toList();
        _isLoading = false; // Stop loading
      });
      _allOrders = List.from(_orders);
    }).catchError((error) {
      setState(() {
        _isLoading = false; // End loading even if there's an error
      });
    });
  }

  Future<void> _addOrder() async {
    return await showDialog(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return const OrderForm(idEntity: -1, entityName: '');
        }).then((value) => _refreshOrders());
  }

  Future _createQRCode(OrderRecModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(loadingText: 'Génération des QR Codes...');
      },
    );
    try {
      String? name = order.giftFrom;
      name = name!.replaceAll(' ', '_');
      String? number = order.orderNumber;
      print("Appel de l'API pour créer le QR Code...");
      dynamic res = await _orderUseCase.createQRCode(order.id!);
      List<dynamic> listDynamic = res;

      FileDownloader.downloadLargeFile(
          listDynamic, '${name}_$number', 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      print("Erreur lors de la génération des QR Codes: $error");
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération des QRcode.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  Future<void> _createCsv(OrderRecModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Téléchargement du fichier CSV...');
      },
    );
    try {
      String? name = order.giftFrom;
      name = name!.replaceAll(' ', '_');
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

  Future<void> _showPayments(OrderRecModel order) async {
    return await showDialog(
        useSafeArea: true,
        context: context,
        builder: (context) {
          return ShowPayment(order: order);
        }).then((value) => _refreshOrders());
  }

  Future<void> _createInvoice(OrderRecModel order) async {
    Map infos = {};
    try {
      infos = await _orderUseCase.getInvoiceInfos(order.id!);
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text(
            'Erreur : Pensez à vérifier que votre client a une adresse de renseignée ?'),
        backgroundColor: Colors.red, // Optional: to change background color
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

    // Make an objet with the order id and the additional info
    Map<String, dynamic> invoice = {
      'id_order': order.id,
      'comment': additionalInfo
    };
    try {
      dynamic res = await _orderUseCase.createInvoice(invoice);
      String? name = order.giftFrom;
      name = name!.replaceAll(' ', '_');
      String? number = order.orderNumber;
      List<dynamic> listDynamic = res;

      FileDownloader.downloadLargeFile(
          listDynamic, 'Facture_${name}_$number', 'application/pdf',
          fileExtension: 'pdf');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération du PDF.')));
    } finally {
      _refreshOrders();
      navigatorKey.currentState?.pop();
    }
  }

  Future<void> _createSummary(OrderRecModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Téléchargement du fichier récapitulatif...');
      },
    );
    try {
      String? name = order.giftFrom;
      name = name!.replaceAll(' ', '_');
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

  Future<String?> _showAdditionalInfoDialog(Map invoiceInfos) async {
    String? additionalInfo;
    TextEditingController textEditingController =
        TextEditingController(text: invoiceInfos['comment']);

    bool? dialogResult = await showDialog<bool>(
      context: navigatorKey.currentState!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              'Voulez-vous ajouter des informations supplémentaires?'),
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

  Future<void> _createDeliveryNote(OrderRecModel order) async {
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

      String? name = order.giftFrom;
      name = name!.replaceAll(' ', '_');
      String? number = order.orderNumber;

      List<dynamic> listDynamic = res;

      FileDownloader.downloadLargeFile(
          listDynamic, 'BL_${name}_$number', 'application/pdf',
          fileExtension: 'pdf');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération du PDF.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  void _deleteOrder(int id) async {
    return await showDialog(
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
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Supprimer'),
                onPressed: () {
                  _orderUseCase.deleteOrder(id);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }).then((value) => _refreshOrders());
  }

  void _filterOrders(String query) {
    if (query.isEmpty) {
      setState(() {
        _orders = List.from(_allOrders);
      });
    } else {
      List<OrderRecModel> filteredOrders = [];
      for (var order in _allOrders) {
        if (order.orderNumber!.toLowerCase().contains(query.toLowerCase()) ||
            order.giftFrom!.toLowerCase().contains(query.toLowerCase()) ||
            order.giftReason!.toLowerCase().contains(query.toLowerCase())) {
          filteredOrders.add(order);
        }
      }

      setState(() {
        _orders = filteredOrders;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Column(
      children: [
        Text('Ajouter une commande', style: GoogleFonts.roboto(fontSize: 20)),
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
              _filterOrders(value);
            },
          ),
        ),
        const SizedBox(height: 50),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  //border: TableBorder(borderRadius: BorderRadius.circular(10)),
                  headingRowColor:
                      WidgetStateColor.resolveWith((states) => kLBlue),
                  columns: const [
                    DataColumn(
                        label: Center(
                            child: SelectableText('Numéro de commande'))),
                    DataColumn(
                        label: Center(child: SelectableText('Offert par'))),
                    DataColumn(
                        label: Center(child: SelectableText('Occasion'))),
                    DataColumn(
                        label:
                            Center(child: SelectableText('Quantité de fonds'))),
                    DataColumn(
                        label: Center(child: SelectableText('Total Payé'))),
                    DataColumn(
                        label: Center(child: SelectableText('Total Facture'))),
                    DataColumn(
                        label:
                            Center(child: SelectableText('Date de création'))),
                    DataColumn(
                        label: Center(
                            child: SelectableText('Date d\'expiration'))),
                    DataColumn(label: Center(child: Text('Gestion'))),
                    DataColumn(label: Center(child: Text('Edition'))),
                  ],
                  rows: _orders.asMap().entries.map((entry) {
                    final order = entry.value;
                    final index = entry.key;
                    final isEvenRow = index % 2 == 0;
                    return DataRow(
                      cells: [
                        DataCell(Center(
                            child: SelectableText(order.orderNumber ?? ''))),
                        DataCell(SelectableText(order.giftFrom ?? '')),
                        DataCell(Center(
                            child: Env.kNetworkName != 'VDPC'
                                ? SelectableText(order.giftReason ?? '')
                                : SelectableText(
                                    order.orderItems?[0].persoMsg ?? ''))),
                        DataCell(Center(
                            child: SelectableText(
                                order.fundQuantity?.toString() ?? ''))),
                        DataCell(Center(
                            child: SelectableText(order.paid.toString(),
                                style: TextStyle(
                                    color: order.paid == order.totalAmount
                                        ? kGreen
                                        : kRed)))),
                        DataCell(Center(
                            child: SelectableText(order.totalAmount.toString(),
                                style: TextStyle(
                                    color: order.paid == order.totalAmount
                                        ? kGreen
                                        : kRed)))),
                        DataCell(Center(
                            child: Text(DateFormater()
                                    .modifyDate(order.createdDate!.date!) ??
                                ''))),
                        DataCell(Center(
                            child: Text(DateFormater()
                                    .modifyDate(order.fundExpiryDate!.date!) ??
                                ''))),
                        DataCell(
                          Center(
                            child: PopupMenuButton<SampleItem>(
                              icon: const Icon(Icons.call_to_action_outlined),
                              initialValue: selectedMenu,
                              // Callback that sets the selected popup menu item.
                              onSelected: (SampleItem item) {
                                if (item == SampleItem.itemOne) {
                                  _showPayments(order);
                                } else if (item == SampleItem.itemTwo) {
                                  _createQRCode(order);
                                } else if (item == SampleItem.itemThree) {
                                  _createCsv(order);
                                } else if (item == SampleItem.itemFour) {
                                  _createDeliveryNote(order);
                                } else if (item == SampleItem.itemFive) {
                                  _createInvoice(order);
                                } else if (item == SampleItem.itemSix) {
                                  _createSummary(order);
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
                              initialValue: selectedMenu2,
                              // Callback that sets the selected popup menu item.
                              onSelected: (SampleItem2 item) {
                                if (item == SampleItem2.itemTwo) {
                                  _deleteOrder(order.id!);
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
                      color: isEvenRow
                          ? WidgetStateProperty.all(kWhite)
                          : WidgetStateProperty.all(kPLGreyTable),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}

class PaymentMethod {
  final int id;
  final String name;

  PaymentMethod(this.id, this.name);
}

class ShowPayment extends StatefulWidget {
  final OrderRecModel order;

  const ShowPayment({Key? key, required this.order}) : super(key: key);

  @override
  ShowPaymentState createState() => ShowPaymentState();
}

class ShowPaymentState extends State<ShowPayment> {
  OrderUseCase orderUseCase = OrderUseCase();
  PaymentMethod? _selectedPaymentMethod;
  late OrderRecModel order;
  List<PaymentModel> _payments = [];
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(1, "CASH"),
    PaymentMethod(2, "CHECK"),
    PaymentMethod(3, "BANK_TRANSFER"),
    PaymentMethod(4, "ONLINE_PAYMENT"),
    PaymentMethod(5, "CREDIT_AND_DEBIT_CARDS"),
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
    inspect(response);
    setState(() {
      _payments = response;
    });
  }

  traduction(String payment) {
    if (payment == 'CASH') {
      return 'Espèces';
    } else if (payment == 'CHECK') {
      return 'Chèque';
    } else if (payment == 'BANK_TRANSFER') {
      return 'Virement';
    } else if (payment == 'ONLINE_PAYMENT') {
      return 'Paiement en ligne';
    } else if (payment == 'CREDIT_AND_DEBIT_CARDS') {
      return 'Carte bancaire';
    } else {
      return '';
    }
  }

  String date = "";
  DateTime selectedDate = DateTime.now();
  _selectDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBlue,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
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
        lastPaymentDate = DateTime.parse(_payments.last.paymentDate!.date!)
            .subtract(const Duration(hours: 12));
      }
      if (selected.isAfter(lastPaymentDate) ||
          selected.isAtSameMomentAs(lastPaymentDate)) {
        setState(() {
          selectedDate = selected;
          paymentDateController.text = _getDisplayableDate(selectedDate);
        });
      } else {
        snackbarKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
                "La date de paiement ne peut pas être antérieure à la date du dernier paiement."),
          ),
        );
      }
    }
  }

  String _getDisplayableDate(DateTime date) {
    // return DateFormat.yMd('fr').format(date);
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
        setState(() {
          _sendPayment(paymentAmount);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Le montant saisi dépasse le montant total de la commande."),
          ),
        );
      }
    }
  }

  Future<void> _sendPayment(double amount) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: Text(
                'Vous allez envoyer un paiement de ${_paymentAmountController.text} à la date du ${_getDisplayableDate(selectedDate)} ?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Valider'),
                onPressed: () {
                  _addPayment(amount);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }).then((value) => _refreshPayments());
  }

  Future _addPayment(double amount) async {
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
    _refreshPayments();
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
              // Liste des paiements
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
                        child: Center(child: Text('Date')),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: Text('Méthode')),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: Text('Montant')),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(),
                      ),
                    ],
                  ),
                  ..._payments
                      .map(
                        (payment) => TableRow(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                  '${DateFormater().modifyDate(payment.paymentDate!.date!)}'),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(traduction(payment.paymentMethod!)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(payment.amount!.toStringAsFixed(2)),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: SizedBox(),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ],
              ),
              const SizedBox(height: 20),
              // Affiche le champ d'ajout de paiement si le montant total n'est pas atteint
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
                          onPressed: () {
                            _selectDate(context);
                          },
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
                            onChanged: (PaymentMethod? newValue) {
                              setState(() {
                                _selectedPaymentMethod = newValue;
                              });
                            },
                            items: _paymentMethods.map((PaymentMethod method) {
                              return DropdownMenuItem<PaymentMethod>(
                                value: method,
                                child: Text(traduction(method.name)),
                              );
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
                          validator: (value) {
                            double paymentAmount =
                                double.tryParse(value ?? '') ?? 0;
                            if (!_validatePayment(paymentAmount)) {
                              return "Le montant saisi dépasse le montant total de la commande.";
                            }
                            return null;
                          },
                          controller: _paymentAmountController,
                          onFieldSubmitted: (value) {
                            _submitPayment(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: NeoButton(
                            width: 100,
                            height: 40,
                            onPressed: () {
                              _submitPayment(_paymentAmountController.text);
                            },
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
