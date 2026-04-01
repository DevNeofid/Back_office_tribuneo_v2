import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tribuneo_backoffice/config/responsive.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'package:tribuneo_backoffice/domain/models/order_model.dart';
import 'package:tribuneo_backoffice/domain/models/urssaf_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/orders_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/form_validator.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tribuneo_backoffice/presentation/widgets/forms/neo_input.dart';
import 'package:tribuneo_backoffice/presentation/widgets/forms/neo_row.dart';
import 'package:tribuneo_backoffice/presentation/widgets/neo_button.dart';

class UpdateOrderForm extends StatefulWidget {
  final OrderRecModel? orderItem;
  const UpdateOrderForm({Key? key, required this.orderItem}) : super(key: key);
  @override
  State<UpdateOrderForm> createState() => _UpdateOrderFormState();
}

class _UpdateOrderFormState extends State<UpdateOrderForm> {
  TextEditingController orderDateController = TextEditingController();
  TextEditingController expiryDateController = TextEditingController();
  TextEditingController giftFromController = TextEditingController();
  TextEditingController giftReasonController = TextEditingController();
  InputDatePickerFormField orderDateControllerDP = InputDatePickerFormField(
      initialDate: DateTime.now(),
      // Date now - one year
      firstDate: DateTime(
          DateTime.now().year - 1, DateTime.now().month, DateTime.now().day),
      lastDate: DateTime(
          DateTime.now().year + 4, DateTime.now().month, DateTime.now().day));

  List<NeoRow> neorow = List.empty(growable: true);
  List<UrssafModel> _urssafEvent = [];
  final OrderUseCase _orderUseCase = OrderUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isChecked = false;
  late OrderRecModel modifyItem;
  DateTime selectedDate = DateTime.now();
  UrssafModel? _selectedUrssafEvent;
  late DateTime selectedExpiryDate;
  late DateTime oldExpiryDate;

  @override
  initState() {
    super.initState();
    modifyItem = widget.orderItem!;
    selectedExpiryDate = DateTime.now().add(const Duration(days: 365));
    oldExpiryDate = DateTime.parse(modifyItem.fundExpiryDate!.date!);
    if (modifyItem.orderItems!.length > 1) {
      isChecked = true;
    }
    for (var i = 0; i < modifyItem.orderItems!.length; i++) {
      neorow.add(NeoRow(
        initialValue: modifyItem.orderItems![i].amount.toString(),
        initialNumber: modifyItem.orderItems![i].quantity.toString(),
        initialPersoMsg: modifyItem.orderItems![i].persoMsg,
      ));
    }
    orderDateController.text =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
    expiryDateController.text = _getDisplayableDate(oldExpiryDate);
    giftReasonController.text = modifyItem.giftReason!;
    getUrssaf();
  }

  Future<void> sendModifiedOrder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    if (modifyItem.id != -1) {
      setState(() {
        giftFromController.text = modifyItem.giftFrom!;
        giftReasonController.text = modifyItem.giftReason!;
      });
    }
    int fundQuantity = 0;
    List<Map<String, dynamic>> funds = [];
    for (var i = 0; i < neorow.length; i++) {
      int tmpQuantity = int.parse(neorow[i].fundNumberController.text);
      fundQuantity += tmpQuantity;
      funds.add({
        "amount": int.parse(neorow[i].fundValueController.text),
        "quantity": int.parse(neorow[i].fundNumberController.text),
        "perso_msg": neorow[i].persoMsgController.text,
      });
    }
    var inputFormat = DateFormat('dd/MM/yyyy');
    var inputDate = inputFormat.parse(expiryDateController.text);

    var outputFormat = DateFormat('yyyy-MM-dd');
    String dateFormated = outputFormat.format(inputDate);

