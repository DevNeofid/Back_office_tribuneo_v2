class QrCodeStatusByUserModel {
  String? qrCodeIdentifier;
  String? orderNumber;
  num? amount;
  num? remainingAmount;
  bool isDonation;
  String? expiryDate;
  String? email;
  String? firstname;
  String? lastname;
  String? mobile;

  QrCodeStatusByUserModel({
    this.qrCodeIdentifier,
    this.orderNumber,
    this.amount,
    this.remainingAmount,
    this.isDonation = false,
    this.expiryDate,
    this.email,
    this.firstname,
    this.lastname,
    this.mobile,
  });

  QrCodeStatusByUserModel.fromJson(Map<String, dynamic> json)
      : isDonation = _parseBool(json['is_donation']) {
    qrCodeIdentifier = json['qr_code_identifier']?.toString();
    orderNumber = json['order_number']?.toString();
    amount = _parseAmount(json['amount']);
    remainingAmount = _parseAmount(json['remaining_amount']);
    expiryDate = json['expiry_date']?.toString();
    email = json['email']?.toString();
    firstname = json['firstname']?.toString();
    lastname = json['lastname']?.toString();
    mobile = json['mobile']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'qr_code_identifier': qrCodeIdentifier,
      'order_number': orderNumber,
      'amount': amount,
      'remaining_amount': remainingAmount,
      'is_donation': isDonation,
      'expiry_date': expiryDate,
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'mobile': mobile,
    };
  }

  static num? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String normalized = value.toString().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'oui';
  }
}
