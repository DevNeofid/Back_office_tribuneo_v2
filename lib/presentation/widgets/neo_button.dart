import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tribuneo_backoffice/presentation/utils/common.dart';

class NeoButton extends StatelessWidget {
  final String text;
  final Function onPressed;
  final Color color;
  final Color textColor;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color shadowColor;
  final double width;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final double elevation;
  final double verticalPadding;
  final double horizontalPadding;
  final double margin;
  final bool isOutline;
  final bool isDisabled;

  const NeoButton({
    Key? key,
    required this.text,
    required this.onPressed(),
    this.color = kOrange,
    this.textColor = kPWhite,
    this.foregroundColor = kPWhite,
    this.backgroundColor = kOrange,
    this.shadowColor = kBlue,
    this.width = kButtonWidth,
    this.height = kButtonHeight,
    this.fontSize = kButtonFontSize,
    this.fontWeight = kButtonFontWeight,
    this.borderRadius = kButtonRadius,
    this.elevation = kButtonElevation,
    this.horizontalPadding = kButtonPaddingHorizontal,
    this.verticalPadding = kButtonPaddingVertical,
    this.margin = kButtonMargin,
    this.isOutline = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.all(margin),
      child: ElevatedButton(
        onPressed: (() => onPressed()),
        style: ElevatedButton.styleFrom(
          shadowColor: shadowColor,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          side: isOutline ? BorderSide(color: color) : BorderSide.none,
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
              top: verticalPadding,
              bottom: verticalPadding,
              left: horizontalPadding,
              right: horizontalPadding),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: isOutline ? color : textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
