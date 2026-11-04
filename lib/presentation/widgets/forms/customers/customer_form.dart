import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/customer_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/customers/arc_form_panel.dart';

class CustomerForm extends StatefulWidget {
  final String? initialSiret;
  final bool? isIndividual;

  const CustomerForm({super.key, this.initialSiret, this.isIndividual});
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
  void initState() {
    super.initState();
    if (widget.initialSiret != null) {
      customerSiretController.text = widget.initialSiret!;
    }
  }

  Future<void> addCustomer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    } else {
      return;
    }

    bool isIndividual = widget.isIndividual ?? false;

    Map<String, dynamic> customerData = {
      "name": customerNameController.text,
      "email": customerMailController.text,
      "phone": customerPhoneController.text,
      "code": customerCodeController.text.trim().isEmpty
          ? null
          : customerCodeController.text.trim(),
      "type": entityType,
    };

    if (!isIndividual && customerSiretController.text.trim().isNotEmpty) {
      customerData["siret"] = customerSiretController.text.trim();
    }

    EntityModel e = EntityModel.fromJson(customerData);

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
        backgroundColor: kSuccessText,
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
        backgroundColor: kDangerText,
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
    bool isIndividual = widget.isIndividual ?? false;

    return Form(
      key: _formKey,
      child: ArcFormPanel(
        eyebrow: 'Nouveau client',
        title: 'Ajouter un client',
        subtitle: Text(isIndividual ? 'Particulier' : 'Professionnel'),
        onClose: _isSaving ? null : () => Navigator.pop(context, false),
        actions: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ArcSubmitButton(
            label: 'Ajouter le client',
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
                ArcGridItem(
                  NeoInput(
                    controller: customerCodeController,
                    hintText: 'Code du client',
                    fillColor: kSurface,
                    validator: (value) => null,
                  ),
                ),
                if (!isIndividual)
                  ArcGridItem(
                    ArcMonoField(
                      child: NeoInput(
                        controller: customerSiretController,
                        hintText: 'Siret du client',
                        fillColor: kSurface,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          return FormValidator.validateSiret(value);
                        },
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
                  "Le code du client est optionnel. Il peut être utilisé pour identifier le client dans vos systèmes internes."),
            ],
          ),
        ],
      ),
    );
  }
}
