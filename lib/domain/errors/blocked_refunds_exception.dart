import 'package:back_office_tribuneo_v2/domain/errors/api_exception.dart';

/// Un remboursement de la période qui ne peut pas entrer dans un ordre de virement,
/// avec la ou les raisons renvoyées par l'API.
class BlockedRefund {
  final String? entityCode;
  final String entityName;
  final String transactionNumber;

  /// Codes bruts de l'API (`MISSING_BANK_DETAILS`, `MISSING_ADDRESS`...).
  final List<String> reasons;

  BlockedRefund({
    required this.entityCode,
    required this.entityName,
    required this.transactionNumber,
    required this.reasons,
  });

  factory BlockedRefund.fromJson(Map<String, dynamic> json) {
    return BlockedRefund(
      entityCode: json['entity_code']?.toString(),
      entityName: json['entity_name']?.toString() ?? 'Partenaire inconnu',
      transactionNumber: json['transaction_number']?.toString() ?? '',
      reasons: (json['reasons'] as List<dynamic>? ?? [])
          .map((reason) => reason.toString())
          .toList(),
    );
  }

  /// Libellés français des codes, dans l'ordre renvoyé par l'API.
  /// Un code inconnu (API plus récente que le back-office) est affiché tel quel
  /// plutôt que masqué.
  List<String> get reasonLabels => reasons
      .map((reason) => _reasonLabels[reason] ?? reason)
      .toList(growable: false);

  static const Map<String, String> _reasonLabels = {
    'MISSING_PROOF_OF_RECEIPT': "le justificatif n'a pas été édité",
    'PROOF_OF_RECEIPT_NOT_LINKED_TO_INVOICE':
        "le justificatif n'est pas rattaché à une facture",
    'INVOICE_NOT_LINKED_TO_PROOF_OF_RECEIPT':
        "la facture n'est pas rattachée à son justificatif",
    'MISSING_ADDRESS': "l'adresse postale du partenaire n'est pas renseignée",
    'MISSING_BANK_DETAILS':
        "les coordonnées bancaires (IBAN, BIC) ne sont pas renseignées",
    'ZERO_PAYABLE_AMOUNT': 'le montant à rembourser est de 0,00 €',
  };
}

/// Levée quand l'API refuse de générer l'ordre de virement parce qu'au moins un
/// remboursement de la période est incomplet.
///
/// Rien n'a été généré côté API : aucun BTO n'est créé tant que la liste n'est pas vide,
/// pour qu'un partenaire ne soit jamais exclu silencieusement du fichier SEPA.
class BlockedRefundsException extends ApiException {
  final List<BlockedRefund> refunds;

  BlockedRefundsException(this.refunds)
      : super(refunds.length > 1
            ? '${refunds.length} remboursements ne peuvent pas être traités.'
            : 'Un remboursement ne peut pas être traité.');
}
