import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static Future<bool?> getBool(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(key) ? sp.getBool(key) : null;
  }

  static Future<void> setBool(String key, bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, value);
  }

  static Future<int?> getInt(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(key) ? sp.getInt(key) : null;
  }

  static Future<void> setInt(String key, int value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(key, value);
  }
}
