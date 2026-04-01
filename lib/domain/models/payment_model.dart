class PaymentModel {
  int? id;
  int? idEntity;
  int? idOrder;
  num? amount;
  int? idPaymentMethod;
  String? paymentMethod;
  Date? createdDate;
  Date? paymentDate;
  Date? updatedDate;

  PaymentModel(
      {this.id,
      this.idEntity,
      this.idOrder,
      this.amount,
      this.idPaymentMethod,
      this.paymentMethod,
      this.createdDate,
      this.updatedDate});

  PaymentModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idEntity = json['id_entity'];
    idOrder = json['id_order'];
    amount = json['amount'];
    idPaymentMethod = json['id_payment_method'];
    paymentMethod = json['payment_method'];
    createdDate = json['created_date'] != null
        ? Date.fromJson(json['created_date'])
        : null;
    paymentDate = json['payment_date'] != null
        ? Date.fromJson(json['payment_date'])
        : null;
    updatedDate = json['updated_date'] != null
        ? Date.fromJson(json['updated_date'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['id_entity'] = idEntity;
    data['id_order'] = idOrder;
    data['amount'] = amount;
    data['id_payment_method'] = idPaymentMethod;
    data['payment_method'] = paymentMethod;
    if (createdDate != null) {
      data['created_date'] = createdDate!.toJson();
    }
    if (paymentDate != null) {
      data['payment_date'] = paymentDate!.toJson();
    }
    if (updatedDate != null) {
      data['updated_date'] = updatedDate!.toJson();
    }
    return data;
  }
}

class Date {
  String? date;
  int? timezoneType;
  String? timezone;

  Date({this.date, this.timezoneType, this.timezone});

  Date.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    timezoneType = json['timezone_type'];
    timezone = json['timezone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['timezone_type'] = timezoneType;
    data['timezone'] = timezone;
    return data;
  }
}