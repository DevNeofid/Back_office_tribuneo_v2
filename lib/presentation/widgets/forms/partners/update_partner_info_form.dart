import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/config/responsive.dart';
import 'package:back_office_tribuneo_v2/config/size_config.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
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
  bool _isSaving = false;

  final String entityType = 'partner';
  final String entityDescription = 'description';

  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    partnerNameController.text = widget.partner!.name ?? '';
    partnerMailController.text = widget.partner!.email ?? '';
    partnerSiretController.text = widget.partner!.siret ?? '';
    partnerPhoneController.text = widget.partner!.phone ?? '';
    partnerCodeController.text = widget.partner!.code ?? '';
    _checked = widget.partner!.acceptDemat ?? false;
  }

  Future<void> updatePartner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    EntityModel e = EntityModel.fromJson({
      "id": widget.partner!.id,
      "code": partnerCodeController.text,
      "name": partnerNameController.text,
      "email": partnerMailController.text,
      "siret": partnerSiretController.text,
      "phone": partnerPhoneController.text,
      "accept_demat": _checked,
    });

    try {
      await _partnerUseCase.updatePartner(e);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modification du partenaire réussie'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la modification du partenaire'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
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
                      "Modifier un partenaire",
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
                    controller: partnerNameController,
                    hintText: 'Nom du partenaire',
                    fillColor: kPWhite,
                    validator: (value) {
                      return FormValidator.validateText(value ?? '');
                    },
                  ),
                  const SizedBox(height: 16),
                  NeoInput(
                    controller: partnerMailController,
                    hintText: 'Email du partenaire',
                    keyboardType: TextInputType.emailAddress,
                    fillColor: kPWhite,
                    validator: (value) {
                      return FormValidator.validateText(value ?? '');
                    },
                  ),
                  const SizedBox(height: 16),
                  NeoInput(
                    controller: partnerSiretController,
                    hintText: 'Siret du partenaire',
                    fillColor: kPWhite,
                    validator: (value) {
                      return FormValidator.validateSiret(value ?? '');
                    },
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  NeoInput(
                    controller: partnerCodeController,
                    hintText: 'Code du partenaire',
                    fillColor: kPWhite,
                    validator: (value) {
                      return FormValidator.validateCode(value ?? '');
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Accepte la dématérialisation'),
                    value: _checked,
                    onChanged: (bool? value) {
                      setState(() {
                        _checked = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
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
                              onPressed: updatePartner,
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
