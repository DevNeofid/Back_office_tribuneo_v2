class InvoiceModel {
  int? id;
  String? invoiceNumber;
  num? totalAmountInvoice;
  num? totalAmountPaid;
  String? entityName;
  String? entityCode;
  int? idOrder;
  int? idProofOfReceipt;
  String? orderNumber;
  num? orderTotalAmount;
  Date? orderExpirationDate;
  String? giftFrom;
  String? giftReason;
  String? proofOfReceiptNumber;
  num? totalExcl;
  num? totalVat;
  num? totalInclVat;
  num? vatRate;
  num? feesExcl;
  num? feesVatAmount;
  num? feesInclVat;
  num? totalPayable;
  int? idTransaction;
  String? transactionNumber;
  Date? transactionDate;
  Date? createdDate;

  InvoiceModel(
      {this.id,
      this.invoiceNumber,
      this.totalAmountInvoice,
      this.totalAmountPaid,
      this.entityName,
      this.entityCode,
      this.idOrder,
      this.idProofOfReceipt,
      this.orderNumber,
      this.orderTotalAmount,
      this.orderExpirationDate,
      this.giftFrom,
      this.giftReason,
      this.proofOfReceiptNumber,
      this.totalExcl,
      this.totalVat,
      this.totalInclVat,
      this.vatRate,
      this.feesExcl,
      this.feesVatAmount,
      this.feesInclVat,
      this.totalPayable,
      this.idTransaction,
      this.transactionNumber,
      this.transactionDate,
      this.createdDate});

  InvoiceModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    invoiceNumber = json['invoice_number'];
    totalAmountInvoice = json['total_amount_invoice'];
    totalAmountPaid = json['total_amount_paid'];
    entityName = json['entity_name'];
    entityCode = json['entity_code'];
    idOrder = json['id_order'];
    idProofOfReceipt = json['id_proof_of_receipt'];
    orderNumber = json['order_number'];
    orderTotalAmount = json['order_total_amount'];
    orderExpirationDate = json['order_expiration_date'] != null
        ? Date.fromJson(json['order_expiration_date'])
        : null;
    giftFrom = json['gift_from'];
    giftReason = json['gift_reason'];
    proofOfReceiptNumber = json['proof_of_receipt_number'];
    totalExcl = json['total_excl'];
    totalVat = json['total_vat'];
    totalInclVat = json['total_incl_vat'];
    vatRate = json['vat_rate'];
    feesExcl = json['fees_excl'];
    feesVatAmount = json['fees_vat_amount'];
    feesInclVat = json['fees_incl_vat'];
    totalPayable = json['total_payable'];
    idTransaction = json['id_transaction'];
    transactionNumber = json['transaction_number'];
    transactionDate = json['transaction_date'] != null
        ? Date.fromJson(json['transaction_date'])
        : null;
    createdDate = json['created_date'] != null
        ? Date.fromJson(json['created_date'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['invoice_number'] = invoiceNumber;
    data['total_amount_invoice'] = totalAmountInvoice;
    data['total_amount_paid'] = totalAmountPaid;
    data['entity_name'] = entityName;
    data['entity_code'] = entityCode;
    data['id_order'] = idOrder;
    data['id_proof_of_receipt'] = idProofOfReceipt;
    data['order_number'] = orderNumber;
    data['order_total_amount'] = orderTotalAmount;
    if (orderExpirationDate != null) {
      data['order_expiration_date'] = orderExpirationDate!.toJson();
    }
    data['gift_from'] = giftFrom;
    data['gift_reason'] = giftReason;
    data['proof_of_receipt_number'] = proofOfReceiptNumber;
    data['total_excl'] = totalExcl;
    data['total_vat'] = totalVat;
    data['total_incl_vat'] = totalInclVat;
    data['vat_rate'] = vatRate;
    data['fees_excl'] = feesExcl;
    data['fees_vat_amount'] = feesVatAmount;
    data['fees_incl_vat'] = feesInclVat;
    data['total_payable'] = totalPayable;
    data['id_transaction'] = idTransaction;
    data['transaction_number'] = transactionNumber;
    if (transactionDate != null) {
      data['transaction_date'] = transactionDate;
    }
    if (createdDate != null) {
      data['created_date'] = createdDate!.toJson();
    }
    return data;
  }
}

class OrderItems {
  int? id;
  int? quantity;
  int? amount;
  int? idOrder;
  String? persoMsg;

  OrderItems(
      {this.id, this.quantity, this.amount, this.idOrder, this.persoMsg});

  OrderItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    quantity = json['quantity'];
    amount = json['amount'];
    idOrder = json['id_order'];
    persoMsg = json['perso_msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['quantity'] = quantity;
    data['amount'] = amount;
    data['id_order'] = idOrder;
    data['perso_msg'] = persoMsg;
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
