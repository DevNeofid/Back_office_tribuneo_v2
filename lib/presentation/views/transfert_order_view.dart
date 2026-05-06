import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/transfer_order_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/date_formater.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

enum SampleItem { itemOne, itemTwo }

class TranferOrderView extends StatefulWidget {
  const TranferOrderView({super.key});

  @override
  State<TranferOrderView> createState() => _TranferOrderViewState();
}

class _TranferOrderViewState extends State<TranferOrderView> {
  final TransferOrderUseCase _transferOrderUseCase = TransferOrderUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  late final TransferOrderDataSource _dataSource;
  SampleItem? selectedMenu;

  @override
  void initState() {
    super.initState();
    _dataSource = TransferOrderDataSource(_transferOrderUseCase, _downloadFile);
  }

  Future _downloadFile(TransferOrderModel order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Génération des ordres de virement...');
      },
    );
    try {
      String? name = order.filename;
      dynamic res = await _transferOrderUseCase.downloadFile(order.id!);

      List<dynamic> listDynamic = res;

      FileDownloader.downloadLargeFile(
          listDynamic, name ?? 'virement', 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content:
              Text('Erreur lors de la génération des ordres de virement.')));
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
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Builder(builder: (context) {
              final double tableWidth = MediaQuery.of(context).size.width < 1500
                  ? MediaQuery.of(context).size.width * 0.9
                  : MediaQuery.of(context).size.width * 0.7;

              return Container(
                width: tableWidth,
                height: 650,
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
                      columnSpacing: 22,
                      horizontalMargin: 14,
                      minWidth: 1000,
                      rowsPerPage: 10,
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn2(
                          size: ColumnSize.L,
                          label: Expanded(
                            child: Center(
                              child: Text('Nom du fichier',
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Center(
                              child: Text('Montant conservé',
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Center(
                              child: Text('Montant remboursé',
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        DataColumn2(
                          size: ColumnSize.S,
                          label: Expanded(
                            child: Center(
                              child: Text('Date de création',
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        DataColumn2(
                          size: ColumnSize.S,
                          label: Expanded(
                            child: Center(
                              child:
                                  Text('Actions', textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ],
                      source: _dataSource,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class TransferOrderDataSource extends AsyncDataTableSource {
  final TransferOrderUseCase _transferOrderUseCase;
  final Function(TransferOrderModel) onDownload;
  int _lastKnownTotal = 0;

  TransferOrderDataSource(this._transferOrderUseCase, this.onDownload);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final result = await _transferOrderUseCase.getOrders(
      limit: limit,
      offset: apiOffset,
    );

    final List<DataRow> rows = [];
    for (int i = 0; i < result.items.length; i++) {
      final order = result.items[i];
      final int rowIndex = startIndex + i;
      final isEvenRow = rowIndex % 2 == 0;

      rows.add(
        DataRow(
          color: isEvenRow
              ? WidgetStateProperty.all(kWhite)
              : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
          cells: [
            DataCell(Center(child: SelectableText(order.filename ?? ''))),
            DataCell(
                Center(child: SelectableText(order.retainedAmount.toString()))),
            DataCell(
                Center(child: SelectableText(order.refundedAmount.toString()))),
            DataCell(Center(
                child: SelectableText(
                    DateFormater().modifyDate(order.createdDate ?? '') ?? ''))),
            DataCell(
              Center(
                child: IconButton(
                  icon: const Icon(Icons.download),
                  color: kBlue,
                  tooltip: 'Télécharger',
                  onPressed: () {
                    onDownload(order);
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
      _lastKnownTotal = startIndex + result.items.length;
      if (result.items.length == limit) {
        _lastKnownTotal += 1;
      }
    }

    return AsyncRowsResponse(_lastKnownTotal, rows);
  }
}
