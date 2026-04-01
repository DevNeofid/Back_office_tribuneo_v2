// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'package:tribuneo_backoffice/domain/models/refund_shop_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/transfer_order_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/utils/file_downloader.dart';
import 'package:tribuneo_backoffice/presentation/widgets/date_formater.dart';
import 'package:tribuneo_backoffice/presentation/widgets/loading.dart';
// import 'package:tribuneo_backoffice/presentation/widgets/date_formater.dart';

enum SampleItem { itemOne, itemTwo }

class RefoundShopView extends StatefulWidget {
  const RefoundShopView({super.key});
  @override
  State<RefoundShopView> createState() => _RefoundShopViewState();
}

class _RefoundShopViewState extends State<RefoundShopView> {
  final TransferOrderUseCase _transferOrderUseCase = TransferOrderUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  List<RefundShopModel> _refund = [];
  SampleItem? selectedMenu;

  late DateTime today;
  late String formattedDate;

  @override
  void initState() {
    super.initState();
    _timeNow();
    _refreshData();
  }

  _refreshData() async {
    _refund = [];
    await _transferOrderUseCase.awaitRefund().then((value) {
      setState(() {
        _refund = value
            .map((e) => RefundShopModel(
                transactionNumber: e.transactionNumber,
                refundAmount: e.refundAmount,
                code: e.code,
                name: e.name,
                isEdited: e.isEdited,
                createdDate: e.createdDate))
            .toList();
      });
    });
  }

  _timeNow() {
    today = DateTime.now().subtract(const Duration(days: 1));
    formattedDate = DateFormat('yyyy-MM-dd').format(today);
    return formattedDate;
  }

  Future _refundShop() async {
    bool hasUnedited = _refund.any((refund) => refund.isEdited == null);

    if (hasUnedited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Éditer tous les justificatifs pour pouvoir procéder à l'envoi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Génération des ordres de virement...');
      },
    );
    try {
      dynamic response = await _transferOrderUseCase.refundShop();
      String fileName = 'BTO_$formattedDate';
      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(listDynamic, fileName, 'application/zip',
          fileExtension: 'zip');

      // Here call
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content:
              Text('Erreur lors de la génération des ordres de virement.')));
    } finally {
      _refreshData();
      navigatorKey.currentState?.pop();
    }
  }

  Future _editProof(RefundShopModel refund) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(
            loadingText: 'Généreration des documents...');
      },
    );
    try {
      String? name = refund.code;
      name = name!.replaceAll(' ', '_');
      String? number = refund.refundAmount;
      dynamic response =
          await _transferOrderUseCase.editProof(refund.transactionNumber!);
      List<dynamic> listDynamic = response;

      FileDownloader.downloadLargeFile(
          listDynamic, '$name-$number', 'application/zip',
          fileExtension: 'zip');
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la génération de la facture.')));
    } finally {
      _refreshData();
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
              _refundShop();
            },
            child: const Text('Déclencher un remboursement'),
          ),
          const SizedBox(height: 50),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              //border: TableBorder(borderRadius: BorderRadius.circular(10)),
              headingRowColor: WidgetStateColor.resolveWith((states) => kLBlue),
              columns: const [
                DataColumn(label: Center(child: Text('Nom'))),
                DataColumn(label: Center(child: Text('Code'))),
                DataColumn(
                    label: Center(child: Text('Montant du remboursement'))),
                DataColumn(label: Center(child: Text('Justificatif édité ?'))),
                DataColumn(label: Center(child: Text('Date de demande'))),
                DataColumn(label: Center(child: Text('Gestion'))),
              ],
              rows: _refund.asMap().entries.map((entry) {
                final refund = entry.value;
                final index = entry.key;
                final isEvenRow = index % 2 == 0;
                return DataRow(
                  cells: [
                    DataCell(Center(child: SelectableText(refund.name ?? ''))),
                    DataCell(
                        Center(child: SelectableText(refund.code.toString()))),
                    DataCell(Center(
                        child: SelectableText(refund.refundAmount.toString()))),
                    DataCell(Center(
                        child: SelectableText(
                            refund.isEdited == null ? 'non' : 'oui'))),
                    DataCell(Center(
                        child: SelectableText(
                            DateFormater().modifyDate(refund.createdDate!)))),
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              _editProof(refund);
                            },
                            icon: const Icon(Icons.download),
                          ),
                        ],
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
