class PaymentModel {
  int? id;
  int? idEntity;
  int? idOrder;
  num? amount;
  int? idPaymentMethod;
  DateTime? createdDate;
  DateTime? paymentDate;
  DateTime? updatedDate;

  PaymentModel(
      {this.id,
      this.idEntity,
      this.idOrder,
      this.amount,
      this.idPaymentMethod,
      this.createdDate,
      this.paymentDate,
      this.updatedDate});

  PaymentModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idEntity = json['id_entity'];
    idOrder = json['id_order'];
    amount = json['amount'];
    idPaymentMethod = json['id_payment_method'];
    createdDate = _parseDate(json['created_date']);
    paymentDate = _parseDate(json['payment_date']);
    updatedDate = _parseDate(json['updated_date']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['id_entity'] = idEntity;
    data['id_order'] = idOrder;
    data['amount'] = amount;
    data['id_payment_method'] = idPaymentMethod;
    if (createdDate != null) {
      data['created_date'] = createdDate!.toIso8601String();
    }
    if (paymentDate != null) {
      data['payment_date'] = paymentDate!.toIso8601String();
    }
    if (updatedDate != null) {
      data['updated_date'] = updatedDate!.toIso8601String();
    }
    return data;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is Map<String, dynamic> && value.containsKey('date')) {
      return DateTime.tryParse(value['date'].toString());
    }
    return null;
  }
}
