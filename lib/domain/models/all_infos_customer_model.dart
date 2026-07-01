class AllInfosCustomerModel {
  String? code;
  String? name;
  String? email;
  String? siret;
  String? phone;
  String? street;
  String? zip;
  String? city;
  String? country;
  String? intracommunityVatNumber;
  String? nafCode;
  String? accountingNumber;

  AllInfosCustomerModel({
    this.code,
    this.name,
    this.email,
    this.siret,
    this.phone,
    this.street,
    this.zip,
    this.city,
    this.country,
    this.intracommunityVatNumber,
    this.nafCode,
    this.accountingNumber,
  });

  AllInfosCustomerModel.fromJson(Map<String, dynamic> json) {
    code = json['code']?.toString();
    name = json['name']?.toString();
    email = json['email']?.toString();
    siret = json['siret']?.toString();
    phone = json['phone']?.toString();
    street = json['street']?.toString();
    zip = json['zip']?.toString();
    city = json['city']?.toString();
    country = json['country']?.toString();
    intracommunityVatNumber = json['intracommunity_vat_number']?.toString();
    nafCode = json['naf_code']?.toString();
    accountingNumber = json['accounting_number']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'email': email,
      'siret': siret,
      'phone': phone,
      'street': street,
      'zip': zip,
      'city': city,
      'country': country,
      'intracommunity_vat_number': intracommunityVatNumber,
      'naf_code': nafCode,
      'accounting_number': accountingNumber,
    };
  }
}
