import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'common.dart';

/// Styles de texte du design system « Arc » : Bricolage Grotesque pour les
/// titres et chiffres clés, Poppins pour l'interface, Martian Mono pour les
/// montants, IBAN, SIRET et noms de fichiers.
abstract final class ArcText {
  static TextStyle display({Color color = kNavy900}) =>
      GoogleFonts.bricolageGrotesque(
          fontSize: 40,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: color);

  static TextStyle pageTitle({Color color = kNavy900}) =>
      GoogleFonts.bricolageGrotesque(
          fontSize: 32,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: color);

  static TextStyle kpi({Color color = kNavy900}) =>
      GoogleFonts.bricolageGrotesque(
          fontSize: 30, height: 1.1, fontWeight: FontWeight.w700, color: color);

  static TextStyle dialogTitle({Color color = kNavy900}) =>
      GoogleFonts.bricolageGrotesque(
          fontSize: 22, height: 1.2, fontWeight: FontWeight.w700, color: color);

  static TextStyle sectionTitle({Color color = kNavy900}) =>
      GoogleFonts.poppins(
          fontSize: 18, height: 1.45, fontWeight: FontWeight.w600, color: color);

  static TextStyle cardTitle({Color color = kNavy900}) => GoogleFonts.poppins(
      fontSize: 15, height: 1.45, fontWeight: FontWeight.w600, color: color);

  static TextStyle body({Color color = kInk}) => GoogleFonts.poppins(
      fontSize: 14, height: 1.55, fontWeight: FontWeight.w400, color: color);

  static TextStyle small({Color color = kText2}) => GoogleFonts.poppins(
      fontSize: 12, height: 1.4, fontWeight: FontWeight.w400, color: color);

  /// Libellé en capitales (en-têtes de KPI, groupes du menu).
  static TextStyle label({Color color = kText2}) => GoogleFonts.poppins(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: color);

  /// Chiffres à chasse fixe. La maquette resserre la police à 87,5 % ; les
  /// fichiers servis par google_fonts sont en largeur normale, d'où la taille
  /// et l'interlettrage réduits.
  static TextStyle data(
          {Color color = kInk, FontWeight fontWeight = FontWeight.w400}) =>
      GoogleFonts.martianMono(
          fontSize: 12.5,
          height: 1.5,
          letterSpacing: -0.3,
          fontWeight: fontWeight,
          color: color);

  static TextStyle dataSmall({Color color = kText2}) => GoogleFonts.martianMono(
      fontSize: 11,
      height: 1.45,
      letterSpacing: -0.3,
      fontWeight: FontWeight.w500,
      color: color);
}

/// Tonalités des pastilles et compteurs : point, texte, fond.
enum ArcTone {
  success(kSuccess, kSuccessText, kSuccessBg),
  warning(kWarning, kWarningText, kWarningBg),
  danger(kDanger, kDangerText, kDangerBg),
  info(kInfo, kInfoText, kInfoBg),
  neutral(kNeutral, kNeutralText, kNeutralBg);

  final Color dot, text, background;
  const ArcTone(this.dot, this.text, this.background);
}

