import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';

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
          backgroundColor: kSuccessText,
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
          backgroundColor: kDangerText,
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
    final String name = widget.partner?.name ?? '';

    return Form(
      key: _formKey,
      child: ArcFormPanel(
        eyebrow: 'Modifier le partenaire',
        title: name.trim().isEmpty ? 'Modifier un partenaire' : name,
        onClose: _isSaving ? null : () => Navigator.pop(context, false),
        actions: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ArcSubmitButton(
            label: 'Enregistrer',
            busy: _isSaving,
            onPressed: updatePartner,
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
                // Le code n'est pas saisissable ici : aucun validateur, pour
                // qu'une fiche sans code n'empêche pas d'enregistrer le reste.
                ArcGridItem(
                  ArcMonoField(
                    child: NeoInput(
                      controller: partnerCodeController,
                      hintText: 'Code du partenaire',
                      fillColor: kNavy50,
                      readOnly: true,
                    ),
                  ),
                ),
                ArcGridItem(
                  ArcMonoField(
                    child: NeoInput(
                      controller: partnerSiretController,
                      hintText: 'Siret du partenaire',
                      fillColor: kSurface,
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
                  "Le code du partenaire est attribué à la création et n'est pas modifiable depuis cet écran."),
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
