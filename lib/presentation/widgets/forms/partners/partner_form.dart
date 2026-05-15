import 'dart:developer';

import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

class PartnerForm extends StatefulWidget {
  const PartnerForm({Key? key}) : super(key: key);
  @override
  State<PartnerForm> createState() => _PartnerFormState();
}

class _PartnerFormState extends State<PartnerForm> {
  TextEditingController partnerNameController = TextEditingController();
  TextEditingController partnerMailController = TextEditingController();
  TextEditingController partnerSiretController = TextEditingController();
  TextEditingController partnerCodeController = TextEditingController();
  TextEditingController partnerPhoneController = TextEditingController();
  TextEditingController partnerDescriptionController = TextEditingController();

  bool _checked = false;
  bool _isLoading = false;

  final String entityType = 'partner';
  final String entityDescription = 'description';

  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  initState() {
    super.initState();
  }

  Future<void> addPartner() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      EntityModel e = EntityModel.fromJson({
        "name": partnerNameController.text,
        "email": partnerMailController.text,
        "siret": partnerSiretController.text,
        "code": partnerCodeController.text,
        "phone": partnerPhoneController.text,
        "accept_demat": _checked ? true : false,
        "type": entityType,
      });

      inspect(e);

      await _partnerUseCase.addPartner(e);

      if (!mounted) return;
      Navigator.pop(context, true);

      snackbarKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Inscription du partenaire réussie',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l’inscription : $error',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    partnerNameController.dispose();
    partnerMailController.dispose();
    partnerSiretController.dispose();
    partnerCodeController.dispose();
    partnerPhoneController.dispose();
    partnerDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(0),
      content: Form(
        key: _formKey,
        child: Container(
          width: SizeConfig.screenWidth * 0.3,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            color: kPLGrey2,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: SelectableText(
                    "Ajouter un partenaire",
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                        color: kOrange),
                  ),
                ),
                const SizedBox(height: 30),
                NeoInput(
                  controller: partnerNameController,
                  hintText: 'Nom du partenaire',
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateText(value ?? '');
                  },
                ),
                const SizedBox(height: 20),
                NeoInput(
                  controller: partnerMailController,
                  hintText: 'Email du partenaire',
                  keyboardType: TextInputType.emailAddress,
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateText(value ?? '');
                  },
                ),
                const SizedBox(height: 20),
                NeoInput(
                  controller: partnerSiretController,
                  hintText: 'Siret du partenaire',
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateSiret(value ?? '');
                  },
                ),
                const SizedBox(height: 20),
                NeoInput(
                  controller: partnerPhoneController,
                  hintText: 'Téléphone du partenaire',
                  keyboardType: TextInputType.phone,
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validatePhoneNumber(value ?? '');
                  },
                  formatter: FilteringTextInputFormatter.digitsOnly,
                ),
                const SizedBox(height: 20),
                NeoInput(
                  controller: partnerCodeController,
                  hintText: 'Code du partenaire',
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateCode(value ?? '');
                  },
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: Text(
                    'Accepte la dématérialisation',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: kBlack,
                    ),
                  ),
                  value: _checked,
                  onChanged: (bool? value) {
                    setState(() {
                      _checked = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: kBlue,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.poppins(
                          color: _isLoading ? Colors.grey : kRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.only(right: 40.0),
                            child: CircularProgressIndicator(
                              color: kOrange,
                            ),
                          )
                        : NeoButton(
                            text: "Enregistrer",
                            onPressed: addPartner,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
