import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                        minWidth: isCompact ? 800 : 1000,
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
                        rows: _transferOrder.asMap().entries.map((entry) {
                          final order = entry.value;
                          final index = entry.key;
                          final isEvenRow = index % 2 == 0;
                          return DataRow(
                            color: isEvenRow
                                ? WidgetStateProperty.all(kWhite)
                                : WidgetStateProperty.all(
                                    kLBlue.withValues(alpha: 0.10)),
                            cells: [
                              DataCell(Center(
                                  child: SelectableText(order.filename ?? ''))),
                              DataCell(Center(
                                  child: SelectableText(
                                      order.retainedAmount.toString()))),
                              DataCell(Center(
                                  child: SelectableText(
                                      order.refundedAmount.toString()))),
                              DataCell(Center(
                                  child: SelectableText(DateFormater()
                                      .modifyDate(order.createdDate!)))),
                              DataCell(
                                Center(
                                  child: PopupMenuButton<SampleItem>(
                                    icon: const Icon(Icons.more_vert),
                                    initialValue: selectedMenu,
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
