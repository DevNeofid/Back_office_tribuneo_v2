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
  TextEditingController intraComNumber = TextEditingController();

  final BankInformationsUseCase _bankInformationsUseCase =
      BankInformationsUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? entityType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    entityType = widget.entity.type;
    final bankInformations = widget.entity.bankInformations;

    bic.text = bankInformations?.bic ?? '';
    key.text = bankInformations?.key ?? '';
    bankCode.text = bankInformations?.bankCode ?? '';
    officeCode.text = bankInformations?.officeCode ?? '';
    accountNumber.text = bankInformations?.accountNumber ?? '';
    accountingNumber.text = bankInformations?.accountingNumber ?? '';
    intraComNumber.text = bankInformations?.intraCommunityVat ?? '';
    // Mémorise l'IBAN initial pour ne pas écraser les champs RIB venant de la
    // base à l'ouverture du formulaire — le préshot ne vaut que pour une
    // modification de l'IBAN par l'utilisateur.
    _lastPrefilledIban =
        (bankInformations?.iban ?? '').replaceAll(' ', '').toUpperCase();
    iban.addListener(_handleTextChanged);
    iban.text = _formatIban(bankInformations?.iban ?? '');
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
      id: widget.entity.bankInformations?.id,
      iban: iban.text.replaceAll(' ', ''),
      bic: bic.text,
      key: key.text.trim().isEmpty ? null : key.text.trim(),
      bankCode: bankCode.text.trim().isEmpty ? null : bankCode.text.trim(),
      officeCode:
          officeCode.text.trim().isEmpty ? null : officeCode.text.trim(),
      accountNumber:
          accountNumber.text.trim().isEmpty ? null : accountNumber.text.trim(),
      accountingNumber: accountingNumber.text.trim().isEmpty
          ? null
          : accountingNumber.text.trim(),
      intraCommunityVat: intraComNumber.text.trim().isEmpty
          ? null
          : intraComNumber.text.trim(),
      idEntity: widget.entity.id,
    );

    try {
      await _bankInformationsUseCase.updateBankInfo(b);
      if (!mounted) return;
      Navigator.pop(context, true);
      snackbarKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Modification des informations bancaires réussie'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      snackbarKey.currentState?.showSnackBar(
        const SnackBar(
          content:
              Text('Erreur lors de la modification des informations bancaires'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
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
    intraComNumber.dispose();
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
    _prefillFromIban(text.replaceAll(' ', '').toUpperCase());
  }

  String _lastPrefilledIban = '';

  /// Un IBAN français contient déjà le RIB : FR + clé (2) + code établissement
  /// (5) + code guichet (5) + numéro de compte (11) + clé RIB (2).
  void _prefillFromIban(String cleanIban) {
    if (!FormValidator.isValidIban(cleanIban)) return;
    if (cleanIban == _lastPrefilledIban) return;
    _lastPrefilledIban = cleanIban;
    bankCode.text = cleanIban.substring(4, 9);
    officeCode.text = cleanIban.substring(9, 14);
    accountNumber.text = cleanIban.substring(14, 25);
    key.text = cleanIban.substring(25, 27);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
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
                            maxLength: 34,
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
                            maxLength: 11,
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
                            validator: (value) => null,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: inputWidth,
                          child: NeoInput(
                            controller: bankCode,
                            hintText: 'Code établissement',
                            fillColor: kPWhite,
                            validator: (value) => null,
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
                            validator: (value) => null,
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
                            validator: (value) => null,
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
                          hintText: 'Numéro de comptabilité',
                          fillColor: kPWhite,
                          validator: (value) => null,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: inputWidth,
                        child: NeoInput(
                          maxLength: 13,
                          controller: intraComNumber,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          hintText: 'Numéro intra communautaire',
                          fillColor: kPWhite,
                          validator: (value) => null,
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
