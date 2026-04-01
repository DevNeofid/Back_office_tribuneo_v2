class QRCodeData {
  List<Data>? data;
  int? idOrder;

  QRCodeData({this.data, this.idOrder});

  QRCodeData.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    idOrder = json['id_order'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['id_order'] = idOrder;
    return data;
  }
}

class Data {
  String? json;
  int? amount;

  Data({this.json, this.amount});

  Data.fromJson(Map<String, dynamic> json) {
    json = json['json'];
    amount = json['amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['json'] = json;
    data['amount'] = amount;
    return data;
  }
}