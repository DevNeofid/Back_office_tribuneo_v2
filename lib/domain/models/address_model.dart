import 'package:hive/hive.dart';

//part 'adapters/Address_model.g.dart';

@HiveType(typeId: 5)
class AddressModel extends HiveObject {
  @HiveField(0)
  int? id;
  @HiveField(1)
  String? street;
  @HiveField(2)
  String? zip;
  @HiveField(3)
  String? city;
  @HiveField(4)
  String? country;
  @HiveField(5)
  num? lat;
  @HiveField(6)
  num? lng;
  @HiveField(7)
  int? idUser;
  @HiveField(8)
  int? idEntity;

  AddressModel(
    this.id,
    this.street,
    this.zip,
    this.city,
    this.country,
    this.lat,
    this.lng,
    this.idUser,
    this.idEntity,
  );

  AddressModel.fromJson(Map<String, dynamic> json) {
    // print("### DEBUG ### -> id ${json['id']}");
    id = json['id'];
    // print("### DEBUG ### -> street ${json['street']}");
    street = json['street'];
    // print("### DEBUG ### -> zip ${json['zip']}");
    zip = json['zip'];
    // print("### DEBUG ### -> city ${json['city']}");
    city = json['city'];
    // print("### DEBUG ### -> country ${json['country']}");
    country = json['country'];
    // print("### DEBUG ### -> lat ${json['lat']}");
    lat = json['lat'];
    // print("### DEBUG ### -> lon ${json['lon']}");
    lng = json['lng'];
    // print("### DEBUG ### -> id_user ${json['id_user']}");
    idUser = json['id_user'];
    // print("### DEBUG ### -> id_entity ${json['id_entity']}");
    idEntity = json['id_entity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['street'] = street;
    data['zip'] = zip;
    data['city'] = city;
    data['country'] = country;
    data['lat'] = lat;
    data['lng'] = lng;
    data['id_user'] = idUser;
    data['id_entity'] = idEntity;
    return data;
  }
}
