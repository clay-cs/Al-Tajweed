import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT between app launches.
abstract class TokenStore {
  static const _key = 'auth_token';
  static String? _cached;

  static Future<String?> read() async {
    if (_cached != null) return _cached;
    final prefs = await SharedPreferences.getInstance();
    return _cached = prefs.getString(_key);
  }

  static Future<void> save(String token) async {
    _cached = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<void> clear() async {
    _cached = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
