class TechnicalSupportOrderModel {
  String? orderNumber;
  String? name;
  String? totalByOrder;
  int? countQrcode;
  String? createdDate;

  TechnicalSupportOrderModel({
    this.orderNumber,
    this.name,
    this.totalByOrder,
    this.countQrcode,
    this.createdDate,
  });

  TechnicalSupportOrderModel.fromJson(Map<String, dynamic> json) {
    orderNumber = json['order_number']?.toString();
    name = json['name']?.toString();
    totalByOrder = json['total_by_order']?.toString();
    countQrcode = (json['count_qrcode'] as num?)?.toInt();
    createdDate = json['created_date']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'order_number': orderNumber,
      'name': name,
      'total_by_order': totalByOrder,
      'count_qrcode': countQrcode,
      'created_date': createdDate,
    };
  }
}
