import 'dart:convert';
import 'dart:core';
import 'package:back_office_tribuneo_v2/data/local/storage_model.dart';
import 'package:back_office_tribuneo_v2/data/local/storage_service.dart';
import 'package:back_office_tribuneo_v2/domain/models/network_model.dart';

class StorageFunction {
  static const String _lastViewedKey = 'box_last_viewed_1';

  Future<void> saveNetwork(Map<String, dynamic> network) async {
    final networkJson = jsonEncode(network);
    final item = StorageItem('network', networkJson);
    await _storage.writeSecureData(item);
  }

  final StorageService _storage = StorageService();

  Future<void> clearUser() async {
    await _storage.deleteSecureDataFromKey('firstname');
    await _storage.deleteSecureDataFromKey('user_id');
    await _storage.deleteSecureDataFromKey('role');
    await _storage.deleteSecureDataFromKey('user_id_network');
    await _storage.deleteSecureDataFromKey('id_network');
    await _storage.deleteSecureDataFromKey('id_entity');
    await _storage.deleteSecureDataFromKey('login');
    await _storage.deleteSecureDataFromKey('mobile');
    await _storage.deleteSecureDataFromKey('email');
    await _storage.deleteSecureDataFromKey('lastname');
    await _storage.deleteSecureDataFromKey('network');
  }

  Future<void> saveLogin(String login) async {
    await _storage.deleteSecureDataFromKey('login');
    final items = [StorageItem('login', login)];
    for (final item in items) {
      await _storage.writeSecureData(item);
    }
  }

  Future<void> saveUser(Map<String, dynamic> jsonResponse) async {
    final items = [
      StorageItem('user_id', jsonResponse['id'].toString()),
      StorageItem('mobile', jsonResponse['mobile'] ?? ''),
      StorageItem('username', jsonResponse['username'] ?? ''),
      StorageItem('firstname', jsonResponse['firstname'] ?? ''),
      StorageItem('lastname', jsonResponse['lastname'] ?? ''),
      StorageItem('email', jsonResponse['email'] ?? ''),
    ];

    if (jsonResponse['role'] != null) {
      items.add(StorageItem('role', jsonResponse['role'].toString()));
    } else if (jsonResponse['roles'] != null &&
        jsonResponse['roles'] is List &&
        jsonResponse['roles'].isNotEmpty) {
      items.add(StorageItem('role', jsonResponse['roles'][0].toString()));
    }

    if (jsonResponse['id_network'] != null) {
      items.add(
        StorageItem('user_id_network', jsonResponse['id_network'].toString()),
      );
    }

    if (jsonResponse['id_entity'] != null) {
      final idEntity = jsonResponse['id_entity'].toString();
      items.add(StorageItem('id_entity', idEntity));
    }

    for (final item in items) {
      await _storage.writeSecureData(item);
    }
  }

  Future<void> saveUserIdNetwork(String idNetwork) async {
    final items = [
      StorageItem('user_id_network', idNetwork),
      StorageItem('id_network', idNetwork),
    ];

    for (final item in items) {
      await _storage.writeSecureData(item);
    }
  }

  Future<void> saveNotification(int id) async {
    String? stringOfItems = await _storage.readSecureData('notifications');
    stringOfItems ??= '[]';
    List<dynamic> items = json.decode(stringOfItems);
    items.add(id);
    dynamic newItems = StorageItem('notifications', json.encode(items));
    await _storage.writeSecureData(newItems);
  }

  Future<List> readNotification() async {
    String? stringOfItems = await _storage.readSecureData('notifications');
    if (stringOfItems == null) {
      return [];
    }
    List<dynamic> items = json.decode(stringOfItems);
    await _storage.deleteSecureDataFromKey('notifications');
    return items;
  }

  Future<void> saveLastViewedMenu(String menuName) async {
    final encoded = jsonEncode({'value': menuName});
    await _storage.writeSecureData(StorageItem(_lastViewedKey, encoded));
  }

  Future<String?> readLastViewedMenu() async {
    final raw = await _storage.readSecureData(_lastViewedKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['value'];
        return value?.toString();
      }
      return decoded?.toString();
    } catch (_) {
      return raw;
    }
  }

  Future<Network?> readNetwork() async {
    final networkString = await _storage.readSecureData('network');
    if (networkString != null && networkString.isNotEmpty) {
      final Map<String, dynamic> networkMap = jsonDecode(networkString);
      return Network.fromJson(networkMap);
    }
    return null;
  }
}
