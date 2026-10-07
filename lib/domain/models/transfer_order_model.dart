class TransferOrderModel {
  int? id;
  String? filename;
  double? retainedAmount;
  double? refundedAmount;

  /// Compte payeur. `null` sur les ordres antérieurs aux comptes multiples.
  String? bankAccountCode;
  String? createdDate;

  TransferOrderModel(
      {this.id,
      this.filename,
      this.retainedAmount,
      this.refundedAmount,
      this.bankAccountCode,
      this.createdDate});

  TransferOrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    filename = json['filename'];
    retainedAmount = json['retained_amount'];
    refundedAmount = json['refunded_amount'];
    bankAccountCode = json['bank_account_code']?.toString();
    createdDate = json['created_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['filename'] = filename;
    data['retained_amount'] = retainedAmount;
    data['refunded_amount'] = refundedAmount;
    data['bank_account_code'] = bankAccountCode;
    data['created_date'] = createdDate;
    return data;
  }
}
