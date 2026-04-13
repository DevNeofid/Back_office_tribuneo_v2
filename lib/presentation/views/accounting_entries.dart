import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'dart:developer';
import 'package:tribuneo_backoffice/domain/models/accounting_entries_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/accounting_entries_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/utils/file_downloader.dart';
import 'package:tribuneo_backoffice/presentation/widgets/date_formater.dart';
import 'package:tribuneo_backoffice/presentation/widgets/loading.dart';

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

  List<AccountingEntriesModel> _accountingEntries = [];
  SampleItem? selectedMenu;
  late DateTime today;
  late String formattedDate;

  @override
  void initState() {
    super.initState();
    _timeNow();
    _refreshAccountingEntries();
  }

  _refreshAccountingEntries() async {
    _accountingEntries = [];
    await _accountingEntriesUseCase.getAccountingEntries().then((value) {
      setState(() {
        _accountingEntries = value
            .map((e) => AccountingEntriesModel(
                id: e.id, filename: e.filename, createdDate: e.createdDate))
            .toList();
      });
      inspect(_accountingEntries);
    });
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
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content:
              Text('Erreur lors de la génération des écritures comptables.')));
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
              final bool isCompact = MediaQuery.of(context).size.width < 1500;
              return Container(
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: isCompact ? 600 : 800,
                      ),
                      child: DataTable(
                        columnSpacing: isCompact ? 16 : 22,
                        horizontalMargin: isCompact ? 10 : 14,
                        dividerThickness: 0.6,
                        dataRowMinHeight: 50,
                        dataRowMaxHeight: 56,
                        headingRowHeight: 54,
                        headingTextStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kWhite,
                        ),
                        dataTextStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: kBlueEnd,
                        ),
                        headingRowColor: WidgetStateProperty.all(kBlue),
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
                          DataColumn(
                            label: Expanded(
                              child: Center(
                                child: Text('Actions',
                                    textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ],
                        rows: _accountingEntries.asMap().entries.map((entry) {
                          final e = entry.value;
                          final index = entry.key;
                          final isEvenRow = index % 2 == 0;
                          return DataRow(
                            color: isEvenRow
                                ? WidgetStateProperty.all(kWhite)
                                : WidgetStateProperty.all(
                                    kLBlue.withValues(alpha: 0.10)),
                            cells: [
                              DataCell(Center(
                                  child: SelectableText(e.filename ?? ''))),
                              DataCell(Center(
                                  child: SelectableText(DateFormater()
                                      .modifyDate(e.createdDate!)))),
                              DataCell(
                                Center(
                                  child: IconButton(
                                    icon: const Icon(Icons.download),
                                    color: kBlue,
                                    tooltip: 'Télécharger',
                                    onPressed: () {
                                      _downloadFile(e);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
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
