// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// // import address_model.dart
// import 'package:tribuneo_backoffice/domain/models/address_model.dart';
// //part 'adapters/partner_model.g.dart';

// @HiveType(typeId: 3)
// class EntityModel extends HiveObject {
//   @HiveField(0)
//   int? id;
//   @HiveField(1)
//   String? name;
//   @HiveField(2)
//   String? email;
//   @HiveField(3)
//   String? siret;
//   @HiveField(4)
//   String? phone;
//   @HiveField(5)
//   String? type;
//   @HiveField(6)
//   AddressModel? address;
//   @HiveField(7)
//   TabController? tabController;

//   EntityModel(
//     this.id,
//     this.name,
//     this.email,
//     this.siret,
//     this.phone,
//     this.type,
//     this.address,
//     this.tabController,
//   );

//   EntityModel.fromJson(Map<String, dynamic> json) {
//     // print("### DEBUG ### -> id ${json['id']}");
//     id = json['id'];
//     // print("### DEBUG ### -> name ${json['name']}");
//     name = json['name'];
//     // print("### DEBUG ### -> email ${json['email']}");
//     email = json['email'];
//     // print("### DEBUG ### -> siret ${json['siret']}");
//     siret = json['siret'];
//     // print("### DEBUG ### -> phone ${json['phone']}");
//     phone = json['phone'];
//     // print("### DEBUG ### -> entityType ${json['entityType']}");
//     type = json['type'];
//     // print("### DEBUG ### -> address ${json['address']}");
//     address = json['address'] != null
//         ? AddressModel.fromJson(json['address'])
//         : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['name'] = name;
//     data['email'] = email;
//     data['siret'] = siret;
//     data['phone'] = phone;
//     data['type'] = type;
//     if (address != null) {
//       data['address'] = address!.toJson();
//     }
//     return data;
//   }
// }
