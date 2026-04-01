// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';

import 'package:tribuneo_backoffice/data/local/local_data_helper.dart';
import 'package:tribuneo_backoffice/domain/models/invoice_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/document_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/utils/file_downloader.dart';
import 'package:tribuneo_backoffice/presentation/widgets/date_formater.dart';
import 'package:tribuneo_backoffice/presentation/widgets/loading.dart';
import 'package:tribuneo_backoffice/presentation/widgets/neo_button.dart';

enum SampleItem { itemOne, itemTwo }

class DocumentsContentView extends StatefulWidget {
  const DocumentsContentView({Key? key}) : super(key: key);

  @override
  State<DocumentsContentView> createState() => _DocumentsContentViewState();
}

class _DocumentsContentViewState extends State<DocumentsContentView> {
  LocalDataHelper localDataHelper = LocalDataHelper();
  final DocumentUseCase _documentUseCase = DocumentUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  List<InvoiceModel> _orders = [];
  List<InvoiceModel> _allOrders = [];
  List<InvoiceModel> _fees = [];
  List<InvoiceModel> _allFees = [];
  int _selectedButtonIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshInvoices();
    _refreshFees();
  }

  _refreshInvoices() async {
    String order = 'order';
    _orders = [];
    await _documentUseCase.getInvoices(order).then((value) {
      setState(() {
        _orders = value
            .map((e) => InvoiceModel(
                  id: e.id,
                  invoiceNumber: e.invoiceNumber,
                  entityName: e.entityName,
                  entityCode: e.entityCode,
                  giftReason: e.giftReason,
                  totalAmountInvoice: e.totalAmountInvoice,
                  createdDate: e.createdDate,
                  idOrder: e.idOrder,
                  orderNumber: e.orderNumber,
                ))
            .toList();
      });
      _allOrders = List.from(_orders);
      // inspect(_allOrders);
    });

    setState(() {
      _isLoading = false;
    });
  }

  _refreshFees() async {
    String fees = 'fees';
    _fees = [];
    await _documentUseCase.getInvoices(fees).then((value) {
      setState(() {
        _fees = value
            .map((e) => InvoiceModel(
                  id: e.id,
                  invoiceNumber: e.invoiceNumber,
                  entityName: e.entityName,
                  entityCode: e.entityCode,
                  feesInclVat: e.feesInclVat,
                  totalPayable: e.totalPayable,
                  createdDate: e.createdDate,
                  idTransaction: e.idTransaction,
                  transactionNumber: e.transactionNumber,
                ))
            .toList();
      });
      // inspect(_allFees);
      _allFees = List.from(_fees);
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SizedBox(
      height: SizeConfig.screenHeight * 0.9,
      child: Scaffold(
        body: Column(
          children: [
            Row(
              children: [
                NeoButton(
                  onPressed: () {
                    setState(() {
                      _selectedButtonIndex = 0;
                    });
                  },
                  text: 'Factures',
                  backgroundColor:
                      _selectedButtonIndex == 0 ? kBlue : Colors.grey,
                ),
                SizedBox(width: SizeConfig.screenWidth * 0.01),
                NeoButton(
                  onPressed: () {
                    setState(() {
                      _selectedButtonIndex = 1;
                    });
                  },
                  text: 'Frais de gestion',
                  backgroundColor:
                      _selectedButtonIndex == 1 ? kBlue : Colors.grey,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kBlue))
                  : _selectedButtonIndex == 0
                      ? InvoicesContent(_orders, _allOrders)
                      : FeesContent(_fees, _allFees),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoicesContent extends StatefulWidget {
  final List<InvoiceModel> orders;
  final List<InvoiceModel> allOrders;
  const InvoicesContent(this.orders, this.allOrders, {Key? key})
      : super(key: key);
  @override
  State<InvoicesContent> createState() => _InvoicesContentState();
}

class _InvoicesContentState extends State<InvoicesContent> {
  final DocumentUseCase _documentUseCase = DocumentUseCase();
  final TextEditingController _searchOrderController = TextEditingController();
  List<InvoiceModel> _orders = [];
  List<InvoiceModel> _allOrders = [];
  SampleItem? selectedMenu;
  String prefixe = 'invoice_purchase';

  @override
  void initState() {
    super.initState();
    _orders = widget.orders;
    _allOrders = widget.allOrders;
  }

  Future _downloadFile(InvoiceModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(loadingText: 'Génération de la facture...');
      },
    );
    try {
      String? name = order.entityName;
      name = name!.replaceAll(' ', '_');
      String? number = order.orderNumber;
      dynamic response = await _documentUseCase
          .downloadFileInvoice(order.idOrder!, prefixe: prefixe);
      List<dynamic> listDynamic = response;
      // Uint8List bytes = Uint8List.fromList(listDynamic.cast<int>());

      FileDownloader.downloadLargeFile(
          listDynamic, '${name}_$number', 'application/pdf',
          fileExtension: 'pdf');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération du fichier.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  void _filterOrders(String query) {
    if (query.isEmpty) {
      setState(() {
        _orders = List.from(_allOrders);
      });
    } else {
      List<InvoiceModel> filteredOrders = _allOrders.where((order) {
        return (order.invoiceNumber
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
                false) ||
            (order.entityName?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (order.giftReason?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();

      setState(() {
        _orders = filteredOrders;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceDataSource = InvoiceDataSource(_orders, _downloadFile);
    int rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
    return Column(
      children: [
        const SizedBox(height: 50),
        SizedBox(
          width: SizeConfig.screenWidth * 0.3,
          child: TextField(
            controller: _searchOrderController,
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
        Expanded(
          child: PaginatedDataTable(
            columns: const [
              DataColumn(label: Center(child: Text('Numéro de facture'))),
              DataColumn(label: Center(child: Text('Destinataire'))),
              DataColumn(label: Center(child: Text('Code'))),
              DataColumn(label: Center(child: Text('Occasion'))),
              DataColumn(label: Center(child: Text('Montant total'))),
              DataColumn(label: Center(child: Text('Date de création'))),
              DataColumn(label: Center(child: Text('Actions')))
            ],
            source: invoiceDataSource,
            rowsPerPage: rowsPerPage,
            availableRowsPerPage: const [5, 10, 15],
            onRowsPerPageChanged: (value) {
              setState(() {
                rowsPerPage = value!;
              });
            },
            columnSpacing: 120,
            showCheckboxColumn: false,
          ),
        ),
      ],
    );
  }
}

class InvoiceDataSource extends DataTableSource {
  final List<InvoiceModel> invoices;
  final void Function(InvoiceModel)
      onDownload; // Fonction pour gérer le téléchargement
  InvoiceDataSource(this.invoices, this.onDownload);

  @override
  DataRow getRow(int index) {
    final invoice = invoices[index];
    return DataRow.byIndex(index: index, cells: [
      DataCell(Center(child: SelectableText(invoice.invoiceNumber ?? ''))),
      DataCell(SelectableText(invoice.entityName ?? '')),
      DataCell(SelectableText(invoice.entityCode ?? '')),
      DataCell(Center(child: SelectableText(invoice.giftReason ?? ''))),
      DataCell(
        Center(
          child: SelectableText(
            invoice.totalAmountInvoice != null
                ? invoice.totalAmountInvoice!.toStringAsFixed(2)
                : '',
          ),
        ),
      ),
      DataCell(Center(
          child: Text(
              DateFormater().modifyDate(invoice.createdDate!.date!) ?? ''))),
      DataCell(Center(
        child: PopupMenuButton<SampleItem>(
          icon: const Icon(Icons.more_vert),
          onSelected: (SampleItem item) {
            if (item == SampleItem.itemOne) {
              onDownload(invoice); // Appel de la fonction de téléchargement
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<SampleItem>>[
            const PopupMenuItem<SampleItem>(
              value: SampleItem.itemOne,
              child: Text('Télécharger'),
            ),
          ],
        ),
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => invoices.length;
  @override
  int get selectedRowCount => 0;
}

class FeesContent extends StatefulWidget {
  final List<InvoiceModel> fees;
  final List<InvoiceModel> allFees;
  const FeesContent(this.fees, this.allFees, {Key? key}) : super(key: key);
  @override
  State<FeesContent> createState() => _FeesContentState();
}

class _FeesContentState extends State<FeesContent> {
  final DocumentUseCase _documentUseCase = DocumentUseCase();
  final TextEditingController _searchFeeController = TextEditingController();
  List<InvoiceModel> _fees = [];
  List<InvoiceModel> _allFees = [];
  SampleItem? selectedMenu;
  String prefixe = 'proof_of_receipt';

  @override
  void initState() {
    super.initState();
    _fees = widget.fees;
    _allFees = widget.allFees;
  }

  Future _downloadFile(InvoiceModel fee) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(loadingText: 'Génération du document...');
      },
    );
    try {
      String? name = fee.entityCode;
      name = name!.replaceAll(' ', '_');
      String? number = fee.totalPayable.toString();
      dynamic response = await _documentUseCase
          .downloadFileFees(fee.transactionNumber!, prefixe: prefixe);
      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(
          listDynamic, '${name}_$number', 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération du fichier.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  void _filterFees(String query) {
    if (query.isEmpty) {
      setState(() {
        _fees = List.from(_allFees);
      });
    } else {
      List<InvoiceModel> filteredFees = _allFees.where((fees) {
        return (fees.invoiceNumber
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
                false) ||
            (fees.entityName?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (fees.giftReason?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();

      setState(() {
        _fees = filteredFees;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 50),
        SizedBox(
          width: SizeConfig.screenWidth * 0.3,
          child: TextField(
            controller: _searchFeeController,
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
              _filterFees(value);
            },
          ),
        ),
        const SizedBox(height: 50),
        Expanded(
          child: PaginatedDataTable(
            columns: const [
              DataColumn(label: Center(child: Text('Numéro de transaction'))),
              DataColumn(label: Center(child: Text('Destinataire'))),
              DataColumn(label: Center(child: Text('Code'))),
              DataColumn(label: Center(child: Text('Montant total'))),
              DataColumn(label: Center(child: Text('Montant total à payer'))),
              DataColumn(label: Center(child: Text('Date de création'))),
              DataColumn(label: Center(child: Text('Actions')))
            ],
            source:
                FeesDataSource(_fees, _downloadFile), // Passer la fonction ici
            rowsPerPage: PaginatedDataTable.defaultRowsPerPage,
            availableRowsPerPage: const [5, 10, 15],
            columnSpacing: 120,
            showCheckboxColumn: false,
          ),
        ),
      ],
    );
  }
}

class FeesDataSource extends DataTableSource {
  final List<InvoiceModel> fees;
  final void Function(InvoiceModel)
      onDownload; // Ajout de la fonction de téléchargement

  FeesDataSource(this.fees, this.onDownload);

  @override
  DataRow getRow(int index) {
    final fee = fees[index];
    return DataRow.byIndex(index: index, cells: [
      DataCell(Center(child: SelectableText(fee.transactionNumber ?? ''))),
      DataCell(SelectableText(fee.entityName ?? '')),
      DataCell(SelectableText(fee.entityCode ?? '')),
      DataCell(
        Center(
          child: SelectableText(
            fee.feesInclVat != null ? fee.feesInclVat!.toStringAsFixed(2) : '',
          ),
        ),
      ),
      DataCell(
        Center(
          child: SelectableText(
            fee.totalPayable != null
                ? fee.totalPayable!.toStringAsFixed(2)
                : '',
          ),
        ),
      ),
      DataCell(Center(
          child:
              Text(DateFormater().modifyDate(fee.createdDate!.date!) ?? ''))),
      DataCell(Center(
        child: PopupMenuButton<SampleItem>(
          icon: const Icon(Icons.more_vert),
          onSelected: (SampleItem item) {
            if (item == SampleItem.itemOne) {
              onDownload(fee); // Appel de la fonction de téléchargement
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<SampleItem>>[
            const PopupMenuItem<SampleItem>(
              value: SampleItem.itemOne,
              child: Text('Télécharger'),
            ),
          ],
        ),
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => fees.length;
  @override
  int get selectedRowCount => 0;
}
