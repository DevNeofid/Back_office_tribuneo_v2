class AccountingEntriesModel {
  int? id;
  String? filename;
  String? createdDate;

  AccountingEntriesModel({this.id, this.filename, this.createdDate});

  AccountingEntriesModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    filename = json['filename'];
    createdDate = json['created_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['filename'] = filename;
    data['created_date'] = createdDate;
    return data;
  }
}