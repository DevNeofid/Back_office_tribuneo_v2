class BankInformationsModel {
  int? id;
  String? iban;
  String? bic;
  String? key;
  String? bankCode;
  String? officeCode;
  String? accountNumber;
  String? accountingNumber;
  String? intraCommunityVat;
  int? idEntity;

  BankInformationsModel(
      {this.id,
      this.iban,
      this.bic,
      this.key,
      this.bankCode,
      this.officeCode,
      this.accountNumber,
      this.accountingNumber,
      this.intraCommunityVat,
      this.idEntity});

  BankInformationsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    iban = json['iban'];
    bic = json['bic'];
    key = json['key'];
    bankCode = json['bank_code'];
    officeCode = json['office_code'];
    accountNumber = json['account_number'];
    accountingNumber = json['accounting_number'];
    intraCommunityVat = json['intracommunity_vat_number'];
    idEntity = json['id_entity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['iban'] = iban;
    data['bic'] = bic;
    data['key'] = key;
    data['bank_code'] = bankCode;
    data['office_code'] = officeCode;
    data['account_number'] = accountNumber;
    data['accounting_number'] = accountingNumber;
    data['intracommunity_vat_number'] = intraCommunityVat;
    data['id_entity'] = idEntity;
    return data;
  }
}
