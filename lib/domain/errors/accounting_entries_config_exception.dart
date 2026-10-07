import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';

/// Levée quand l'API refuse de générer les écritures parce qu'un compte bancaire
/// utilisé sur la période n'a pas de `journal` ou de `accounting_number`.
///
/// Rien n'est généré dans ce cas. Ces paramètres sont gérés par Neofid.
class AccountingEntriesConfigException extends ApiException {
  /// Manques renvoyés par l'API (`error.details.errors`), affichés tels quels.
  final List<String> errors;

  AccountingEntriesConfigException(this.errors)
      : super('Paramétrage comptable des comptes bancaires incomplet.');
}
