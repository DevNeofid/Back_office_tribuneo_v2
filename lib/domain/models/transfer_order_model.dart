class TransferOrderModel {
  int? id;
  String? filename;
  double? retainedAmount;
  double? refundedAmount;
  String? createdDate;

  TransferOrderModel(
      {this.id,
      this.filename,
      this.retainedAmount,
      this.refundedAmount,
      this.createdDate});

  TransferOrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    filename = json['filename'];
    retainedAmount = json['retained_amount'];
    refundedAmount = json['refunded_amount'];
    createdDate = json['created_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['filename'] = filename;
    data['retained_amount'] = retainedAmount;
    data['refunded_amount'] = refundedAmount;
    data['created_date'] = createdDate;
    return data;
  }
}