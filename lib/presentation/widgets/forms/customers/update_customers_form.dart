import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tribuneo_backoffice/config/responsive.dart';
import 'package:tribuneo_backoffice/config/size_config.dart';
import 'package:tribuneo_backoffice/domain/models/entity_model.dart';
import 'package:tribuneo_backoffice/domain/usecases/customer_usecase.dart';
import 'package:tribuneo_backoffice/presentation/utils/_global.dart';
import 'package:tribuneo_backoffice/presentation/utils/form_validator.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tribuneo_backoffice/presentation/widgets/forms/neo_input.dart';
import 'package:tribuneo_backoffice/presentation/widgets/neo_button.dart';

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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

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
      _customerUseCase.updateCustomer(e).then((value) {
        Navigator.pop(context);
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Modification du client réussie'),
          backgroundColor: Colors.green, // Optional: to change background color
        ));
      });
    } catch (e) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Erreur lors de la modification du client.'),
        backgroundColor: Colors.red, // Optional: to change background color
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
                          "Modifier le client",
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w600,
                              color: kOrange),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: NeoInput(
                                controller: customerNameController,
                                hintText: 'Nom du client',
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validateText(
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
                            Expanded(
                              flex: 2,
                              child: NeoInput(
                                controller: customerMailController,
                                hintText: 'Email du client',
                                keyboardType: TextInputType.text,
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
                      SizedBox(height: SizeConfig.screenHeight * 0.02),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: NeoInput(
                                controller: customerSiretController,
                                hintText: 'Siret du client',
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validateSiret(
                                      value ?? '');
                                },
                              ),
                            ),
                            !Responsive.isMobile(context)
                                ? Expanded(
                                    flex: Responsive.isDesktop(context) ? 4 : 2,
                                    child: const SizedBox(height: 10),
                                  )
                                : const SizedBox(height: 10),
                            Expanded(
                              flex: 2,
                              child: NeoInput(
                                controller: customerPhoneController,
                                hintText: 'Téléphone du client',
                                keyboardType: TextInputType.number,
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validatePhoneNumber(
                                      value ?? '');
                                },
                                formatter:
                                    FilteringTextInputFormatter.digitsOnly,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.02),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: NeoInput(
                                controller: customerCodeController,
                                hintText: 'Code du client',
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validateCode(
                                      value ?? '');
                                },
                              ),
                            ),
                            !Responsive.isMobile(context)
                                ? Expanded(
                                    flex: Responsive.isDesktop(context) ? 4 : 2,
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
                              text: "Enregistrer", onPressed: addCustomer),
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
