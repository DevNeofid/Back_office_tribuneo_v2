class PartnerDigitalNeverOpenSessionModel {
  String? name;
  String? email;
  String? phone;
  String? withQrCode;

  PartnerDigitalNeverOpenSessionModel({
    this.name,
    this.email,
    this.phone,
    this.withQrCode,
  });

  PartnerDigitalNeverOpenSessionModel.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    email = json['email']?.toString();
    phone = json['phone']?.toString();
    withQrCode = json['with_qr_code_first_login']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'with_qr_code_first_login': withQrCode,
    };
  }
}
