import 'package:flutter/material.dart';
import 'package:tribuneo_backoffice/domain/models/address_model.dart';
import 'package:tribuneo_backoffice/domain/models/bank_informations_model.dart';
import 'package:tribuneo_backoffice/domain/models/sector_model.dart';

class EntityModel {
  int? id;
  String? name;
  String? email;
  String? siret;
  String? code;
  String? phone;
  String? type;
  num? fundAmount;
  int? acceptDemat;
  AddressModel? address;
  BankInformationsModel? bankInformations;
  List<Sector>? activitySectors;
  TabController? tabController;

  EntityModel(
    this.id,
    this.name,
    this.email,
    this.siret,
    this.code,
    this.phone,
    this.type,
    this.fundAmount,
    this.acceptDemat,
    this.address,
    this.bankInformations,
    this.activitySectors,
    this.tabController,
  );

  EntityModel.fromJson(Map<String, dynamic> json) {
    //print("### DEBUG ### -> id ${json['id']}");
    id = json['id'];
    //print("### DEBUG ### -> name ${json['name']}");
    name = json['name'];
    //print("### DEBUG ### -> email ${json['email']}");
    email = json['email'];
    //print("### DEBUG ### -> siret ${json['siret']}");
    siret = json['siret'];
    //print("### DEBUG ### -> phone ${json['phone']}");
    code = json['code'];
    //print("### DEBUG ### -> phone ${json['phone']}");
    phone = json['phone'];
    //print("### DEBUG ### -> entityType ${json['entityType']}");
    type = json['type'];
    //print("### DEBUG ### -> fundAmount ${json['fundAmount']}");
    fundAmount = json['fund_amount'];
    //print("### DEBUG ### -> address ${json['address']}");
    acceptDemat = json['accept_demat'];
    //print("### DEBUG ### -> bankInformations ${json['bankInformations']}");
    address = json['address'] != null
        ? AddressModel.fromJson(json['address'])
        : null;
    bankInformations = json['bankInformations'] != null
        ? BankInformationsModel.fromJson(json['bankInformations'])
        : null;
    activitySectors = json['activitySectors'] != null
        ? (json['activitySectors'] as List)
            .map((sectorJson) => Sector.fromJson(sectorJson))
            .toList()
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['siret'] = siret;
    data['code'] = code;
    data['phone'] = phone;
    data['type'] = type;
    data['fund_amount'] = fundAmount;
    data['accept_demat'] = acceptDemat;
    if (address != null) {
      data['address'] = address!.toJson();
    }
    if (bankInformations != null) {
      data['bankInformations'] = bankInformations!.toJson();
    }
    if (activitySectors != null) {
      data['activitySectors'] = activitySectors!.map((sector) => sector.toJson()).toList();
    }
    return data;
  }
}
