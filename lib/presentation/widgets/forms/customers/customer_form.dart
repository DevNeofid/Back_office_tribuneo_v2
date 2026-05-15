import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/customer_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

class CustomerForm extends StatefulWidget {
  const CustomerForm({Key? key}) : super(key: key);
  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerMailController = TextEditingController();
  TextEditingController customerSiretController = TextEditingController();
  TextEditingController customerCodeController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();
  TextEditingController customerDescriptionController = TextEditingController();

  final String entityType = 'customer';
  final String entityDescription = 'description';

  final CustomerUseCase _customerUseCase = CustomerUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  initState() {
    super.initState();
  }

  Future<void> addCustomer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    } else {
      return;
    }

    EntityModel e = EntityModel.fromJson({
      "name": customerNameController.text,
      "email": customerMailController.text,
      "siret": customerSiretController.text,
      "code": customerCodeController.text,
      "phone": customerPhoneController.text,
      "type": entityType,
    });

    inspect(e);

    setState(() {
      _isSaving = true;
    });

    try {
      await _customerUseCase.addCustomer(e);
      if (!mounted) return;
      Navigator.pop(context, true);
      snackbarKey.currentState?.showSnackBar(SnackBar(
        content: Text(
          'Ajout du client réussi.',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      snackbarKey.currentState?.showSnackBar(SnackBar(
        content: Text(
          'Erreur lors de l’ajout du client',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    customerNameController.dispose();
    customerMailController.dispose();
    customerSiretController.dispose();
    customerCodeController.dispose();
    customerPhoneController.dispose();
    customerDescriptionController.dispose();
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
                    "Ajouter un client",
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                        color: kOrange),
                  ),
                ),
                const SizedBox(height: 30),
                NeoInput(
                  controller: customerNameController,
                  hintText: 'Nom du client',
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateText(value ?? '');
                  },
                ),
                const SizedBox(height: 20),
                NeoInput(
                  controller: customerMailController,
                  hintText: 'Email du client',
                  keyboardType: TextInputType.emailAddress,
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateText(value ?? '');
                  },
                ),
                const SizedBox(height: 20),
                NeoInput(
                  controller: customerSiretController,
                  hintText: 'Siret du client',
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateSiret(value ?? '');
                  },
                ),
                const SizedBox(height: 20),
                NeoInput(
                  controller: customerPhoneController,
                  hintText: 'Téléphone du client',
                  keyboardType: TextInputType.phone,
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validatePhoneNumber(value ?? '');
                  },
                  formatter: FilteringTextInputFormatter.digitsOnly,
                ),
                const SizedBox(height: 20),
                NeoInput(
                  controller: customerCodeController,
                  hintText: 'Code du client',
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateCode(value ?? '');
                  },
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.poppins(
                          color: kRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                            onPressed: addCustomer,
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
