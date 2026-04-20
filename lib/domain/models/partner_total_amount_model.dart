class PartnerTotalAmountModel {
  String? name;
  double? totalAmount;

  PartnerTotalAmountModel({
    this.name,
    this.totalAmount,
  });

  factory PartnerTotalAmountModel.fromJson(Map<String, dynamic> json) {
    final dynamic amountValue = json['total_amount'];
    return PartnerTotalAmountModel(
      name: json['name'] as String?,
      totalAmount: amountValue == null
          ? null
          : amountValue is num
              ? amountValue.toDouble()
              : double.tryParse(amountValue.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'total_amount': totalAmount,
    };
  }
}
