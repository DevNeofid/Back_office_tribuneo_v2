import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/voucher_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';

class VoucherView extends StatefulWidget {
  const VoucherView({super.key});

  @override
  VoucherViewState createState() => VoucherViewState();
}

class VoucherViewState extends State<VoucherView> {
  VoucherUseCase useCase = VoucherUseCase();
  List vouchers = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  void initData() {
    useCase.getVouchers().then((value) {
      setState(() {
        vouchers = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Column(
      children: <Widget>[
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateColor.resolveWith((states) => kLBlue),
              columns: const [
                DataColumn(
                    label: Center(child: Text('Identifiant du Qr_code'))),
                DataColumn(label: Center(child: Text('Montant'))),
                DataColumn(label: Center(child: Text('Date d\'expiration'))),
                DataColumn(label: Center(child: Text('Numéro de commande'))),
                DataColumn(label: Center(child: Text('Prénom'))),
                DataColumn(label: Center(child: Text('Nom'))),
                DataColumn(label: Center(child: Text('Téléphone'))),
                DataColumn(label: Center(child: Text('Email'))),
                DataColumn(
                    label: Center(
                  child: Text('Actions'),
                ))
              ],
              rows: vouchers.asMap().entries.map((entry) {
                final index = entry.key;
                final isEvenRow = index % 2 == 0;
                return DataRow(
                  color: isEvenRow
                      ? WidgetStateColor.resolveWith((states) => kPLGrey)
                      : WidgetStateColor.resolveWith((states) => kLBlue),
                  cells: [
                    // DataCell(Center(child: Text(e.invoiceNumber ?? ''))),
                    // DataCell(Center(child: Text(e.entityName ?? ''))),
                    // DataCell(Center(child: Text(e.entityCode ?? ''))),
                    // DataCell(Center(child: Text(e.feesInclVat ?? ''))),
                    // DataCell(Center(child: Text(e.totalPayable ?? ''))),
                    // DataCell(Center(child: Text(DateFormater().modifyDate(e.createdDate!)))),
                    // DataCell(
                    //   Center(
                    //     child: PopupMenuButton<SampleItem>(
                    //       icon: const Icon(Icons.more_vert),
                    //       initialValue: selectedMenu,
                    //       onSelected: (SampleItem item) {
                    //         if (item == SampleItem.itemOne) {
                    //           // _downloadFile(e);
                    //         }
                    //       },
                    //       itemBuilder: (BuildContext context) => <PopupMenuEntry<SampleItem>>[
                    //         const PopupMenuItem<SampleItem>(
                    //           value: SampleItem.itemOne,
                    //           child: Text('Télécharger'),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }
}
