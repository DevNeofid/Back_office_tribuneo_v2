import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/models/address_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/bank_informations_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/sector_model.dart';

class EntityModel {
  int? id;
  String? name;
  String? email;
  String? siret;
  String? code;
  String? phone;
  String? type;
  String? username;
  num? fundAmount;
  bool? acceptDemat;
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
    this.username,
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
    //print("### DEBUG ### -> username ${json['username']}");
    username = json['username'];
    //print("### DEBUG ### -> address ${json['address']}");
    acceptDemat = json['accept_demat'];
    //print("### DEBUG ### -> accept_demat ${json['accept_demat']}");
    address =
        json['address'] != null ? AddressModel.fromJson(json['address']) : null;
    bankInformations = json['bank_informations'] != null
        ? BankInformationsModel.fromJson(json['bank_informations'])
        : null;
    activitySectors = json['activity_sectors'] != null
        ? (json['activity_sectors'] as List)
            .map((sectorJson) => Sector.fromJson(sectorJson))
            .toList()
        : [];
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
    data['accept_demat'] = acceptDemat == true ? 1 : 0;
    if (address != null) {
      data['address'] = address!.toJson();
    }
    if (bankInformations != null) {
      data['bank_informations'] = bankInformations!.toJson();
    }
    if (activitySectors != null) {
      data['activity_sectors'] =
          activitySectors!.map((sector) => sector.toJson()).toList();
    }
    return data;
  }
}
