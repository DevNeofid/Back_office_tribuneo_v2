class OrderVoucherModel {
  int? id;
  num? amount;
  num? remainingAmount;
  int? isDonation;
  String? name;
  String? email;
  String? mobile;
  String? expiryDate;
  String? deletedDate;

  OrderVoucherModel(
      {this.id,
      this.amount,
      this.remainingAmount,
      this.isDonation,
      this.name,
      this.email,
      this.mobile,
      this.expiryDate,
      this.deletedDate});

  OrderVoucherModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    amount = _parseAmount(json['amount']);
    remainingAmount = _parseAmount(json['remaining_amount']);
    isDonation = json['is_donation'];
    name = json['name'];
    email = json['email'];
    mobile = json['mobile'];
    expiryDate = json['expiry_date'];
    deletedDate = json['deleted_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['amount'] = amount;
    data['remaining_amount'] = remainingAmount;
    data['is_donation'] = isDonation;
    data['name'] = name;
    data['email'] = email;
    data['mobile'] = mobile;
    data['expiry_date'] = expiryDate;
    data['deleted_date'] = deletedDate;
    return data;
  }

  num? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  /// Le bon est associé à un utilisateur (nom, email ou téléphone renseigné).
  bool get hasUser =>
      (name?.trim().isNotEmpty ?? false) ||
      (email?.trim().isNotEmpty ?? false) ||
      (mobile?.trim().isNotEmpty ?? false);

  bool get isDeleted => deletedDate != null && deletedDate!.trim().isNotEmpty;
}
