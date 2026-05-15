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
  bool _isSaving = false;

  String? entityType;

  @override
  void initState() {
    super.initState();
    entityType = widget.entity.type;
    iban.addListener(_handleTextChanged);
  }

  Future<void> addBankInformations() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

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
    try {
      await _bankInformationsUseCase.addBankInfo(b);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
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
    // Largeur maximale pour que les champs ne s'étirent pas trop sur grand écran
    double inputWidth = Responsive.isDesktop(context) ? 400 : double.infinity;

    return AlertDialog(
      backgroundColor: kTransparent,
      contentPadding: const EdgeInsets.all(0),
      content: Form(
        key: _formKey,
        child: Stack(children: [
          SizedBox(
            width: SizeConfig.screenWidth * 0.4,
            height: SizeConfig.screenHeight * 0.9,
            child: Container(
              width: SizeConfig.screenWidth * 0.4,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: kPLGrey2,
              ),
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Center(
                        child: SelectableText(
                          "Indiquer les informations bancaire de ce commerçant",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w600,
                              color: kOrange),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (entityType == 'partner') ...[
                        SizedBox(
                          width: inputWidth,
                          child: NeoInput(
                            controller: iban,
                            hintText: 'Iban',
                            fillColor: kPWhite,
                            validator: (value) {
                              return FormValidator.validateText(value ?? '');
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: inputWidth,
                          child: NeoInput(
                            controller: bic,
                            hintText: 'BIC',
                            fillColor: kPWhite,
                            validator: (value) {
                              return FormValidator.validateText(value ?? '');
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: inputWidth,
                          child: NeoInput(
                            controller: key,
                            hintText: 'Clé RIB',
                            fillColor: kPWhite,
                            validator: (value) {
                              return FormValidator.validateText(value ?? '');
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: inputWidth,
                          child: NeoInput(
                            controller: bankCode,
                            hintText: 'Code établissement',
                            fillColor: kPWhite,
                            validator: (value) {
                              return FormValidator.validateText(value ?? '');
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: inputWidth,
                          child: NeoInput(
                            controller: officeCode,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            hintText: 'Code guichet',
                            fillColor: kPWhite,
                            validator: (value) {
                              return FormValidator.validatePosition(
                                  value ?? '');
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: inputWidth,
                          child: NeoInput(
                            controller: accountNumber,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            hintText: 'Numéro de compte',
                            fillColor: kPWhite,
                            validator: (value) {
                              return FormValidator.validatePosition(
                                  value ?? '');
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                      SizedBox(
                        width: inputWidth,
                        child: NeoInput(
                          controller: accountingNumber,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          hintText: 'Numéro de compte comptabilité',
                          fillColor: kPWhite,
                          validator: (value) {
                            return FormValidator.validateAccounting(
                                value ?? '');
                          },
                        ),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.04),
                      _isSaving
                          ? const SizedBox(
                              height: 40,
                              width: 40,
                              child: CircularProgressIndicator(
                                color: kOrange,
                              ),
                            )
                          : NeoButton(
                              text: "Enregistrer",
                              onPressed: addBankInformations,
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
