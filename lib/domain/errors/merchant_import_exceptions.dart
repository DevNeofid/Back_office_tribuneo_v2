import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';
import 'package:back_office_tribuneo_v2/domain/models/merchant_import_row_model.dart';

/// Refus d'un `PATCH` de ligne qui renvoie l'état serveur de la ligne :
/// `VERSION_CONFLICT` (`details.row`) ou `ROW_HAS_ERRORS` (`details.issues`, et
/// `details.row` s'il est fourni).
class MerchantImportConflict extends ApiException {
  /// Ligne telle qu'elle est en base.
  final MerchantImportRow? row;

  /// Anomalies à jour de la ligne (`ROW_HAS_ERRORS`).
  final List<MerchantImportIssue> issues;

  MerchantImportConflict(super.message,
      {super.code, this.row, this.issues = const []});
}

/// Erreur réseau, timeout ou 5xx : rien n'a été enregistré, l'envoi peut être
/// retenté tel quel.
class MerchantImportTransientError extends ApiException {
  MerchantImportTransientError(super.message, {super.code});
}
