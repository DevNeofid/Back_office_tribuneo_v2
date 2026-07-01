class AllInfosPartnerModel {
  String? code;
  String? name;
  String? email;
  String? siret;
  String? phone;
  String? acceptDemat;
  String? street;
  String? zip;
  String? city;
  String? country;
  String? iban;
  String? bic;
  String? intracommunityVatNumber;
  String? nafCode;
  String? accountingNumber;
  String? amount;

  AllInfosPartnerModel({
    this.code,
    this.name,
    this.email,
    this.siret,
    this.phone,
    this.acceptDemat,
    this.street,
    this.zip,
    this.city,
    this.country,
    this.iban,
    this.bic,
    this.intracommunityVatNumber,
    this.nafCode,
    this.accountingNumber,
    this.amount,
  });

  AllInfosPartnerModel.fromJson(Map<String, dynamic> json) {
    code = json['code']?.toString();
    name = json['name']?.toString();
    email = json['email']?.toString();
    siret = json['siret']?.toString();
    phone = json['phone']?.toString();
    acceptDemat = json['accept_demat']?.toString();
    street = json['street']?.toString();
    zip = json['zip']?.toString();
    city = json['city']?.toString();
    country = json['country']?.toString();
    iban = json['iban']?.toString();
    bic = json['bic']?.toString();
    intracommunityVatNumber = json['intracommunity_vat_number']?.toString();
    nafCode = json['naf_code']?.toString();
    accountingNumber = json['accounting_number']?.toString();
    amount = json['amount']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'email': email,
      'siret': siret,
      'phone': phone,
      'accept_demat': acceptDemat,
      'street': street,
      'zip': zip,
      'city': city,
      'country': country,
      'iban': iban,
      'bic': bic,
      'intracommunity_vat_number': intracommunityVatNumber,
      'naf_code': nafCode,
      'accounting_number': accountingNumber,
      'amount': amount,
    };
  }
}
