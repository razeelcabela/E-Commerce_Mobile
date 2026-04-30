import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  static const String _key = 'saved_address';

  static Future<void> saveAddress(Map<String, String> address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(address));
  }

  static Future<Map<String, String>?> loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
