import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';

class NeoInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;
  final TextInputType keyboardType;
  final double hintFontSize;
  final FontWeight hintFontWeight;
  final Color fillColor;
  final Color textColor;
  final InputBorder border;
  final String? Function(String?)? validator;
  final TextInputFormatter? formatter;

  const NeoInput({
    Key? key,
    required this.controller,
    required this.hintText,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.hintFontSize = kInputHintFontSize,
    this.hintFontWeight = kInputHintFontWeight,
    required this.fillColor,
    this.border = const OutlineInputBorder(
      borderSide: BorderSide(color: kPWhite),
      borderRadius: BorderRadius.all(Radius.circular(kInputRadius)),
    ),
    this.textColor = kBlack,
    this.validator,
    this.formatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: (formatter != null) ? [formatter!] : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          fontSize: hintFontSize,
          fontWeight: hintFontWeight,
          color: textColor,
        ),
        labelText: hintText,
        floatingLabelStyle: const TextStyle(color: kBlue),
        fillColor: fillColor,
        filled: true,
        isDense: true,
        border: border
      ),
    );
  }
}
