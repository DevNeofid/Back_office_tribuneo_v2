import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/domain/models/address_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/address_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';

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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    streetController.text = widget.entity.address!.street ?? '';
    zipController.text = widget.entity.address!.zip ?? '';
    cityController.text = widget.entity.address!.city ?? '';
    countryController.text = widget.entity.address!.country ?? '';

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
  }

  Future<void> updateAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    Map<String, dynamic> addressMap = {
      'id': widget.entity.address!.id,
      'street': streetController.text,
      'zip': zipController.text,
      'city': cityController.text,
      'country': countryController.text,
      'id_entity': widget.entity.address!.idEntity,
    };

    if (latController.text.trim().isNotEmpty) {
      addressMap['lat'] = double.parse(latController.text.replaceAll(',', '.'));
    }

    if (lngController.text.trim().isNotEmpty) {
      addressMap['lng'] = double.parse(lngController.text.replaceAll(',', '.'));
    }

    AddressModel a = AddressModel.fromJson(addressMap);

    try {
      await _addressUseCase.updateAddress(a);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Modification de l\'adresse réussie'),
        backgroundColor: kSuccessText,
      ));

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors de la modification de l\'adresse'),
        backgroundColor: kDangerText,
      ));
    }
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
    final String name = widget.entity.name ?? '';
    final bool isPartner = widget.entity.type == 'partner';

    return Form(
      key: _formKey,
      child: ArcFormPanel(
        eyebrow: "Modifier l'adresse",
        title: name.trim().isEmpty ? "Indiquer l'adresse" : name,
        onClose: _isSaving ? null : () => Navigator.pop(context, false),
        actions: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ArcSubmitButton(
            label: 'Enregistrer',
            busy: _isSaving,
            onPressed: updateAddress,
          ),
        ],
        children: [
          ArcFormSection(
            icon: Icons.place_outlined,
            title: isPartner ? 'Adresse du magasin' : 'Adresse du client',
            children: [
              ArcFormGrid([
                ArcGridItem(
                  NeoInput(
                    controller: streetController,
                    hintText: 'Adresse',
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
                      controller: zipController,
                      hintText: 'Code postal',
                      keyboardType: TextInputType.number,
                      fillColor: kSurface,
                      validator: (value) {
                        return FormValidator.validateInt(value ?? '');
                      },
                      formatter: FilteringTextInputFormatter.digitsOnly,
                    ),
                  ),
                ),
                ArcGridItem(
                  NeoInput(
                    controller: cityController,
                    hintText: 'Ville',
                    fillColor: kSurface,
                    validator: (value) {
                      return FormValidator.validateText(value ?? '');
                    },
                  ),
                ),
                ArcGridItem(
                  NeoInput(
                    controller: countryController,
                    hintText: 'Pays',
                    fillColor: kSurface,
                    validator: (value) {
                      return FormValidator.validateText(value ?? '');
                    },
                  ),
                  span: true,
                ),
                if (isPartner) ...[
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        controller: latController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        hintText: 'Latitude',
                        fillColor: kSurface,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          return FormValidator.validatePosition(value);
                        },
                      ),
                    ),
                  ),
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        controller: lngController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        hintText: 'Longitude',
                        fillColor: kSurface,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          return FormValidator.validatePosition(value);
                        },
                      ),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
