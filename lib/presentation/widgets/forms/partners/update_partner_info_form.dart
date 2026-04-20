import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/neo_button.dart';

class UpdatePartnerInfo extends StatefulWidget {
  final EntityModel? partner;
  const UpdatePartnerInfo({Key? key, required this.partner}) : super(key: key);
  @override
  State<UpdatePartnerInfo> createState() => UpdatePartnerInfoState();
}

class UpdatePartnerInfoState extends State<UpdatePartnerInfo> {
  TextEditingController partnerNameController = TextEditingController();
  TextEditingController partnerMailController = TextEditingController();
  TextEditingController partnerSiretController = TextEditingController();
  TextEditingController partnerCodeController = TextEditingController();
  TextEditingController partnerPhoneController = TextEditingController();

  bool _checked = true;

  final String entityType = 'partner';
  final String entityDescription = 'description';

  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  initState() {
    partnerNameController.text = widget.partner!.name!;
    partnerMailController.text = widget.partner!.email!;
    partnerSiretController.text = widget.partner!.siret!;
    partnerPhoneController.text = widget.partner!.phone!;
    partnerCodeController.text = widget.partner!.code!;
    _checked = widget.partner!.acceptDemat == 1 ? true : false;
    super.initState();
  }

  Future updatePartner() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }

    EntityModel e = EntityModel.fromJson({
      "name": partnerNameController.text,
      "email": partnerMailController.text,
      "siret": partnerSiretController.text,
      "code": partnerCodeController.text,
      "phone": partnerPhoneController.text,
      "accept_demat": _checked ? 1 : 0,
      "type": entityType,
      "id": widget.partner!.id,
    });
    inspect(e);
    try {
      dynamic res = await _partnerUseCase.updatePartner(e);
      navigatorKey.currentState?.pop(res);

      // Show success message
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Modification du partenaire réussie'),
        backgroundColor: Colors.green, // Optional: to change background color
      ));
    } catch (e) {
      // Show error message if something goes wrong
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Erreur lors de la modification du partenaire'),
        backgroundColor: Colors.red, // Optional: to change background color
      ));
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    partnerNameController.dispose();
    partnerMailController.dispose();
    partnerSiretController.dispose();
    partnerCodeController.dispose();
    partnerPhoneController.dispose();
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
                          "Modifier un partenaire",
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
                                controller: partnerNameController,
                                hintText: 'Nom du partenaire',
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
                                controller: partnerMailController,
                                hintText: 'Email du partenaire',
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
                                controller: partnerSiretController,
                                hintText: 'Siret du partenaire',
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
                                controller: partnerPhoneController,
                                hintText: 'Téléphone du partenaire',
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
                                controller: partnerCodeController,
                                hintText: 'Code du partenaire',
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
                      SizedBox(height: SizeConfig.screenHeight * 0.02),
                      SizedBox(
                        height: 60,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: CheckboxListTile(
                                  title: const Text(
                                      'Accepte la dématérialisation'),
                                  value: _checked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _checked = value!;
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              ),
                            ]),
                      ),
                      SizedBox(height: SizeConfig.screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeoButton(
                              text: "Enregistrer", onPressed: updatePartner),
                          // SizedBox(
                          //   width: 200,
                          //   child: OutlinedButton(
                          //     //add order and pop screen
                          //     onPressed: () {
                          //       updatePartner();
                          //     },
                          //     style: OutlinedButton.styleFrom(
                          //       foregroundColor: kWhite,
                          //       backgroundColor: kOrange,
                          //       side:
                          //           const BorderSide(width: 0, color: kLGrey),
                          //       shape: RoundedRectangleBorder(
                          //           borderRadius: BorderRadius.circular(10)),
                          //       padding: const EdgeInsets.symmetric(
                          //           horizontal: 40, vertical: 12)
                          //       ),
                          //     child: Text(
                          //       "Enregistrer",
                          //       style: GoogleFonts.poppins(
                          //         fontSize: 16,
                          //         fontWeight: FontWeight.w700,
                          //       ),
                          //     ),
                          //   ),
                          // ),
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
