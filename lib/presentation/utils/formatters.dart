import 'package:intl/intl.dart';

final NumberFormat _euroFormat =
    NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);

final NumberFormat _compactAmountFormat = NumberFormat('#,##0.##', 'fr_FR');

final DateFormat _frenchDateFormat = DateFormat('dd/MM/yyyy');

/// Montant en euros, tel que reçu de l'API : `1 234,50 €` (2 décimales, virgule,
/// espace insécable). Ne fait aucun calcul.
String formatEuro(num? amount) => _euroFormat.format(amount ?? 0);

/// Montant sans décimales inutiles, pour les phrases : `30`, `12,5`.
String formatAmount(num? amount) => _compactAmountFormat.format(amount ?? 0);

/// Date de l'API (`2026-10-13 23:59:59` ou ISO) au format `13/10/2026`.
/// Chaîne vide si la date est absente ou illisible.
String formatFrenchDate(String? apiDate) {
  final DateTime? parsed = DateTime.tryParse(apiDate?.trim() ?? '');
  return parsed == null ? '' : _frenchDateFormat.format(parsed);
}

/// Date au format attendu par l'API : `2026-10-13`.
String formatApiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Demain à minuit : date minimale pour une date de validité de bon.
DateTime tomorrow() {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day + 1);
}

/// `1 demande`, `3 demandes`.
String plural(int count, String singular, [String? pluralForm]) =>
    '$count ${count > 1 ? (pluralForm ?? '${singular}s') : singular}';
