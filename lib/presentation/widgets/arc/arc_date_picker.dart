import 'package:flutter/material.dart';

/// Sélecteur de date du back-office (design system « Arc ») : style
/// `ArcTheme.datePickerTheme`, libellés en français, saisie au clavier
/// possible (JJ/MM/AAAA).
///
/// [initialDate] est ramenée dans [firstDate]–[lastDate] (aujourd'hui par
/// défaut) : `showDatePicker` refuse une date initiale hors bornes.
Future<DateTime?> showArcDatePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
  String? helpText,
  String confirmText = 'Valider',
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
}) {
  final DateTime first = DateUtils.dateOnly(firstDate);
  final DateTime last = DateUtils.dateOnly(lastDate);
  DateTime initial = DateUtils.dateOnly(initialDate ?? DateTime.now());
  if (initial.isBefore(first)) initial = first;
  if (initial.isAfter(last)) initial = last;

  return showDatePicker(
    context: context,
    locale: const Locale('fr', 'FR'),
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    initialEntryMode: initialEntryMode,
    helpText: helpText ?? 'Choisir une date',
    cancelText: 'Annuler',
    confirmText: confirmText,
    fieldLabelText: 'Date',
    fieldHintText: 'JJ/MM/AAAA',
    errorFormatText: 'Format attendu : JJ/MM/AAAA',
    errorInvalidText: 'Date en dehors de la période autorisée',
  );
}
