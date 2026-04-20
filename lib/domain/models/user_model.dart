class UserModel {
  int? id;
  int? idNetwork;
  String? firstname;
  String? lastname;
  String? email;
  String? mobile;
  CreatedDate? createdDate;
  CreatedDate? updatedDate;
  String? role;

  UserModel({
    this.id,
    this.idNetwork,
    this.firstname,
    this.lastname,
    this.email,
    this.mobile,
    this.createdDate,
    this.updatedDate,
    this.role,
  });

  UserModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        idNetwork = json['id_network'],
        firstname = json['firstname'],
        lastname = json['lastname'],
        email = json['email'],
        mobile = json['mobile'],
        createdDate = _parseCreatedDate(json['created_date']),
        updatedDate = _parseCreatedDate(json['updated_date']),
        role = json['role'];

  static CreatedDate? _parseCreatedDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map<String, dynamic>) {
      return CreatedDate.fromJson(value);
    }

    if (value is Map) {
      return CreatedDate.fromJson(Map<String, dynamic>.from(value));
    }

    if (value is String) {
      return CreatedDate(date: value);
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['id_network'] = idNetwork;
    data['firstname'] = firstname;
    data['lastname'] = lastname;
    data['email'] = email;
    data['mobile'] = mobile;
    if (createdDate != null) {
      data['created_date'] = createdDate!.toJson();
    }
    if (updatedDate != null) {
      data['updated_date'] = updatedDate!.toJson();
    }
    data['role'] = role;
    return data;
  }

  bool get isNetworkAdmin => role == 'NETWORK_ADMIN';
}

class CreatedDate {
  String? date;
  int? timezoneType;
  String? timezone;

  CreatedDate({this.date, this.timezoneType, this.timezone});

  CreatedDate.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    timezoneType = json['timezone_type'];
    timezone = json['timezone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['timezone_type'] = timezoneType;
    data['timezone'] = timezone;
    return data;
  }
}
