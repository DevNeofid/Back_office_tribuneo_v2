/// Aperçu du prochain ordre de virement (`GET /bto/preview`).
///
/// Seule source de vérité sur l'état des demandes : tous les montants viennent de
/// l'API, le front n'en calcule aucun.
class BtoPreviewModel {
  /// Les demandes sont prises jusqu'à cette date incluse (hier 23:59:59).
  final String? periodTo;
  final String? selectionFrom;

  /// Compte payeur retenu par l'API pour cet aperçu.
  final BtoPreviewBankAccount? bankAccount;
  final BtoPreviewTotals totals;

  /// Une entrée par commerçant à payer.
  final List<BtoMerchantToPay> toPay;

  /// Une entrée par demande écartée.
  final List<BtoExcludedRequest> excluded;

  BtoPreviewModel({
    this.periodTo,
    this.selectionFrom,
    this.bankAccount,
    required this.totals,
    required this.toPay,
    required this.excluded,
  });

  factory BtoPreviewModel.fromJson(Map<String, dynamic> json) {
    final dynamic bankAccount = json['bank_account'];
    final dynamic totals = json['totals'];
    return BtoPreviewModel(
      periodTo: json['period_to']?.toString(),
      selectionFrom: json['selection_from']?.toString(),
      bankAccount: bankAccount is Map
          ? BtoPreviewBankAccount.fromJson(Map<String, dynamic>.from(bankAccount))
          : null,
      totals: BtoPreviewTotals.fromJson(
          totals is Map ? Map<String, dynamic>.from(totals) : {}),
      toPay: _mapList(json['to_pay'], BtoMerchantToPay.fromJson),
      excluded: _mapList(json['excluded'], BtoExcludedRequest.fromJson),
    );
  }

  /// Rien à rembourser : réponse normale, pas une erreur.
  bool get isEmpty => toPay.isEmpty && excluded.isEmpty;
}

class BtoPreviewBankAccount {
  final String code;
  final String label;
  final String? iban;

  BtoPreviewBankAccount({required this.code, required this.label, this.iban});

  factory BtoPreviewBankAccount.fromJson(Map<String, dynamic> json) {
    final String code = json['code']?.toString() ?? '';
    final String label = json['label']?.toString() ?? '';
    return BtoPreviewBankAccount(
      code: code,
      label: label.isEmpty ? code : label,
      iban: json['iban']?.toString(),
    );
  }
}

class BtoPreviewTotals {
  final int requestsToPay;
  final int merchantsToPay;
  final num amountExcl;
  final num feesInclVat;
  final num amountToTransfer;
  final int requestsExcluded;

  BtoPreviewTotals({
    this.requestsToPay = 0,
    this.merchantsToPay = 0,
    this.amountExcl = 0,
    this.feesInclVat = 0,
    this.amountToTransfer = 0,
    this.requestsExcluded = 0,
  });

  factory BtoPreviewTotals.fromJson(Map<String, dynamic> json) {
    return BtoPreviewTotals(
      requestsToPay: _int(json['requests_to_pay']),
      merchantsToPay: _int(json['merchants_to_pay']),
      amountExcl: _num(json['amount_excl']),
      feesInclVat: _num(json['fees_incl_vat']),
      amountToTransfer: _num(json['amount_to_transfer']),
      requestsExcluded: _int(json['requests_excluded']),
    );
  }
}

class BtoMerchantToPay {
  final int? idEntity;
  final String? entityCode;
  final String entityName;
  final num totalPayable;
  final List<BtoRequestToPay> requests;

  BtoMerchantToPay({
    this.idEntity,
    this.entityCode,
    required this.entityName,
    required this.totalPayable,
    required this.requests,
  });

  factory BtoMerchantToPay.fromJson(Map<String, dynamic> json) {
    return BtoMerchantToPay(
      idEntity: _intOrNull(json['id_entity']),
      entityCode: json['entity_code']?.toString(),
      entityName: json['entity_name']?.toString() ?? '',
      totalPayable: _num(json['total_payable']),
      requests: _mapList(json['requests'], BtoRequestToPay.fromJson),
    );
  }
}

