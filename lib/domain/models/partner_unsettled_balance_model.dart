class PartnerUnsettledBalanceModel {
  String? code;
  String? name;
  String? city;
  double? amount;

  PartnerUnsettledBalanceModel({this.code, this.name, this.city, this.amount});

  PartnerUnsettledBalanceModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
    city = json['city'];
    amount = json['amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = code;
    data['name'] = name;
    data['city'] = city;
    data['amount'] = amount;
    return data;
  }
}
