class UserModel {
  int? id;
  String? firstname;
  String? lastname;
  String? email;
  String? mobile;
  DateTime? createdDate;
  DateTime? updatedDate;
  String? token;
  String? role;

  UserModel(
      {int? id,
      String? firstname,
      String? lastname,
      String? email,
      String? mobile,
      DateTime? createdDate,
      DateTime? updatedDate,
      String? token,
      String? role}) {
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
  }
}
