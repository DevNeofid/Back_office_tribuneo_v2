class LoginResponseModel {
  String? error;

  LoginResponseModel({this.error});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(error: json["error"]);
  }
}

class LoginRequestModel {
  String? username;
  String? password;

  LoginRequestModel({required this.username, required this.password});

  LoginRequestModel.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['username'] = username;
    data['password'] = password;
    return data;
  }
}
