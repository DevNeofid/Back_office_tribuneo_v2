import 'package:hive_flutter/hive_flutter.dart';

import 'package:tribuneo_backoffice/domain/models/user_model.dart';

class LocalDataSource {
  LocalDataSource._privateConstructor();

  static final LocalDataSource _instance =
      LocalDataSource._privateConstructor();

  factory LocalDataSource() {
    return _instance;
  }

  static Future<void> setupLocalDataSource() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    //Hive.registerAdapter(OrderModelAdapter());
    //LocalDataSource._addFakeOrders();
  }

  // static const String _kUsersTable = 'users';
  // static const String _kOrdersTable = 'orders';

  // static Future<void> _addFakeOrders() async {
  //   List<OrderModel> orders = [];

  //   List<Map<String, dynamic>> ordersJson = [
  //     {
  //       'id': 1,
  //       'orderNumber': '123456789',
  //       'orderDate': {
  //         "date": "2022-09-05 14:23:55.000000",
  //         "timezone_type": 3,
  //         "timezone": "Europe/Paris"
  //       },
  //       'numberOfFunds': 2,
  //       'valueByFund': 26.0,
  //       'totalValue': 52.0,
  //       'giftFrom': 'Lulu',
  //       'giftReason': 'Anniversaire'
  //     },
  //     {
  //       'id': 2,
  //       'orderNumber': '987654321',
  //       'orderDate': {
  //         "date": "2022-09-05 14:23:55.000000",
  //         "timezone_type": 3,
  //         "timezone": "Europe/Paris"
  //       },
  //       'numberOfFunds': 13,
  //       'valueByFund': 32.0,
  //       'totalValue': 416.0,
  //       'giftFrom': 'Toto',
  //       'giftReason': 'Noel'
  //     }
  //   ];
  //   Map<String, dynamic> json;
  //   for (var i = 0; i < ordersJson.length; i++) {
  //     print("### DEBUG ### -> ordersJson.length ${ordersJson.length}");
  //     print("### DEBUG ### -> toto $i");
  //     json = ordersJson[i];
  //     // print("### DEBUG ### -> Json : $json");
  //     orders.add(OrderModel.fromJson(json));
  //   }

  //   final box = await Hive.openBox<OrderModel>(LocalDataSource._kOrdersTable);
  //   // box.addAll(orders);
  //   for (var i = 0; i < orders.length; i++) {
  //     box.add(orders[i]);
  //   }
  // }

  // static Future<List<OrderModel>> getOrders() async {
  //   final box = await Hive.openBox<OrderModel>(LocalDataSource._kOrdersTable);
  //   return box.values.toList();
  // }

  // Future<void> saveUser(UserModel user) async {
  //   final Box<UserModel> userBox = await Hive.openBox<UserModel>(_kUsersTable);
  //   userBox.add(user);
  // }

  // static Future<void> saveOrder(OrderModel order) async {
  //   print("### DEBUG ### -> saveOrder : $order");
  //   final Box<OrderModel> orderBox =
  //       await Hive.openBox<OrderModel>(LocalDataSource._kOrdersTable);
  //   orderBox.add(order);
  // }

  // static Future<void> clearOrders() async {
  //   print("### DEBUG ### -> clearOrders");
  //   final Box<OrderModel> orderBox =
  //       await Hive.openBox<OrderModel>(LocalDataSource._kOrdersTable);
  //   orderBox.clear();
  // }

  // static Future<void> deleteOrder(dynamic key) async {
  //   final box = await Hive.openBox<OrderModel>(LocalDataSource._kOrdersTable);
  //   box.delete(key);
  // }

  // Future<void> saveOrders(List<OrderModel> orders) async {
  //   print("### DEBUG ### -> saveOrders : $orders");
  //   final Box<OrderModel> orderBox =
  //       await Hive.openBox<OrderModel>(_kOrdersTable);
  //   //clear the box before adding new orders
  //   orderBox.clear();
  //   orderBox.addAll(orders);
  // }

  // Future<List<UserModel?>> getUsers() async {
  //   final Box<UserModel> userBox = await Hive.openBox<UserModel>(_kUsersTable);
  //   return userBox.values.toList();
  // }

  // Future<List<OrderModel>> getOrders() async {
  //   final Box<OrderModel> orderBox =
  //       await Hive.openBox<OrderModel>(_kOrdersTable);
  //   return orderBox.values.toList();
  // }
}
