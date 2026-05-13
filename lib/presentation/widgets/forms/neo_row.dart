import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/form_validator.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/forms/neo_input.dart';

class RowModel {
  int? number;
  int? value;
  String? persoMsg;

  RowModel({this.value, this.number, this.persoMsg});
}

class NeoRow extends StatefulWidget {
  final String? initialNumber;
  final String? initialValue;
  final String? initialPersoMsg;
  NeoRow(
      {Key? key,
      RowModel? rowModel,
      index,
      fundNumberController,
      fundValueController,
      persoMsgController,
      this.initialNumber = '',
      this.initialValue = '',
      this.initialPersoMsg = ''})
      : super(key: key);

  @override
  State<NeoRow> createState() => NeoRowState();

  final TextEditingController fundNumberController = TextEditingController();
  final TextEditingController fundValueController = TextEditingController();
  final TextEditingController persoMsgController = TextEditingController();
}

class NeoRowState extends State<NeoRow> {
  final formKey = GlobalKey<FormState>();
  late ValueNotifier<bool> _showHint;

  @override
  void initState() {
    super.initState();
    _showHint = ValueNotifier(false);

    if (widget.initialNumber != '') {
      widget.fundNumberController.text = widget.initialNumber!;
    }
    if (widget.initialValue != '') {
      widget.fundValueController.text = widget.initialValue!;
    }
    if (widget.initialPersoMsg != '') {
      widget.persoMsgController.text = widget.initialPersoMsg!;
      _showHint.value = true;
    }

    widget.persoMsgController.addListener(() {
      _showHint.value = widget.persoMsgController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment
          .end, // Aligne le texte rouge à droite, au-dessus de son champ
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _showHint,
          builder: (context, showHint, child) {
            return showHint
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      "Le message personnalisé va remplacer la raison URSAF",
                      style: TextStyle(color: kBlue, fontSize: 12),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment
              .start, // Important pour l'alignement avec les erreurs de validation
          children: [
            Expanded(
              flex: 2,
              child: NeoInput(
                controller: widget.fundValueController,
                hintText: 'Montant par chèque',
                fillColor: kPWhite,
                keyboardType: TextInputType.number,
                validator: (value) {
                  return FormValidator.validateValueByFund(
                      int.parse(value?.toString() ?? '0'));
                },
              ),
            ),
            const SizedBox(width: 16), // Espacement fixe et raisonnable
            Expanded(
              flex: 2,
              child: NeoInput(
                controller: widget.fundNumberController,
                hintText: 'Nombre de chèque',
                keyboardType: TextInputType.number,
                fillColor: kPWhite,
                validator: (value) {
                  return FormValidator.validateNumberOfFunds(
                      int.parse(value?.toString() ?? '0'));
                },
                formatter: FilteringTextInputFormatter.digitsOnly,
              ),
            ),
            const SizedBox(width: 16), // Espacement fixe et raisonnable
            Expanded(
              flex:
                  3, // Donne un peu plus de place à ce champ qui a un texte plus long
              child: NeoInput(
                controller: widget.persoMsgController,
                hintText: 'Message personnalisé',
                keyboardType: TextInputType.text,
                fillColor: kPWhite,
                validator: (value) {
                  return FormValidator.validateText(value?.toString() ?? '');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _showHint.dispose();
    super.dispose();
  }
}
