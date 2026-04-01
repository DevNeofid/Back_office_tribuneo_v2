class UserBalanceModel {
  String? mobile;
  String? initials;
  num? amount;

  UserBalanceModel({this.mobile, this.initials, this.amount});

  UserBalanceModel.fromJson(Map<String, dynamic> json) {
    mobile = json['mobile'];
    initials = json['initials'];
    amount = json['amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mobile'] = mobile;
    data['initials'] = initials;
    data['amount'] = amount;
    return data;
  }
}