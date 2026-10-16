/// Bénéficiaires d'une commande (`GET /order/{id}/beneficiaries`) : un bon par
/// ligne, hors dons et bons annulés.
class OrderBeneficiariesModel {
  final int? idOrder;
  final String? orderNumber;

  /// `manual`, `file` (import par fichier) ou `shop` (boutique en ligne).
  final String? source;
  final bool invoiced;

  /// Ajout de bénéficiaires autorisé.
  final bool canAdd;
  final List<OrderBeneficiaryModel> beneficiaries;

  OrderBeneficiariesModel({
    this.idOrder,
    this.orderNumber,
    this.source,
    this.invoiced = false,
    this.canAdd = false,
    required this.beneficiaries,
  });

  factory OrderBeneficiariesModel.fromJson(Map<String, dynamic> json) {
    return OrderBeneficiariesModel(
      idOrder: _intOrNull(json['id_order']),
      orderNumber: json['order_number']?.toString(),
      source: json['source']?.toString(),
      invoiced: _bool(json['invoiced']),
      canAdd: _bool(json['can_add']),
      beneficiaries: (json['beneficiaries'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) =>
              OrderBeneficiaryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  static const String sourceFile = 'file';
  static const String sourceShop = 'shop';

  bool get isImported => source == sourceFile;
  bool get isFromShop => source == sourceShop;
}

class OrderBeneficiaryModel {
  final int? idQrcode;
  final num amount;
  final num remainingAmount;
  final String? expiryDate;
  final String? email;
  final String? mobile;
  final String? firstname;
  final String? lastname;
  final bool assigned;
  final String? assignedTo;
  final bool canEditContact;
  final bool canEditAmount;
  final bool canRemove;
  final bool canResendMail;

  OrderBeneficiaryModel({
    this.idQrcode,
    required this.amount,
    this.remainingAmount = 0,
    this.expiryDate,
    this.email,
    this.mobile,
    this.firstname,
    this.lastname,
    this.assigned = false,
    this.assignedTo,
    this.canEditContact = false,
    this.canEditAmount = false,
    this.canRemove = false,
    this.canResendMail = false,
  });

  factory OrderBeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return OrderBeneficiaryModel(
      idQrcode: _intOrNull(json['id_qrcode']),
      amount: _num(json['amount']),
      remainingAmount: _num(json['remaining_amount']),
      expiryDate: json['expiry_date']?.toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      firstname: json['firstname']?.toString(),
      lastname: json['lastname']?.toString(),
      assigned: _bool(json['assigned']),
      assignedTo: json['assigned_to']?.toString(),
      canEditContact: _bool(json['can_edit_contact']),
      canEditAmount: _bool(json['can_edit_amount']),
      canRemove: _bool(json['can_remove']),
      canResendMail: _bool(json['can_resend_mail']),
    );
  }
}

/// Réponse de `PUT /order/{id}/beneficiaries`.
class BeneficiariesUpdateResult {
  final int updated;
  final int created;
  final int removed;
  final int mailsSent;
  final int mailsFailed;
  final int mailsSkipped;

  BeneficiariesUpdateResult({
    this.updated = 0,
    this.created = 0,
    this.removed = 0,
    this.mailsSent = 0,
    this.mailsFailed = 0,
    this.mailsSkipped = 0,
  });

  factory BeneficiariesUpdateResult.fromJson(Map<String, dynamic> json) {
    final dynamic mails = json['mails'];
    final Map<String, dynamic> mailsMap =
        mails is Map ? Map<String, dynamic>.from(mails) : {};
    return BeneficiariesUpdateResult(
      updated: _count(json['updated']),
      created: _count(json['created']),
      removed: _count(json['removed']),
      mailsSent: _count(mailsMap['sent']),
      mailsFailed: _count(mailsMap['failed']),
      mailsSkipped: _count(mailsMap['skipped']),
    );
  }
}

bool _bool(dynamic value) => value == true || value == 1 || value == '1';

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

int? _intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

int _count(dynamic value) {
  if (value is List) return value.length;
  return _intOrNull(value) ?? 0;
}
