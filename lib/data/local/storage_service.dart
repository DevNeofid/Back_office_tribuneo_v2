import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './storage_model.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  AndroidOptions _getAndroidOptions() =>
      const AndroidOptions(encryptedSharedPreferences: true);

  Future<void> writeSecureData(StorageItem newItem) async {
    await _secureStorage.write(
      key: newItem.key,
      value: newItem.value,
      aOptions: _getAndroidOptions(),
    );
  }

  Future<String?> readSecureData(String key) async {
    var readData = await _secureStorage.read(key: key);
    return readData;
  }

  Future<void> deleteSecureData(StorageItem item) async {
    await _secureStorage.delete(key: item.key);
  }

  Future<void> deleteSecureDataFromKey(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<bool> containsKeyInSecureData(String key) async {
    var containsKey = await _secureStorage.containsKey(key: key);
    return containsKey;
  }

  Future<List<StorageItem>> readAllSecureData() async {
    var allData = await _secureStorage.readAll();
    List<StorageItem> list = allData.entries
        .map((e) => StorageItem(e.key, e.value))
        .toList();
    return list;
  }

  Future<void> deleteAllSecureData() async {
    await _secureStorage.deleteAll(aOptions: _getAndroidOptions());
  }
}
