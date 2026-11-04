import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_informations_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/bank_informations_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';

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
    iban.text = _formatIban(bankInformations?.iban ?? '');
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
          backgroundColor: kSuccessText,
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
          backgroundColor: kDangerText,
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
  String? _ibanError;

  /// Un IBAN français contient déjà le RIB : FR + clé (2) + code établissement
  /// (5) + code guichet (5) + numéro de compte (11) + clé RIB (2).
  void _prefillFromIban(String cleanIban) {
    // Le message d'erreur ne s'affiche qu'une fois la saisie complète, pour ne
    // pas signaler « invalide » pendant que l'utilisateur tape encore.
    String? error;
    if (cleanIban.length >= 27) {
      if (FormValidator.validateIban(cleanIban) != null) {
        error = '🚩 Format d\'IBAN invalide';
      } else if (!FormValidator.isValidIban(cleanIban)) {
        error = '🚩 IBAN invalide (clé de contrôle incorrecte)';
      }
    }
    if (error != _ibanError) {
      setState(() => _ibanError = error);
    }

    if (error != null || cleanIban.length != 27) return;
    if (cleanIban == _lastPrefilledIban) return;
    _lastPrefilledIban = cleanIban;
    bankCode.text = cleanIban.substring(4, 9);
    officeCode.text = cleanIban.substring(9, 14);
    accountNumber.text = cleanIban.substring(14, 25);
    key.text = cleanIban.substring(25, 27);
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.entity.name ?? '';
    final bool isPartner = entityType == 'partner';

    final Widget accounting = ArcFormGrid([
      ArcGridItem(
        ArcMonoField(
          child: NeoInput(
            controller: accountingNumber,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: 'Numéro de comptabilité',
            fillColor: kSurface,
            validator: (value) => null,
          ),
        ),
      ),
      ArcGridItem(
        ArcMonoField(
          child: NeoInput(
            maxLength: 13,
            controller: intraComNumber,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: 'Numéro intra communautaire',
            fillColor: kSurface,
            validator: (value) => null,
          ),
        ),
      ),
    ]);

    return Form(
      key: _formKey,
      child: ArcFormPanel(
        eyebrow: 'Modifier les informations bancaires',
        title: name.trim().isEmpty ? 'Informations bancaires' : name,
        onClose: _isSaving ? null : () => Navigator.pop(context, false),
        actions: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ArcSubmitButton(
            label: 'Enregistrer',
            busy: _isSaving,
            onPressed: addBankInformations,
          ),
        ],
        children: [
          if (isPartner)
            ArcFormSection(
              number: '1',
              title: 'Coordonnées bancaires',
              children: [
                ArcFormGrid([
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        maxLength: 34,
                        controller: iban,
                        hintText: 'Iban',
                        errorText: _ibanError,
                        fillColor: kSurface,
                        validator: (value) {
                          return FormValidator.validateIban(value ?? '');
                        },
                      ),
                    ),
                    span: true,
                  ),
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        maxLength: 11,
                        controller: bic,
                        hintText: 'BIC',
                        fillColor: kSurface,
                        validator: (value) {
                          return FormValidator.validateText(value ?? '');
                        },
                      ),
                    ),
                  ),
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        controller: key,
                        hintText: 'Clé RIB',
                        fillColor: kSurface,
                        validator: (value) => null,
                      ),
                    ),
                  ),
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        controller: bankCode,
                        hintText: 'Code établissement',
                        fillColor: kSurface,
                        validator: (value) => null,
                      ),
                    ),
                  ),
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        controller: officeCode,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        hintText: 'Code guichet',
                        fillColor: kSurface,
                        validator: (value) => null,
                      ),
                    ),
                  ),
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        controller: accountNumber,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        hintText: 'Numéro de compte',
                        fillColor: kSurface,
                        validator: (value) => null,
                      ),
                    ),
                    span: true,
                  ),
                ]),
                const ArcFormNote(
                    "Un IBAN français complet remplit automatiquement le code établissement, le code guichet, le numéro de compte et la clé RIB."),
              ],
            ),
          ArcFormSection(
            number: isPartner ? '2' : null,
            icon: Icons.account_balance_outlined,
            title: 'Comptabilité',
            children: [accounting],
          ),
        ],
      ),
    );
  }
}
