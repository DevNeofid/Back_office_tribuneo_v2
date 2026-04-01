import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer';

import 'package:tribuneo_backoffice/domain/models/user_model.dart';
import 'package:tribuneo_backoffice/domain/models/entity_model.dart';

class LocalDataHelper {
  final Map<String, dynamic> _hiveBoxes = {
    //'orders': OrderModelAdapter(),
    //'partners': PartnerModelAdapter(),
    'users': UserModelAdapter(),
    //'token': null,
  };

  // stock instance of LocalDataHelper
  static LocalDataHelper? _instance;

  // final Map<String, dynamic> _hiveModels = {'person': Person, 'users': User};

  LocalDataHelper() {
    if (_instance == null) {
      // for (var i = 0; i < boxesNames.length; i++) {
      //   Hive.registerAdapter(_hiveBoxes[boxesNames[i]]);
      // }

      // Register all adapters
      _hiveBoxes.forEach((key, value) {
        if (value is UserModelAdapter) {
          //Hive.registerAdapter<UserModel>(value);
        }
        // Add more conditions for other adapters if necessary
      });

      _instance = this;
    }
  }

  Future _getBox(String boxName) async {
    Box box;
    switch (boxName) {
      // case 'orders':
      //   box = await Hive.openBox<OrderModel>('orders');
      //   break;
      case 'users':
        box = await Hive.openBox<UserModel>('users');
        break;
      case 'partners':
        box = await Hive.openBox<EntityModel>('partners');
        break;
      case 'last_viewed':
        box = await Hive.openBox('last_viewed');
        break;
      case 'token': // Added this case for the token
        box = await Hive.openBox('token');
        break;
      default:
        box = await Hive.openBox('default');
        break;
    }
    return box;
  }

  Future getAll(String boxName) async {
    Box box = await _getBox(boxName);
    return box.values.toList();
  }

  Future getByKey(String boxName, int key) async {
    Box box = await _getBox(boxName);
    return box.get(key);
  }

  Future add(String boxName, dynamic data) async {
    Box box = await _getBox(boxName);
    inspect(box);
    box.add(data);
  }

  Future addKey(
    String boxName,
    dynamic data,
    int key,
  ) async {
    update(boxName, key, data);
  }

  Future addAll(String boxName, dynamic data) async {
    Box box = await _getBox(boxName);
    box.addAll(data);
  }

  Future update(String boxName, int key, dynamic data) async {
    Box box = await _getBox(boxName);
    box.put(key, data);
  }

  Future delete(String boxName, int key) async {
    Box box = await _getBox(boxName);
    box.delete(key);
  }

  Future deleteAll(String boxName) async {
    Box box = await _getBox(boxName);
    var keys = box.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      box.delete(keys[i]);
    }
    // box.clear();
  }
}
