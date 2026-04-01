class PartnerActivatedSinceModel {
  String? code;
  String? name;
  String? city;
  String? updatedDate;

  PartnerActivatedSinceModel(
      {this.code, this.name, this.city, this.updatedDate});

  PartnerActivatedSinceModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
    city = json['city'];
    updatedDate = json['updated_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = code;
    data['name'] = name;
    data['city'] = city;
    data['updated_date'] = updatedDate;
    return data;
  }
}
