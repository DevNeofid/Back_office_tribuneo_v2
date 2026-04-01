class DataToEncode {
  int? senderId;
  int? receiverId;
  int? senderFundId;
  String? receiverFundId;
  int? amount;
  String? type;
  int? fundGroupId;
  String? expiryDate;
  String? shopId;
  String? firstname;

  DataToEncode(
      {this.senderId,
      this.receiverId,
      this.senderFundId,
      this.receiverFundId,
      this.amount,
      this.type,
      this.fundGroupId,
      this.expiryDate,
      this.shopId,
      this.firstname});

  DataToEncode.fromJson(Map<String, dynamic> json) {
    senderId = json['sender_id'];
    receiverId = json['receiver_id'];
    senderFundId = json['sender_fund_id'];
    receiverFundId = json['receiver_fund_id'];
    amount = json['amount'];
    type = json['type'];
    fundGroupId = json['fund_group_id'];
    expiryDate = json['expiry_date'];
    shopId = json['shop_id'];
    firstname = json['firstname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sender_id'] = senderId;
    data['receiver_id'] = receiverId;
    data['sender_fund_id'] = senderFundId;
    data['receiver_fund_id'] = receiverFundId;
    data['amount'] = amount;
    data['type'] = type;
    data['fund_group_id'] = fundGroupId;
    data['expiry_date'] = expiryDate;
    data['shop_id'] = shopId;
    data['firstname'] = firstname;
    return data;
  }
  
  Map<String, dynamic> removeValue(String key) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data.remove(key);
    return data;
  }

  
}