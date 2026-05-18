import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/accounting_entries_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/accounting_entries_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/date_formater.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

enum SampleItem { itemOne, itemTwo }

class AccountingEntriesView extends StatefulWidget {
  const AccountingEntriesView({super.key});

  @override
  State<AccountingEntriesView> createState() => _AccountingEntriesViewState();
}

class _AccountingEntriesViewState extends State<AccountingEntriesView> {
  final AccountingEntriesUseCase _accountingEntriesUseCase =
      AccountingEntriesUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  late final AccountingEntriesDataSource _dataSource;
  SampleItem? selectedMenu;
  late DateTime today;
  late String formattedDate;

  @override
  void initState() {
    super.initState();
    _timeNow();
    _dataSource =
        AccountingEntriesDataSource(_accountingEntriesUseCase, _downloadFile);
  }

  _timeNow() {
    today = DateTime.now().subtract(const Duration(days: 1));
    formattedDate = DateFormat('yyyy-MM-dd').format(today);
    return formattedDate;
  }

  Future _downloadFile(AccountingEntriesModel entry) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Génération des écritures comptables...');
      },
    );
    try {
      String? name = entry.filename;
      dynamic response =
          await _accountingEntriesUseCase.downloadFile(entry.id!);

      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(listDynamic, name!, 'application/zip',
          fileExtension: 'zip');
      _dataSource.refreshDatasource();
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Aucune écritures comptables disponibles.')));
    } finally {
      navigatorKey.currentState?.pop();
    }
  }

  Future _createAccountingEntries() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Génération des écritures comptables...');
      },
    );
    try {
      dynamic response =
          await _accountingEntriesUseCase.createAccountingEntries();
      String fileName = 'ECRITURES_$formattedDate';
      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(listDynamic, fileName, 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content:
              Text('Erreur lors de la génération des écritures comptables.')));
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
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(kOrange),
              ),
              onPressed: () {
                _createAccountingEntries();
              },
              child: const Text('Déclencher les écritures comptables'),
            ),
            const SizedBox(height: 50),
            Builder(builder: (context) {
              final double tableWidth = MediaQuery.of(context).size.width * 0.6;

              return Container(
                width: tableWidth,
                height: 600,
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
                      minWidth: 800,
                      rowsPerPage: 10,
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(
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

class AccountingEntriesDataSource extends AsyncDataTableSource {
  final AccountingEntriesUseCase _accountingEntriesUseCase;
  final Function(AccountingEntriesModel) onDownload;
  int _lastKnownTotal = 0;

  AccountingEntriesDataSource(this._accountingEntriesUseCase, this.onDownload);

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int limit) async {
    final int apiOffset = startIndex;
    final result = await _accountingEntriesUseCase.getAccountingEntries(
      limit: limit,
      offset: apiOffset,
    );

    final List<DataRow> rows = [];
    for (int i = 0; i < result.items.length; i++) {
      final e = result.items[i];
      final int rowIndex = startIndex + i;
      final isEvenRow = rowIndex % 2 == 0;

      rows.add(
        DataRow(
          color: isEvenRow
              ? WidgetStateProperty.all(kWhite)
              : WidgetStateProperty.all(kLBlue.withValues(alpha: 0.10)),
          cells: [
            DataCell(Center(child: SelectableText(e.filename ?? ''))),
            DataCell(Center(
                child: SelectableText(
                    DateFormater().modifyDate(e.createdDate ?? '') ?? ''))),
            DataCell(
              Center(
                child: IconButton(
                  icon: const Icon(Icons.download),
                  color: kBlue,
                  tooltip: 'Télécharger',
                  onPressed: () {
                    onDownload(e);
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
