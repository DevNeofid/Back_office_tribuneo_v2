import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tribuneo_backoffice/config/responsive.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';
import 'package:tribuneo_backoffice/presentation/utils/form_validator.dart';
import 'package:tribuneo_backoffice/presentation/widgets/forms/neo_input.dart';

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
  NeoRow({
    Key? key,
    RowModel? rowModel,
    index,
    fundNumberController,
    fundValueController,
    persoMsgController,
    this.initialNumber = '',
    this.initialValue = '',
    this.initialPersoMsg = ''
  }) : super(key: key);

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
    return SizedBox(
      height: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        
          Row(
            children: [
              const Expanded(child: SizedBox()),
              ValueListenableBuilder<bool>(
                valueListenable: _showHint,
                builder: (context, showHint, child) {
                  return showHint
                      ? const Text(
                          "Le message personnalisé va remplacer la raison URSAF",
                          style: TextStyle(color: Colors.red),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              !Responsive.isMobile(context)
                  ? Expanded(
                      flex: Responsive.isDesktop(context) ? 4 : 2,
                      child: const SizedBox(height: 10),
                    )
                  : const SizedBox(height: 10),
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
              !Responsive.isMobile(context)
                  ? Expanded(
                      flex: Responsive.isDesktop(context) ? 4 : 2,
                      child: const SizedBox(height: 10),
                    )
                  : const SizedBox(height: 10),
              Expanded(
                flex: 3,
                child: NeoInput(
                  controller: widget.persoMsgController,
                  hintText: 'Message personnalisé',
                  keyboardType: TextInputType.text,
                  fillColor: kPWhite,
                  validator: (value) {
                    return FormValidator.validateText(
                        value?.toString() ?? '');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _showHint.dispose();
    super.dispose();
  }
}