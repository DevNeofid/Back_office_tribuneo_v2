import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/refund_shop_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/transfer_order_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/file_downloader.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/date_formater.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/loading.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Remboursement traite avec succes.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du traitement du remboursement.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        return const LoadingDialog(loadingText: 'Génération des documents...');
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
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.grey.shade400;
                  }
                  return kOrange;
                }),
              ),
              onPressed: _refund.isEmpty ? null : _refundShop,
              child: const Text('Déclencher un remboursement'),
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
                        minWidth: isCompact ? 1000 : 1200,
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
                                child: Text('Nom', textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Center(
                                child:
                                    Text('Code', textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Center(
                                child: Text('Montant du remboursement',
                                    textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Center(
                                child: Text('Justificatif édité ?',
                                    textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Center(
                                child: Text('Date de demande',
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
                        rows: _refund.asMap().entries.map((entry) {
                          final refund = entry.value;
                          final index = entry.key;
                          final isEvenRow = index % 2 == 0;
                          return DataRow(
                            color: isEvenRow
                                ? WidgetStateProperty.all(kWhite)
                                : WidgetStateProperty.all(
                                    kLBlue.withValues(alpha: 0.10)),
                            cells: [
                              DataCell(Center(
                                  child: SelectableText(refund.name ?? ''))),
                              DataCell(Center(
                                  child:
                                      SelectableText(refund.code.toString()))),
                              DataCell(Center(
                                  child: SelectableText(
                                      refund.refundAmount.toString()))),
                              DataCell(Center(
                                  child: SelectableText(refund.isEdited == null
                                      ? 'non'
                                      : 'oui'))),
                              DataCell(Center(
                                  child: SelectableText(DateFormater()
                                      .modifyDate(refund.createdDate!)))),
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
