// lib/utils/storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static late SharedPreferences _prefs;

  // Initialize SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Fixed Getter Methods ---

  // FIX: Handles null return from SharedPreferences and ensures boolean conversion is safe.
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  // --- Setter Methods ---

  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }
}