    OrderSendModel o = OrderSendModel.fromJson({
      "id": modifyItem.id,
      "gift_from": modifyItem.giftFrom,
      "id_urssaf_event": modifyItem.idUrssaf,
      "gift_reason": giftReasonController.text,
      "fund_quantity": fundQuantity,
      "fund_expiry_date": dateFormated,
      "order_items": funds,
      "id_entity": modifyItem.id
    });
    inspect(o);
    _orderUseCase.updateOrder(o);
    Navigator.pop(context);
    return;
  }

  String expiryDate = "";

  _selectExpiryDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBlue,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
      fieldHintText: "Jour/Mois/Année",
      locale: const Locale("fr", "FR"),
      context: context,
      initialDate: oldExpiryDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(3000),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (selected != null && selected != oldExpiryDate) {
      setState(() {
        oldExpiryDate = selected;
        expiryDateController.text = _getDisplayableDate(oldExpiryDate);
      });
    }
  }

  String _getDisplayableDate(DateTime date) {
    String day = date.day > 9 ? date.day.toString() : "0${date.day.toString()}";
    String month =
        date.month > 9 ? date.month.toString() : "0${date.month.toString()}";
    return "$day/$month/${date.year}";
  }

  Future<void> getUrssaf() async {
    await _orderUseCase.getUrssaf().then((value) {
      setState(() {
        _urssafEvent = value;

        _selectedUrssafEvent ??= _urssafEvent.firstWhere(
            (event) => event.id == modifyItem.idUrssaf,
            orElse: () => _urssafEvent.first);
      });
    });
  }

  @override
  void dispose() {
    for (var i = 0; i < neorow.length; i++) {
      neorow[i].fundNumberController.dispose();
      neorow[i].fundValueController.dispose();
      neorow[i].persoMsgController.dispose();
    }
    orderDateController.dispose();
    expiryDateController.dispose();
    giftFromController.dispose();
    giftReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color getColor(Set<WidgetState> states) {
      const Set<WidgetState> interactiveStates = <WidgetState>{
        WidgetState.pressed,
        WidgetState.hovered,
        WidgetState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return kOrange;
      }
      return kBlue;
    }

    SizeConfig().init(context);

    return AlertDialog(
      backgroundColor: kTransparent,
      contentPadding: const EdgeInsets.all(0),
      content: Form(
        key: _formKey,
        child: Stack(children: [
          SizedBox(
            width: SizeConfig.screenWidth * 0.7,
            height: SizeConfig.screenHeight * 0.8,
            child: Container(
              width: SizeConfig.screenWidth * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: kPLGrey2,
              ),
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Center(
                        child: SelectableText(
                          "Modifier une commande",
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w600,
                              color: kOrange),
                        ),
                      ),
                      const SizedBox(height: 50),
                      SizedBox(height: SizeConfig.screenHeight * 0.01),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: NeoInput(
                                controller: expiryDateController,
                                hintText: 'Date d\'expiration',
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validateOrderDate(
                                      value ?? '');
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: NeoButton(
                                width: 100,
                                height: 40,
                                verticalPadding: 0,
                                horizontalPadding: 0,
                                fontSize: 12,
                                text: "Choisir une date",
                                backgroundColor: kBlue,
                                onPressed: () {
                                  _selectExpiryDate(context);
                                },
                              ),
                            ),
                            !Responsive.isMobile(context)
                                ? Expanded(
                                    flex: Responsive.isDesktop(context) ? 4 : 2,
                                    child: const SizedBox(height: 10),
                                  )
                                : const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.01),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Différents fonds ?",
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    letterSpacing: 0.3,
                                    fontWeight: FontWeight.w600,
                                    color: kBlue),
                              ),
                            ),
                            Expanded(
                                flex: 0,
                                child: Checkbox(
                                  checkColor: Colors.white,
                                  fillColor:
                                      WidgetStateProperty.resolveWith(getColor),
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isChecked = value!;
                                      if (neorow.length != 1) {
                                        neorow.removeRange(1, neorow.length);
                                      }
                                    });
                                  },
                                )),
                            !Responsive.isMobile(context)
                                ? Expanded(
                                    flex: Responsive.isDesktop(context) ? 3 : 1,
                                    child: const SizedBox(height: 10),
                                  )
                                : const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.01),
                      ListView.builder(
                          shrinkWrap: true,
                          itemCount: neorow.length,
                          itemBuilder: (_, index) {
                            return neorow[index];
                          }),
                      isChecked
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  child: RawMaterialButton(
                                    onPressed: () {
                                      setState(() {
                                        neorow.add(NeoRow());
                                      });
                                    },
                                    padding: const EdgeInsets.all(15.0),
                                    shape: const CircleBorder(
                                      side: BorderSide(
                                        color: kBlue,
                                        width: 1,
                                      ),
                                    ),
                                    elevation: 2.0,
                                    child: const Icon(
                                      Icons.add,
                                      color: kBlue,
                                    ),
                                  ),
                                ),
                                neorow.length > 1
                                    ? SizedBox(
                                        child: RawMaterialButton(
                                        onPressed: () {
                                          setState(() {
                                            neorow.removeLast();
                                          });
                                        },
                                        padding: const EdgeInsets.all(15.0),
                                        shape: const CircleBorder(
                                          side: BorderSide(
                                            color: kBlue,
                                            width: 1,
                                          ),
                                        ),
                                        elevation: 2.0,
                                        child: const Icon(
                                          Icons.remove,
                                          color: kBlue,
                                        ),
                                      ))
                                    : const SizedBox(width: 0, height: 0),
                              ],
                            )
                          : const SizedBox(height: 0),
                      SizedBox(height: SizeConfig.screenHeight * 0.01),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: giftFromController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 18,
                                  ),
                                  hintText: modifyItem.giftFrom,
                                  filled: true,
                                  hintStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                    color: kGrey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                readOnly: true,
                              ),
                            ),
                            !Responsive.isMobile(context)
                                ? Expanded(
                                    flex: Responsive.isDesktop(context) ? 3 : 1,
                                    child: const SizedBox(height: 10),
                                  )
                                : const SizedBox(height: 10),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<UrssafModel>(
                                items: _urssafEvent
                                    .map((event) =>
                                        DropdownMenuItem<UrssafModel>(
                                          value: event,
                                          child: Text(event.name!),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedUrssafEvent = value!;
                                  });
                                },
                                initialValue: _selectedUrssafEvent,
                                decoration: InputDecoration(
                                  labelText: "Pour l'occasion de",
                                  labelStyle:
                                      const TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeoButton(
                              text: "Enregistrer",
                              onPressed: sendModifiedOrder),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
