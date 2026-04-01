class PartnerAccountModel {
  String? code;
  String? name;
  int? id;
  String? mobile;
  String? username;
  String? firstname;
  String? lastname;
  String? email;
  bool? completed;

  PartnerAccountModel(
      {this.code,
      this.name,
      this.id,
      this.mobile,
      this.username,
      this.firstname,
      this.lastname,
      this.email,
      this.completed});

  PartnerAccountModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
    id = json['id'];
    mobile = json['mobile'];
    username = json['username'];
    firstname = json['firstname'];
    lastname = json['lastname'];
    email = json['email'];
    completed = json['completed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = code;
    data['name'] = name;
    data['id'] = id;
    data['mobile'] = mobile;
    data['username'] = username;
    data['firstname'] = firstname;
    data['lastname'] = lastname;
    data['email'] = email;
    data['completed'] = completed;
    return data;
  }
}
