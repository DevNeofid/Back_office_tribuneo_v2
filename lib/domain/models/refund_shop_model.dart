class RefundShopModel {
  String? refundAmount;
  int? id;
  String? code;
  String? name;
  String? transactionNumber;
  String? createdDate;
  int? isEdited;

  RefundShopModel(
      {this.refundAmount,
      this.id,
      this.code,
      this.name,
      this.transactionNumber,
      this.createdDate,
      this.isEdited});

  RefundShopModel.fromJson(Map<String, dynamic> json) {
    refundAmount = json['refund_amount'];
    id = json['id'];
    code = json['code'];
    name = json['name'];
    transactionNumber = json['transaction_number'];
    createdDate = json['created_date'];
    isEdited = json['proof_of_receipt_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['refund_amount'] = refundAmount;
    data['id'] = id;
    data['code'] = code;
    data['name'] = name;
    data['transaction_number'] = transactionNumber;
    data['created_date'] = createdDate;
    data['proof_of_receipt_id'] = isEdited;
    return data;
  }
}
