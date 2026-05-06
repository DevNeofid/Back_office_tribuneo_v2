class VoucherTotalBalancePerCustomerModel {
  String? name;
  String? amount;
  String? expirationDate;

  VoucherTotalBalancePerCustomerModel({
    this.name,
    this.amount,
    this.expirationDate,
  });

  VoucherTotalBalancePerCustomerModel.fromJson(Map<String, dynamic> json) {
    name = json['name_customer']?.toString();
    amount = json['global_balance_as_date']?.toString();
    expirationDate = json['expiry_date']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'name_customer': name,
      'global_balance_as_date': amount,
      'expiry_date': expirationDate,
    };
  }
}
