import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin synchronous wrapper around SharedPreferences (initialised in main).
class Prefs {
  static late SharedPreferences _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();

  static String? s(String k) => _p.getString(k);
  static int? i(String k) => _p.getInt(k);
  static double? d(String k) => _p.getDouble(k);
  static bool? b(String k) => _p.getBool(k);
  static Future<void> setS(String k, String v) => _p.setString(k, v);
  static Future<void> setI(String k, int v) => _p.setInt(k, v);
  static Future<void> setD(String k, double v) => _p.setDouble(k, v);
  static Future<void> setB(String k, bool v) => _p.setBool(k, v);
  static Future<void> remove(String k) => _p.remove(k);
  static Set<String> keys() => _p.getKeys();
  static Object? value(String k) => _p.get(k);

  static Future<bool> setValue(String key, Object value) {
    if (value is String) return _p.setString(key, value);
    if (value is int) return _p.setInt(key, value);
    if (value is double) return _p.setDouble(key, value);
    if (value is bool) return _p.setBool(key, value);
    throw ArgumentError.value(value, 'value', 'Unsupported SharedPreferences value type');
  }

  static Map<String, dynamic>? json(String k) {
    final v = _p.getString(k);
    if (v == null) return null;
    try {
      return jsonDecode(v) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setJson(String k, Object v) => _p.setString(k, jsonEncode(v));
}
