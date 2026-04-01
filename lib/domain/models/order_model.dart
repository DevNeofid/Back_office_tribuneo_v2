
class OrderRecModel {
  int? id;
  String? orderNumber;
  String? giftFrom;
  String? giftReason;
  int? idUrssaf;
  int? fundQuantity;
  num? totalAmount;
  int? paid;
  int? idEntity;
  List<OrderRecItems>? orderItems;
  FundDate? fundExpiryDate;
  FundDate? createdDate;
  FundDate? updatedDate;

  OrderRecModel(
      {this.id,
      this.orderNumber,
      this.giftFrom,
      this.giftReason,
      this.idUrssaf,
      this.fundQuantity,
      this.totalAmount,
      this.paid,
      this.idEntity,
      this.orderItems,
      this.fundExpiryDate,
      this.createdDate,
      this.updatedDate});

  OrderRecModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderNumber = json['order_number'];
    giftFrom = json['gift_from'];
    giftReason = json['gift_reason'];
    idUrssaf = json['id_urssaf_event'];
    fundQuantity = json['fund_quantity'];
    totalAmount = json['total_amount'];
    paid = json['amount_paid'] ?? 0;
    idEntity = json['id_entity'];
    if (json['order_items'] != null) {
      orderItems = <OrderRecItems>[];
      json['order_items'].forEach((v) {
        orderItems!.add(OrderRecItems.fromJson(v));
      });
    }
    fundExpiryDate = json['fund_expiry_date'] != null
        ? FundDate.fromJson(json['fund_expiry_date'])
        : null;
    createdDate = json['created_date'] != null
        ? FundDate.fromJson(json['created_date'])
        : null;
    updatedDate = json['updated_date'] != null
        ? FundDate.fromJson(json['updated_date'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_number'] = orderNumber;
    data['gift_from'] = giftFrom;
    data['gift_reason'] = giftReason;
    data['id_urssaf_event'] = idUrssaf;
    data['fund_quantity'] = fundQuantity;
    data['total_amount'] = totalAmount;
    data['amount_paid'] = paid;
    data['id_entity'] = idEntity;
    if (orderItems != null) {
      data['order_items'] = orderItems!.map((v) => v.toJson()).toList();
    }
    if (fundExpiryDate != null) {
      data['fund_expiry_date'] = fundExpiryDate!.toJson();
    }
    if (createdDate != null) {
      data['created_date'] = createdDate!.toJson();
    }
    if (updatedDate != null) {
      data['updated_date'] = updatedDate!.toJson();
    }
    return data;
  }
}

class OrderRecItems {
  int? id;
  int? quantity;
  num? amount;
  String? persoMsg;
  int? idOrder;

  OrderRecItems({this.id, this.quantity, this.amount, this.idOrder});

  OrderRecItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    quantity = json['quantity'];
    amount = json['amount'];
    persoMsg = json['perso_msg'];
    idOrder = json['id_order'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['quantity'] = quantity;
    data['amount'] = amount;
    data['perso_msg'] = persoMsg;
    data['id_order'] = idOrder;
    return data;
  }
}

class FundDate {
  String? date;
  int? timezoneType;
  String? timezone;

  FundDate({this.date, this.timezoneType, this.timezone});

  FundDate.fromJson(Map<String, dynamic> json) {
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

class OrderSendModel {
  int? id;
  String? giftFrom;
  int? idUrssaf;
  String? giftReason;
  int? fundQuantity;
  String? fundExpiryDate;
  List<OrderSendItems>? orderItems;
  int? idEntity;

  OrderSendModel(
      {this.id,
      this.giftFrom,
      this.idUrssaf,
      this.giftReason,
      this.fundQuantity,
      this.fundExpiryDate,
      this.orderItems,
      this.idEntity});

  OrderSendModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    giftFrom = json['gift_from'];
    idUrssaf = json['id_urssaf_event'];
    giftReason = json['gift_reason'];
    fundQuantity = json['fund_quantity'];
    fundExpiryDate = json['fund_expiry_date'];
    if (json['order_items'] != null) {
      orderItems = <OrderSendItems>[];
      json['order_items'].forEach((v) {
        orderItems!.add(OrderSendItems.fromJson(v));
      });
    }
    idEntity = json['id_entity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['gift_from'] = giftFrom;
    data['id_urssaf_event'] = idUrssaf;
    data['gift_reason'] = giftReason;
    data['fund_quantity'] = fundQuantity;
    data['fund_expiry_date'] = fundExpiryDate;
    if (orderItems != null) {
      data['order_items'] = orderItems!.map((v) => v.toJson()).toList();
    }
    data['id_entity'] = idEntity;
    return data;
  }
}

class OrderSendItems {
  int? amount;
  int? quantity;
  String? persoMsg;

  OrderSendItems({this.amount, this.quantity, this.persoMsg});

  OrderSendItems.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    quantity = json['quantity'];
    persoMsg = json['perso_msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['quantity'] = quantity;
    data['perso_msg'] = persoMsg;
    return data;
  }
}
