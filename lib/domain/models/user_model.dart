import 'package:hive/hive.dart';

part 'adapters/user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  int? id;
  @HiveField(1)
  String? firstname;
  @HiveField(2)
  String? lastname;
  @HiveField(3)
  String? email;
  @HiveField(4)
  String? mobile;
  @HiveField(5)
  DateTime? createdDate;
  @HiveField(6)
  DateTime? updatedDate;
  @HiveField(7)
  String? token;
  @HiveField(8)
  String? role;
  @HiveField(9)
  int? idNetwork;

  UserModel(
      {int? id,
      String? firstname,
      String? lastname,
      String? email,
      String? mobile,
      DateTime? createdDate,
      DateTime? updatedDate,
      String? token,
      String? role,
      int? idNetwork}) {
    if (id != null) {
      id = id;
    }
    if (firstname != null) {
      firstname = firstname;
    }
    if (lastname != null) {
      lastname = lastname;
    }
    if (email != null) {
      email = email;
    }
    if (mobile != null) {
      mobile = mobile;
    }
    if (createdDate != null) {
      createdDate = createdDate;
    }
    if (updatedDate != null) {
      updatedDate = updatedDate;
    }
    if (token != null) {
      token = token;
    }
    if (role != null) {
      role = role;
    }
    if (idNetwork != null) {
      idNetwork = idNetwork;
    }
  }

  UserModel.fromJson(Map<String, dynamic> jsonData) {
    id = jsonData['id'];
    firstname = jsonData['firstname'];
    lastname = jsonData['lastname'];
    email = jsonData['email'];
    mobile = jsonData['mobile'];
    createdDate = jsonData['created_date'] != null
        ? DateTime.parse(jsonData['created_date']['date'].toString())
        : null;
    updatedDate = jsonData['updated_date'] != null
        ? DateTime.parse(jsonData['updated_date']['date'].toString())
        : null;
    token = jsonData['token'];
    role = jsonData['role'];
    idNetwork = jsonData['id_network'];
  }
}
