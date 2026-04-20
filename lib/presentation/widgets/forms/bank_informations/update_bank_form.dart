import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_informations_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/bank_informations_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

class UpadateBankInformationsForm extends StatefulWidget {
  final EntityModel entity;

  const UpadateBankInformationsForm({Key? key, required this.entity})
      : super(key: key);

  @override
  State<UpadateBankInformationsForm> createState() =>
      _UpadateBankInformationsFormState();
}

class _UpadateBankInformationsFormState
    extends State<UpadateBankInformationsForm> {
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
    bic.text = widget.entity.bankInformations!.bic!;
    key.text = widget.entity.bankInformations!.key!;
    bankCode.text = widget.entity.bankInformations!.bankCode!;
    officeCode.text = widget.entity.bankInformations!.officeCode!;
    accountNumber.text = widget.entity.bankInformations!.accountNumber!;
    accountingNumber.text = widget.entity.bankInformations!.accountingNumber!;

    iban.addListener(_handleTextChanged);
    iban.text = _formatIban(widget.entity.bankInformations!.iban!);
  }

  Future<void> addBankInformations() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    BankInformationsModel b = BankInformationsModel(
      id: widget.entity.bankInformations!.id,
      iban: iban.text.replaceAll(' ', ''),
      bic: bic.text,
      key: key.text,
      bankCode: bankCode.text,
      officeCode: officeCode.text,
      accountNumber: accountNumber.text,
      accountingNumber: accountingNumber.text,
      idEntity: widget.entity.id,
    );

    try {
      _bankInformationsUseCase.updateBankInfo(b);
      Navigator.pop(context);
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Modification des informations bancaires réussie'),
        backgroundColor: Colors.green, // Optional: to change background color
      ));
    } catch (e) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content:
            Text('Erreur lors de la modification des informations bancaires'),
        backgroundColor: Colors.red, // Optional: to change background color
      ));
    }
    return;
  }

  @override
  void dispose() {
    iban.dispose();
    iban.removeListener(_handleTextChanged);
    bic.dispose();
    key.dispose();
    bankCode.dispose();
    officeCode.dispose();
    accountNumber.dispose();
    accountingNumber.dispose();
    super.dispose();
  }

  String _formatIban(String iban) {
    iban = iban.replaceAll(' ', '');
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < iban.length; i++) {
      buffer.write(iban[i]);
      if ((i + 1) % 4 == 0 && i != iban.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  void _handleTextChanged() {
    String text = iban.text;
    String newText = _formatIban(text);
    if (newText != iban.text) {
      iban.value = iban.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
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
                                              flex:
                                                  Responsive.isDesktop(context)
                                                      ? 3
                                                      : 1,
                                              child: const SizedBox(height: 10),
                                            )
                                          : const SizedBox(height: 10),
                                      Expanded(
                                        flex: 2,
                                        child: NeoInput(
                                          controller: bic,
                                          hintText: 'BIC',
                                          // keyboardType: TextInputType.number,
                                          fillColor: kPWhite,
                                          validator: (value) {
                                            return FormValidator.validateText(
                                                value ?? '');
                                          },
                                          // formatter: FilteringTextInputFormatter
                                          //     .digitsOnly,
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
                                              flex:
                                                  Responsive.isDesktop(context)
                                                      ? 3
                                                      : 1,
                                              child: const SizedBox(height: 10),
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
                                              .numberWithOptions(decimal: true),
                                          hintText: 'Code guichet',
                                          fillColor: kPWhite,
                                          validator: (value) {
                                            return FormValidator
                                                .validatePosition(value ?? '');
                                          },
                                        ),
                                      ),
                                      !Responsive.isMobile(context)
                                          ? Expanded(
                                              flex:
                                                  Responsive.isDesktop(context)
                                                      ? 3
                                                      : 1,
                                              child: const SizedBox(height: 10),
                                            )
                                          : const SizedBox(height: 10),
                                      Expanded(
                                        flex: 2,
                                        child: NeoInput(
                                          controller: accountNumber,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          hintText: 'Numéro de compte',
                                          fillColor: kPWhite,
                                          validator: (value) {
                                            return FormValidator
                                                .validatePosition(value ?? '');
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    height: SizeConfig.screenHeight * 0.02),
                              ],
                            )
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
