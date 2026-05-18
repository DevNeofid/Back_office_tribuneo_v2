import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/customer_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

class UpdateCustomerForm extends StatefulWidget {
  final EntityModel? entity;

  const UpdateCustomerForm({Key? key, required this.entity}) : super(key: key);
  @override
  State<UpdateCustomerForm> createState() => UpdateCustomerFormState();
}

class UpdateCustomerFormState extends State<UpdateCustomerForm> {
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerMailController = TextEditingController();
  TextEditingController customerSiretController = TextEditingController();
  TextEditingController customerCodeController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();

  final String entityType = 'customer';
  final String entityDescription = 'description';

  final CustomerUseCase _customerUseCase = CustomerUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  initState() {
    customerNameController.text = widget.entity!.name!;
    customerMailController.text = widget.entity!.email!;
    customerSiretController.text = widget.entity!.siret!;
    customerCodeController.text = widget.entity!.code!;
    customerPhoneController.text = widget.entity!.phone!;
    super.initState();
  }

  Future<void> addCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    EntityModel e = EntityModel.fromJson({
      "name": customerNameController.text,
      "email": customerMailController.text,
      "siret": customerSiretController.text,
      "code": customerCodeController.text,
      "phone": customerPhoneController.text,
      "type": entityType,
      "id": widget.entity!.id,
    });
    inspect(e);

    try {
      await _customerUseCase.updateCustomer(e);
      if (!mounted) return;
      Navigator.pop(context, true);
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Modification du client réussie'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Erreur lors de la modification du client.'),
        backgroundColor: Colors.red,
      ));
    }
    return;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    customerNameController.dispose();
    customerMailController.dispose();
    customerSiretController.dispose();
    customerCodeController.dispose();
    customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    double formWidth = Responsive.isMobile(context)
        ? SizeConfig.screenWidth * 0.9
        : SizeConfig.screenWidth * 0.4;

    return AlertDialog(
      backgroundColor: kTransparent,
      contentPadding: const EdgeInsets.all(0),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: formWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: kPLGrey2,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: SelectableText(
                      "Modifier le client",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: Responsive.isMobile(context) ? 22 : 28,
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
                  const SizedBox(height: 16),
                  NeoInput(
                    controller: customerMailController,
                    hintText: 'Email du client',
                    keyboardType: TextInputType.emailAddress,
                    fillColor: kPWhite,
                    validator: (value) {
                      return FormValidator.validateText(value ?? '');
                    },
                  ),
                  const SizedBox(height: 16),
                  NeoInput(
                    controller: customerSiretController,
                    hintText: 'Siret du client',
                    keyboardType: TextInputType.number,
                    fillColor: kPWhite,
                    validator: (value) {
                      return FormValidator.validateSiret(value ?? '');
                    },
                    formatter: FilteringTextInputFormatter.digitsOnly,
                    maxLength: 14,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  NeoInput(
                    controller: customerCodeController,
                    hintText: 'Code du client',
                    fillColor: kPWhite,
                    validator: (value) {
                      return FormValidator.validateCode(value ?? '');
                    },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
      ),
    );
  }
}