class BtoRequestToPay {
  final String transactionNumber;
  final String? createdDate;
  final num amount;
  final num feesInclVat;

  /// Net versé au commerçant pour cette demande.
  final num totalPayable;

  /// Les documents existent déjà (information seulement).
  final bool hasDocuments;
  final String? proofOfReceiptNumber;

  BtoRequestToPay({
    required this.transactionNumber,
    this.createdDate,
    required this.amount,
    required this.feesInclVat,
    required this.totalPayable,
    this.hasDocuments = false,
    this.proofOfReceiptNumber,
  });

  factory BtoRequestToPay.fromJson(Map<String, dynamic> json) {
    return BtoRequestToPay(
      transactionNumber: json['transaction_number']?.toString() ?? '',
      createdDate: json['created_date']?.toString(),
      amount: _num(json['amount']),
      feesInclVat: _num(json['fees_incl_vat']),
      totalPayable: _num(json['total_payable']),
      hasDocuments: json['has_documents'] == true,
      proofOfReceiptNumber: json['proof_of_receipt_number']?.toString(),
    );
  }
}

class BtoExcludedRequest {
  final String transactionNumber;
  final String? createdDate;
  final int? idEntity;
  final String? entityCode;
  final String entityName;
  final num amount;

  /// Codes bruts de l'API, éventuellement plusieurs.
  final List<String> reasons;

  /// Motif saisi par l'admin lors de la mise en attente.
  final String? holdReason;

  BtoExcludedRequest({
    required this.transactionNumber,
    this.createdDate,
    this.idEntity,
    this.entityCode,
    required this.entityName,
    required this.amount,
    required this.reasons,
    this.holdReason,
  });

  factory BtoExcludedRequest.fromJson(Map<String, dynamic> json) {
    return BtoExcludedRequest(
      transactionNumber: json['transaction_number']?.toString() ?? '',
      createdDate: json['created_date']?.toString(),
      idEntity: _intOrNull(json['id_entity']),
      entityCode: json['entity_code']?.toString(),
      entityName: json['entity_name']?.toString() ?? '',
      amount: _num(json['amount']),
      reasons: (json['reasons'] as List<dynamic>? ?? [])
          .map((reason) => reason.toString())
          .toList(),
      holdReason: json['hold_reason']?.toString(),
    );
  }

  bool get isOnHold => reasons.contains(onHold);

  /// La fiche du commerçant est à compléter (adresse ou coordonnées bancaires).
  bool get needsEntityCompletion =>
      reasons.contains(missingAddress) || reasons.contains(missingBankDetails);

  static const String missingAddress = 'MISSING_ADDRESS';
  static const String missingBankDetails = 'MISSING_BANK_DETAILS';
  static const String onHold = 'ON_HOLD';

  static const Map<String, String> _reasonLabels = {
    missingAddress: 'Adresse du commerçant incomplète',
    missingBankDetails: 'IBAN ou BIC du commerçant manquant',
    onHold: 'Mise en attente',
    'ZERO_PAYABLE_AMOUNT': 'Montant net nul après frais de gestion',
    'UNKNOWN_ENTITY': 'Commerçant introuvable, contactez le support',
  };

  /// Libellés français, dans l'ordre de l'API. Un motif inconnu (API plus récente
  /// que le back-office) est affiché tel quel plutôt que masqué.
  List<String> get reasonLabels => reasons
      .map((reason) => _reasonLabels[reason] ?? reason)
      .toList(growable: false);
}

/// Résultat de `GET /bto/gen` : le zip et les compteurs des en-têtes
/// `X-Requests-Paid` / `X-Requests-Excluded`, `null` s'ils ne sont pas exposés.
class BtoGenerationResult {
  final List<int> bytes;
  final String? filename;
  final int? requestsPaid;
  final int? requestsExcluded;

  BtoGenerationResult({
    required this.bytes,
    this.filename,
    this.requestsPaid,
    this.requestsExcluded,
  });
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

int _int(dynamic value) => _intOrNull(value) ?? 0;

int? _intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
