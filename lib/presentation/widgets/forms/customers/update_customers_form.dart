import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/customer_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';

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
    customerSiretController.text = widget.entity?.siret ?? '';
    customerCodeController.text = widget.entity?.code ?? '';
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
        backgroundColor: kSuccessText,
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Erreur lors de la modification du client.'),
        backgroundColor: kDangerText,
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
    final String name = widget.entity?.name ?? '';

    return Form(
      key: _formKey,
      child: ArcFormPanel(
        eyebrow: 'Modifier le client',
        title: name.trim().isEmpty ? 'Modifier le client' : name,
        onClose: _isSaving ? null : () => Navigator.pop(context, false),
        actions: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ArcSubmitButton(
            label: 'Enregistrer',
            busy: _isSaving,
            onPressed: addCustomer,
          ),
        ],
        children: [
          ArcFormSection(
            number: '1',
            title: 'Identité',
            children: [
              ArcFormGrid([
                ArcGridItem(
                  NeoInput(
                    controller: customerNameController,
                    hintText: 'Nom du client',
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
                      controller: customerCodeController,
                      hintText: 'Code du client',
                      fillColor: kNavy50,
                      readOnly: true,
                    ),
                  ),
                ),
                ArcGridItem(
                  ArcMonoField(
                    child: NeoInput(
                      controller: customerSiretController,
                      hintText: 'Siret du client',
                      keyboardType: TextInputType.number,
                      fillColor: kSurface,
                      formatter: FilteringTextInputFormatter.digitsOnly,
                      maxLength: 14,
                    ),
                  ),
                ),
                ArcGridItem(
                  NeoInput(
                    controller: customerMailController,
                    hintText: 'Email du client',
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
                      controller: customerPhoneController,
                      hintText: 'Téléphone du client',
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
                  "Le code du client est attribué à la création et n'est pas modifiable depuis cet écran."),
            ],
          ),
        ],
      ),
    );
  }
}
