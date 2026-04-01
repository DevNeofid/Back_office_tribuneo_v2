// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
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
    return Center(
      child: Column(
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              //border: TableBorder(borderRadius: BorderRadius.circular(10)),
              headingRowColor: WidgetStateColor.resolveWith((states) => kLBlue),
              columns: const [
                DataColumn(
                    label: Center(child: SelectableText('Nom du fichier'))),
                DataColumn(
                    label: Center(child: SelectableText('Date de création'))),
                DataColumn(label: Center(child: SelectableText('Actions'))),
              ],
              rows: _accountingEntries.asMap().entries.map((entry) {
                final e = entry.value;
                final index = entry.key;
                final isEvenRow = index % 2 == 0;
                return DataRow(
                  cells: [
                    DataCell(Center(child: SelectableText(e.filename ?? ''))),
                    DataCell(Center(
                        child: SelectableText(
                            DateFormater().modifyDate(e.createdDate!)))),
                    DataCell(
                      Center(
                        child: PopupMenuButton<SampleItem>(
                          icon: const Icon(Icons.more_vert),
                          initialValue: selectedMenu,
                          // Callback that sets the selected popup menu item.
                          onSelected: (SampleItem item) {
                            if (item == SampleItem.itemOne) {
                              _downloadFile(e);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<SampleItem>>[
                            const PopupMenuItem<SampleItem>(
                              value: SampleItem.itemOne,
                              child: Text('Télécharger'),
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
      ),
    );
  }
}
