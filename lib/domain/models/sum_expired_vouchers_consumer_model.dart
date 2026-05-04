class SumExpiredVouchersConsumerModel {
  String? name;
  int? expiredVouchers;
  String? unredeemendAmount;

  SumExpiredVouchersConsumerModel({
    this.name,
    this.expiredVouchers,
    this.unredeemendAmount,
  });

  SumExpiredVouchersConsumerModel.fromJson(Map<String, dynamic> json) {
    name = json['name_customer']?.toString();
    expiredVouchers = (json['count_expired_vouchers'] as num?)?.toInt();
    unredeemendAmount = json['total_unredeemed_amount']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'name_customer': name,
      'count_expired_vouchers': expiredVouchers,
      'total_unredeemed_amount': unredeemendAmount,
    };
  }
}
