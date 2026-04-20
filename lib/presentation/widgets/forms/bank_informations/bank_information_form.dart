import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_informations_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/bank_informations_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

class BankInformationsForm extends StatefulWidget {
  final EntityModel entity;

  const BankInformationsForm({Key? key, required this.entity})
      : super(key: key);

  @override
  State<BankInformationsForm> createState() => _BankInformationsFormState();
}

class _BankInformationsFormState extends State<BankInformationsForm> {
  TextEditingController iban = TextEditingController();
  TextEditingController bic = TextEditingController();
  TextEditingController key = TextEditingController();
  TextEditingController bankCode = TextEditingController();
  TextEditingController officeCode = TextEditingController();
  TextEditingController accountNumber = TextEditingController();
  TextEditingController accountingNumber = TextEditingController();

  final BankInformationsUseCase _bankInformationsUseCase =
      BankInformationsUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? entityType;

  @override
  initState() {
    super.initState();
    entityType = widget.entity.type;
    iban.addListener(_handleTextChanged);
  }

  Future<void> addBankInformations() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    BankInformationsModel b = BankInformationsModel(
      iban: iban.text.replaceAll(' ', ''),
      bic: bic.text,
      key: key.text,
      bankCode: bankCode.text,
      officeCode: officeCode.text,
      accountNumber: accountNumber.text,
      accountingNumber: accountingNumber.text,
      idEntity: widget.entity.id,
    );
    _bankInformationsUseCase.addBankInfo(b);
    Navigator.pop(context);
    return;
  }

  void _handleTextChanged() {
    String text = iban.text;
    text = text.replaceAll(' ', '');
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }
    String newText = buffer.toString();
    if (newText != iban.text) {
      iban.value = iban.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    iban.removeListener(_handleTextChanged);
    iban.dispose();
    bic.dispose();
    key.dispose();
    bankCode.dispose();
    officeCode.dispose();
    accountNumber.dispose();
    accountingNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          "Indiquer les informations bancaire de ce commerçant",
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w600,
                              color: kOrange),
                        ),
                      ),
                      const SizedBox(height: 20),
                      entityType == 'partner'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  SizedBox(
                                    height: 60,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: NeoInput(
                                            controller: iban,
                                            hintText: 'Iban',
                                            fillColor: kPWhite,
                                            validator: (value) {
                                              return FormValidator.validateText(
                                                  value ?? '');
                                            },
                                          ),
                                        ),
                                        !Responsive.isMobile(context)
                                            ? Expanded(
                                                flex: Responsive.isDesktop(
                                                        context)
                                                    ? 3
                                                    : 1,
                                                child:
                                                    const SizedBox(height: 10),
                                              )
                                            : const SizedBox(height: 10),
                                        Expanded(
                                          flex: 2,
                                          child: NeoInput(
                                            controller: bic,
                                            hintText: 'BIC',
                                            //keyboardType: TextInputType.number,
                                            fillColor: kPWhite,
                                            validator: (value) {
                                              return FormValidator.validateText(
                                                  value ?? '');
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      height: SizeConfig.screenHeight * 0.02),
                                  SizedBox(
                                    height: 60,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: NeoInput(
                                            controller: key,
                                            hintText: 'Clé RIB',
                                            fillColor: kPWhite,
                                            validator: (value) {
                                              return FormValidator.validateText(
                                                  value ?? '');
                                            },
                                          ),
                                        ),
                                        !Responsive.isMobile(context)
                                            ? Expanded(
                                                flex: Responsive.isDesktop(
                                                        context)
                                                    ? 3
                                                    : 1,
                                                child:
                                                    const SizedBox(height: 10),
                                              )
                                            : const SizedBox(height: 10),
                                        Expanded(
                                          flex: 2,
                                          child: NeoInput(
                                            controller: bankCode,
                                            hintText: 'Code établissement',
                                            fillColor: kPWhite,
                                            validator: (value) {
                                              return FormValidator.validateText(
                                                  value ?? '');
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      height: SizeConfig.screenHeight * 0.02),
                                  SizedBox(
                                    height: 60,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: NeoInput(
                                            controller: officeCode,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            hintText: 'Code guichet',
                                            fillColor: kPWhite,
                                            validator: (value) {
                                              return FormValidator
                                                  .validatePosition(
                                                      value ?? '');
                                            },
                                          ),
                                        ),
                                        !Responsive.isMobile(context)
                                            ? Expanded(
                                                flex: Responsive.isDesktop(
                                                        context)
                                                    ? 3
                                                    : 1,
                                                child:
                                                    const SizedBox(height: 10),
                                              )
                                            : const SizedBox(height: 10),
                                        Expanded(
                                          flex: 2,
                                          child: NeoInput(
                                            controller: accountNumber,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            hintText: 'Numéro de compte',
                                            fillColor: kPWhite,
                                            validator: (value) {
                                              return FormValidator
                                                  .validatePosition(
                                                      value ?? '');
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      height: SizeConfig.screenHeight * 0.02),
                                ])
                          : const SizedBox(),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: NeoInput(
                                controller: accountingNumber,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                hintText: 'Numéro de compte comptabilité',
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validateAccounting(
                                      value ?? '');
                                },
                              ),
                            ),
                            !Responsive.isMobile(context)
                                ? Expanded(
                                    flex: Responsive.isDesktop(context) ? 3 : 1,
                                    child: const SizedBox(height: 10),
                                  )
                                : const SizedBox(height: 10),
                            const Expanded(
                              flex: 2,
                              child: SizedBox(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeoButton(
                              text: "Enregistrer",
                              onPressed: addBankInformations),
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
