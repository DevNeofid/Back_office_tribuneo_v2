import 'dart:developer';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';

class PartnerForm extends StatefulWidget {
  final String? initialSiret;

  const PartnerForm({super.key, this.initialSiret});

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
  void initState() {
    super.initState();
    if (widget.initialSiret != null) {
      partnerSiretController.text = widget.initialSiret!;
    }
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
        "code": partnerCodeController.text.trim().isEmpty
            ? null
            : partnerCodeController.text.trim(),
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
          backgroundColor: kSuccessText,
        ),
      );
    } catch (error) {
      snackbarKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l’inscription : $error',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: kDangerText,
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
    return Form(
      key: _formKey,
      child: ArcFormPanel(
        eyebrow: 'Nouveau partenaire',
        title: 'Ajouter un partenaire',
        onClose: _isLoading ? null : () => Navigator.pop(context, false),
        actions: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ArcSubmitButton(
            label: 'Ajouter le partenaire',
            busy: _isLoading,
            onPressed: addPartner,
          ),
        ],
        children: [
          ArcFormSection(
            number: '1',
            title: 'Informations du partenaire',
            children: [
              ArcFormGrid([
                ArcGridItem(
                  NeoInput(
                    controller: partnerNameController,
                    hintText: 'Nom du partenaire',
                    fillColor: kSurface,
                    validator: (value) {
                      return FormValidator.validateText(value ?? '');
                    },
                  ),
                  span: true,
                ),
                ArcGridItem(
                  ArcMonoField(
                    child: NeoInput(
                      controller: partnerCodeController,
                      hintText: 'Code du partenaire',
                      fillColor: kSurface,
                      validator: (value) => null,
                    ),
                  ),
                ),
                ArcGridItem(
                  ArcMonoField(
                    child: NeoInput(
                      controller: partnerSiretController,
                      hintText: 'Siret du partenaire',
                      keyboardType: TextInputType.number,
                      fillColor: kSurface,
                      maxLength: 14,
                      formatter: FilteringTextInputFormatter.digitsOnly,
                      validator: (value) {
                        return FormValidator.validateSiret(value ?? '');
                      },
                    ),
                  ),
                ),
                ArcGridItem(
                  NeoInput(
                    controller: partnerMailController,
                    hintText: 'Email du partenaire',
                    keyboardType: TextInputType.emailAddress,
                    fillColor: kSurface,
                    validator: (value) {
                      return FormValidator.validateMail(value ?? '');
                    },
                  ),
                ),
                ArcGridItem(
                  ArcMonoField(
                    child: NeoInput(
                      controller: partnerPhoneController,
                      hintText: 'Téléphone du partenaire',
                      keyboardType: TextInputType.phone,
                      fillColor: kSurface,
                      validator: (value) {
                        return FormValidator.validatePhoneNumber(value ?? '');
                      },
                      formatter: FilteringTextInputFormatter.digitsOnly,
                    ),
                  ),
                ),
              ]),
              const ArcFormNote(
                  "Le code du partenaire est optionnel. Il peut être utilisé pour identifier le partenaire dans vos systèmes internes."),
              ArcToggleCard(
                value: _checked,
                onChanged: (bool value) {
                  setState(() {
                    _checked = value;
                  });
                },
                title: 'Accepte la dématérialisation',
                subtitle:
                    'Le magasin accepte les bons sur mobile, pas seulement le papier.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
