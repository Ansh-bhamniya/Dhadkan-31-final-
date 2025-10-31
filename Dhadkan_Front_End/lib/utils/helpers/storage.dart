import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // store data
  static Future<void> storeData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // get data
  static Future<String?> getData(String key) async {
    return await _storage.read(key: key);
  }

  // delete data
  static Future<void> deleteData(String key) async {
    await _storage.delete(key: key);
  }
}
