// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'dart:developer';
import 'package:tribuneo_backoffice/domain/models/transfer_order_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/transfer_order_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/utils/file_downloader.dart';
import 'package:tribuneo_backoffice/presentation/widgets/date_formater.dart';
import 'package:tribuneo_backoffice/presentation/widgets/loading.dart';

enum SampleItem { itemOne, itemTwo }

class TranferOrderView extends StatefulWidget {
  const TranferOrderView({super.key});

  @override
  State<TranferOrderView> createState() => _TranferOrderViewState();
}

class _TranferOrderViewState extends State<TranferOrderView> {
  final TransferOrderUseCase _transferOrderUseCase = TransferOrderUseCase();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  List<TransferOrderModel> _transferOrder = [];
  SampleItem? selectedMenu;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  _refreshOrders() async {
    _transferOrder = [];
    await _transferOrderUseCase.getTOrders().then((value) {
      setState(() {
        _transferOrder = value
            .map((e) => TransferOrderModel(
                id: e.id,
                filename: e.filename,
                retainedAmount: e.retainedAmount,
                refundedAmount: e.refundedAmount,
                createdDate: e.createdDate))
            .toList();
      });
      inspect(_transferOrder);
    });
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

      //download image
      FileDownloader.downloadLargeFile(
          listDynamic, '${name}', 'application/zip',
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
    return Center(
      child: Column(
        children: [
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
                    label: Center(child: SelectableText('Montant conservé'))),
                DataColumn(
                    label: Center(child: SelectableText('Montant remboursé'))),
                DataColumn(
                    label: Center(child: SelectableText('Date de création'))),
                DataColumn(label: Center(child: SelectableText('Actions'))),
              ],
              rows: _transferOrder.asMap().entries.map((entry) {
                final order = entry.value;
                final index = entry.key;
                final isEvenRow = index % 2 == 0;
                return DataRow(
                  cells: [
                    DataCell(
                        Center(child: SelectableText(order.filename ?? ''))),
                    DataCell(Center(
                        child:
                            SelectableText(order.retainedAmount.toString()))),
                    DataCell(Center(
                        child:
                            SelectableText(order.refundedAmount.toString()))),
                    DataCell(Center(
                        child: SelectableText(
                            DateFormater().modifyDate(order.createdDate!)))),
                    DataCell(
                      Center(
                        child: PopupMenuButton<SampleItem>(
                          icon: const Icon(Icons.more_vert),
                          initialValue: selectedMenu,
                          // Callback that sets the selected popup menu item.
                          onSelected: (SampleItem item) {
                            if (item == SampleItem.itemOne) {
                              _downloadFile(order);
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
