import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';

import 'package:back_office_tribuneo_v2/domain/models/invoice_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/document_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/date_formater.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

enum SampleItem { itemOne, itemTwo }

class DocumentsContentView extends StatefulWidget {
  const DocumentsContentView({Key? key}) : super(key: key);

  @override
  State<DocumentsContentView> createState() => _DocumentsContentViewState();
}

class _DocumentsContentViewState extends State<DocumentsContentView> {
  final DocumentUseCase _documentUseCase = DocumentUseCase();
  int _selectedButtonIndex = 0;
  late InvoiceDataSource _invoiceDataSource;
  late FeesDataSource _feesDataSource;

  @override
  void initState() {
    super.initState();
    _invoiceDataSource =
        InvoiceDataSource(_documentUseCase, _downloadFileInvoice);
    _feesDataSource = FeesDataSource(_documentUseCase, _downloadFileFees);
  }

  Future _downloadFileInvoice(InvoiceModel order) async {
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
          .downloadFileInvoice(order.idOrder!, prefixe: 'invoice_purchase');
      List<dynamic> listDynamic = response;

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

  Future _downloadFileFees(InvoiceModel fee) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(loadingText: 'Génération du document...');
      },
    );
    try {
      String? name = fee.entityName;
      name = name?.replaceAll(' ', '_') ?? 'Frais';
      dynamic response = await _documentUseCase.downloadFileFees(
          fee.transactionNumber ?? '',
          prefixe: 'proof_of_receipt');
      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(listDynamic, name, 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération du fichier.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SizedBox(
      height: SizeConfig.screenHeight * 0.9,
      width: double.infinity,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 40),
            Expanded(
              child: _selectedButtonIndex == 0
                  ? InvoicesContent(dataSource: _invoiceDataSource)
                  : FeesContent(dataSource: _feesDataSource),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoicesContent extends StatefulWidget {
  final InvoiceDataSource dataSource;
  const InvoicesContent({required this.dataSource, Key? key}) : super(key: key);

  @override
  State<InvoicesContent> createState() => _InvoicesContentState();
}

class _InvoicesContentState extends State<InvoicesContent> {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final bool isCompact = MediaQuery.of(context).size.width < 1500;
      final double tableWidth = MediaQuery.of(context).size.width * 0.8;
      return Container(
        width: tableWidth,
        height: 750,
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
              rowsPerPage: 10,
              showCheckboxColumn: false,
              columns: const [
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child: Text('Numéro de facture',
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.M,
                  label: Expanded(
                    child: Center(
                      child: Text('Nom', textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child: Text('Montant total (EUR)',
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child:
                          Text('Date de creation', textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child: Text('Actions', textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
              source: widget.dataSource,
            ),
          ),
        ),
      );
    });
  }
}

class FeesContent extends StatefulWidget {
  final FeesDataSource dataSource;
  const FeesContent({required this.dataSource, Key? key}) : super(key: key);

  @override
  State<FeesContent> createState() => _FeesContentState();
}

class _FeesContentState extends State<FeesContent> {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final bool isCompact = MediaQuery.of(context).size.width < 1500;
      final double tableWidth = MediaQuery.of(context).size.width * 0.8;
      return Container(
        width: tableWidth,
        height: 750,
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
              rowsPerPage: 10,
              showCheckboxColumn: false,
              columns: const [
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child: Text('Numéro de transaction',
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child: Text('Numéro de facture',
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.M,
                  label: Expanded(
                    child: Center(
                      child: Text('Destinataire', textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child: Text('Montant total (€)',
                          textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child:
                          Text('Date de création', textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  label: Expanded(
                    child: Center(
                      child: Text('Actions', textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
              source: widget.dataSource,
            ),
          ),
        ),
      );
    });
  }
}

// --- CLASSE DATASOURCE POUR FACTURES ---
class InvoiceDataSource extends AsyncDataTableSource {
  final DocumentUseCase _documentUseCase;
  final Function(InvoiceModel) onDownload;
  int _lastKnownTotal = 0;

  InvoiceDataSource(this._documentUseCase, this.onDownload);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final result = await _documentUseCase.getInvoices(
      'order',
      limit: limit,
      offset: apiOffset,
    );

    final List<DataRow> rows = [];
    for (int i = 0; i < result.items.length; i++) {
      final invoice = result.items[i];
      final int rowIndex = startIndex + i;
      final isEvenRow = rowIndex % 2 == 0;

      rows.add(
        DataRow(
          color: isEvenRow
              ? WidgetStateProperty.all(kWhite)
              : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
          cells: [
            DataCell(
                Center(child: SelectableText(invoice.invoiceNumber ?? ''))),
            DataCell(Center(child: SelectableText(invoice.entityName ?? ''))),
            DataCell(
              Center(
                child: SelectableText(
                  invoice.totalAmountInvoice != null
                      ? invoice.totalAmountInvoice!.toStringAsFixed(2)
                      : '0.00',
                ),
              ),
            ),
            DataCell(Center(
                child: Text(
                    DateFormater().modifyDate(invoice.createdDate ?? '') ??
                        ''))),
            DataCell(
              Center(
                child: IconButton(
                  icon: const Icon(Icons.download),
                  color: kBlue,
                  tooltip: 'Télécharger',
                  onPressed: () {
                    onDownload(invoice);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (result.total > 0) {
      _lastKnownTotal = result.total;
    } else {
      _lastKnownTotal = 0;
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}

// --- CLASSE DATASOURCE POUR FRAIS ---
class FeesDataSource extends AsyncDataTableSource {
  final DocumentUseCase _documentUseCase;
  final Function(InvoiceModel) onDownload;
  int _lastKnownTotal = 0;

  FeesDataSource(this._documentUseCase, this.onDownload);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final result = await _documentUseCase.getInvoices(
      'fees',
      limit: limit,
      offset: apiOffset,
    );

    final List<DataRow> rows = [];
    for (int i = 0; i < result.items.length; i++) {
      final fee = result.items[i];
      final int rowIndex = startIndex + i;
      final isEvenRow = rowIndex % 2 == 0;

      rows.add(
        DataRow(
          color: isEvenRow
              ? WidgetStateProperty.all(kWhite)
              : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
          cells: [
            DataCell(
                Center(child: SelectableText(fee.transactionNumber ?? ''))),
            DataCell(Center(child: SelectableText(fee.invoiceNumber ?? ''))),
            DataCell(Center(child: SelectableText(fee.entityName ?? ''))),
            DataCell(
              Center(
                child: SelectableText(
                  fee.totalAmountInvoice != null
                      ? fee.totalAmountInvoice!.toStringAsFixed(2)
                      : '0.00',
                ),
              ),
            ),
            DataCell(Center(
                child: Text(
                    DateFormater().modifyDate(fee.createdDate ?? '') ?? ''))),
            DataCell(
              Center(
                child: IconButton(
                  icon: const Icon(Icons.download),
                  color: kBlue,
                  tooltip: 'Télécharger',
                  onPressed: () {
                    onDownload(fee);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (result.total > 0) {
      _lastKnownTotal = result.total;
    } else {
      _lastKnownTotal = 0;
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}
