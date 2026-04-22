class NetworkTotalAmountModel {
  final double managementFees;
  final int injectedTotalAmount;
  final String expiredGainTotal;

  NetworkTotalAmountModel(
      {required this.managementFees,
      required this.injectedTotalAmount,
      required this.expiredGainTotal});

  factory NetworkTotalAmountModel.fromJson(Map<String, dynamic> json) {
    return NetworkTotalAmountModel(
      managementFees: json['management_fees'],
      injectedTotalAmount: json['injected_total_amount'],
      expiredGainTotal: json['expired_gain_total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'management_fees': managementFees,
      'injected_total_amount': injectedTotalAmount,
      'expired_gain_total': expiredGainTotal,
    };
  }
}