abstract final class ArcTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    const scheme = ColorScheme.light(
      primary: kNavy600,
      onPrimary: Colors.white,
      primaryContainer: kNavy100,
      onPrimaryContainer: kNavy900,
      secondary: kOrange,
      onSecondary: kNavy900,
      secondaryContainer: kOrange100,
      onSecondaryContainer: kOrange700,
      tertiary: kNavy400,
      error: kDanger,
      onError: Colors.white,
      errorContainer: kDangerBg,
      onErrorContainer: kDangerText,
      surface: kSurface,
      onSurface: kInk,
      onSurfaceVariant: kText2,
      surfaceContainerLowest: kSurface,
      surfaceContainerLow: kSurface2,
      surfaceContainer: kNavy50,
      surfaceContainerHigh: kNavy100,
      surfaceContainerHighest: kNavy100,
      outline: kBorderStrong,
      outlineVariant: kBorder,
      inverseSurface: kNavy900,
      onInverseSurface: Colors.white,
      inversePrimary: kOrange300,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: kInk, displayColor: kNavy900)
        .copyWith(
          displayLarge: ArcText.display(),
          displayMedium: ArcText.pageTitle(),
          displaySmall: ArcText.kpi(),
          headlineSmall: ArcText.dialogTitle(),
          titleLarge: ArcText.sectionTitle(),
          titleMedium: ArcText.cardTitle(),
          bodyLarge: ArcText.body(),
          bodyMedium: ArcText.body(),
          bodySmall: ArcText.small(),
          labelLarge: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600, color: kNavy600),
          labelMedium: ArcText.label(),
        );

    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm));
    final buttonText =
        GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600);
    const buttonSize = Size(64, kControlHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20);

    OutlineInputBorder inputBorder(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusSm),
            borderSide: BorderSide(color: color, width: width));

    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: kCanvas,
      canvasColor: kSurface,
      dividerColor: kBorder,
      iconTheme: const IconThemeData(color: kNavy600, size: 20),
      dividerTheme:
          const DividerThemeData(color: kBorder, thickness: 1, space: 1),

      // Action principale : orange, texte navy (le blanc sur orange se lit mal).
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: kNavy900,
        disabledBackgroundColor: kNavy100,
        disabledForegroundColor: kNavy400,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonText,
      ).copyWith(
        overlayColor: const WidgetStatePropertyAll(Color(0x14F09A1A)),
      )),
      // Action secondaire : navy plein, sans relief.
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: kNavy600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kNavy100,
        disabledForegroundColor: kNavy400,
        elevation: 0,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonText,
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        backgroundColor: kSurface,
        foregroundColor: kNavy600,
        disabledForegroundColor: kNavy400,
        side: const BorderSide(color: kBorderStrong, width: 1.5),
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonText,
      )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: kNavy600,
        minimumSize: buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: buttonShape,
        textStyle: buttonText,
      )),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
        foregroundColor: kNavy600,
        minimumSize: const Size(kControlHeightCompact, kControlHeightCompact),
        shape: buttonShape,
      )),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kOrange,
        foregroundColor: kNavy900,
        elevation: 2,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: kText2),
        floatingLabelStyle: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w500, color: kNavy700),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: kText3),
        helperStyle: ArcText.small(color: kText3),
        errorStyle: ArcText.small(color: kDangerText),
        prefixIconColor: kText3,
        suffixIconColor: kText3,
        border: inputBorder(kBorderStrong),
        enabledBorder: inputBorder(kBorderStrong),
        focusedBorder: inputBorder(kNavy600, 2),
        errorBorder: inputBorder(kDanger),
        focusedErrorBorder: inputBorder(kDanger, 2),
        disabledBorder: inputBorder(kBorder),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: kNavy600,
        selectionColor: kNavy200,
        selectionHandleColor: kNavy600,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? kNavy600 : null),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: kBorderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: const RadioThemeData(
        fillColor: WidgetStatePropertyAll(kNavy600),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? kOrange : kSurface),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? kNavy600 : kNavy200),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      cardTheme: CardThemeData(
        color: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMd),
            side: const BorderSide(color: kBorder)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x4D1F2240),
        barrierColor: const Color(0x8C1F2240),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusLg)),
        titleTextStyle: ArcText.dialogTitle(),
        contentTextStyle: ArcText.body(color: kText2),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(kSurface2),
        headingRowHeight: 44,
        headingTextStyle: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600, color: kText2),
        dataRowColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.selected)
                ? kNavy50
                : kSurface),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        dataTextStyle: GoogleFonts.poppins(fontSize: 13, color: kInk),
        horizontalMargin: 20,
        columnSpacing: 24,
        dividerThickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kNavy100,
        selectedColor: kNavy900,
        disabledColor: kNeutralBg,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600, color: kNavy600),
        secondaryLabelStyle: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: kNavy900,
        unselectedLabelColor: kText2,
        indicatorColor: kOrange,
        dividerColor: kBorder,
        labelStyle:
            GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
            color: kNavy900, borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kNavy900,
        contentTextStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        actionTextColor: kOrange300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kBorder)),
        textStyle: GoogleFonts.poppins(fontSize: 13, color: kInk),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kOrange,
        linearTrackColor: kNavy100,
        circularTrackColor: kNavy100,
      ),
    );
  }
}
