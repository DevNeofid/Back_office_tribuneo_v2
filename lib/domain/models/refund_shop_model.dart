class RefundShopModel {
  String? transactionNumber;
  String? name;
  String? code;
  String? refundAmount;
  int? isEdited;
  String? createdDate;

  RefundShopModel(
      {this.refundAmount, this.transactionNumber, this.code, this.name, this.createdDate, this.isEdited});

  RefundShopModel.fromJson(Map<String, dynamic> json) {
    transactionNumber = json['transaction_number'];
    name = json['name'];
    code = json['code'];
    refundAmount = json['refund_amount'];
    isEdited = json['id_proofs_of_receipt'];
    createdDate = json['created_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['transaction_number'] = transactionNumber;
    data['name'] = name;
    data['code'] = code;
    data['refund_amount'] = refundAmount;
    data['id_proofs_of_receipt'] = isEdited;
    data['created_date'] = createdDate;
    return data;
  }
}