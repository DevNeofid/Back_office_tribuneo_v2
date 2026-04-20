// import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/address_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/address_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

class UpdateAddressForm extends StatefulWidget {
  final EntityModel entity;

  const UpdateAddressForm({Key? key, required this.entity}) : super(key: key);

  @override
  State<UpdateAddressForm> createState() => _UpdateAddressFormState();
}

class _UpdateAddressFormState extends State<UpdateAddressForm> {
  TextEditingController streetController = TextEditingController();
  TextEditingController zipController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController latController = TextEditingController();
  TextEditingController lngController = TextEditingController();

  final AddressUseCase _addressUseCase = AddressUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  initState() {
    streetController.text = widget.entity.address!.street!;
    zipController.text = widget.entity.address!.zip!;
    cityController.text = widget.entity.address!.city!;
    countryController.text = widget.entity.address!.country!;
    if (widget.entity.address!.lat != null) {
      latController.text = widget.entity.address!.lat!.toString();
    } else {
      latController.text = '';
    }
    if (widget.entity.address!.lng != null) {
      lngController.text = widget.entity.address!.lng!.toString();
    } else {
      lngController.text = '';
    }
    super.initState();
  }

  Future<void> updateAddress() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    Map<String, dynamic> addressMap = {
      'id': widget.entity.address!.id,
      'street': streetController.text,
      'zip': zipController.text,
      'city': cityController.text,
      'country': countryController.text,
      'id_entity': widget.entity.address!.idEntity,
    };
    if (latController.text.isNotEmpty) {
      addressMap['lat'] = double.parse(latController.text.replaceAll(',', '.'));
    } else {
      addressMap['lat'] = 0;
    }

    if (lngController.text.isNotEmpty) {
      addressMap['lng'] = double.parse(lngController.text.replaceAll(',', '.'));
    } else {
      addressMap['lng'] = 0;
    }
    AddressModel a = AddressModel.fromJson(addressMap);
    //inspect(a);

    try {
      await _addressUseCase.updateAddress(a);
      navigatorKey.currentState?.pop();
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Modification de l\'adresse réussie'),
        backgroundColor: Colors.green, // Optional: to change background color
      ));
    } catch (e) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Erreur lors de la modification de l\'adresse '),
        backgroundColor: Colors.red, // Optional: to change background color
      ));
    }
    return;
  }

  @override
  void dispose() {
    streetController.dispose();
    zipController.dispose();
    cityController.dispose();
    countryController.dispose();
    latController.dispose();
    lngController.dispose();
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
                          "Indiquer l'adresse de ce commerçant",
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
                                controller: streetController,
                                hintText: 'Adresse',
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
                                controller: zipController,
                                hintText: 'Code postal',
                                keyboardType: TextInputType.number,
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validateInt(value ?? '');
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
                                controller: cityController,
                                hintText: 'Ville',
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validateText(
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
                                controller: countryController,
                                hintText: 'Pays',
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
                                controller: latController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                hintText: 'lattitude',
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validatePosition(
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
                                controller: lngController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                hintText: 'Longitude',
                                fillColor: kPWhite,
                                validator: (value) {
                                  return FormValidator.validatePosition(
                                      value ?? '');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeoButton(
                              text: "Enregistrer", onPressed: updateAddress),
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
