class DigitalPartnerNoActivityModel {
  String? name;
  int? id;
  String? email;
  String? phone;

  DigitalPartnerNoActivityModel({
    this.name,
    this.id,
    this.email,
    this.phone,
  });

  DigitalPartnerNoActivityModel.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    id = (json['id'] as num?)?.toInt();
    email = json['email']?.toString();
    phone = json['phone']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'email': email,
      'phone': phone,
    };
  }
}
