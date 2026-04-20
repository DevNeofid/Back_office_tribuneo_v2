class Network {
  final int id;
  final String name;
  final String dbName;

  Network({required this.id, required this.name, required this.dbName});

  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(id: json['id'], name: json['name'], dbName: json['db_name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'db_name': dbName};
  }
}
