import 'package:shared_preferences/shared_preferences.dart';

/// Small typed wrapper over SharedPreferences for app-level settings.
/// Call [init] once before `runApp`.
abstract class AppPrefs {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Language ────────────────────────────────────────────────────────
  static const _kLanguage = 'app_language';

  /// `null` until the user picks a language on first launch.
  static String? get language => _prefs.getString(_kLanguage);

  static Future<void> setLanguage(String code) =>
      _prefs.setString(_kLanguage, code);

  /// First launch = the language screen hasn't been completed yet.
  static bool get languageChosen => language != null;

  // ── Theme ───────────────────────────────────────────────────────────
  static const _kTheme = 'app_theme';

  static String get theme => _prefs.getString(_kTheme) ?? 'system';

  static Future<void> setTheme(String mode) => _prefs.setString(_kTheme, mode);

  // ── Prayer times (AlAdhan API) ──────────────────────────────────────
  static const _kPrayerCity = 'prayer_city';
  static const _kPrayerCountry = 'prayer_country';
  static const _kPrayerMethod = 'prayer_method';
  static const _kPrayerHanafi = 'prayer_hanafi';
  static const _kPrayerLat = 'prayer_lat';
  static const _kPrayerLng = 'prayer_lng';
  static const _kPrayerUseCoords = 'prayer_use_coords';

  static String get prayerCity =>
      _prefs.getString(_kPrayerCity) ?? 'Tashkent';
  static String get prayerCountry =>
      _prefs.getString(_kPrayerCountry) ?? 'Uzbekistan';
  static int get prayerMethod => _prefs.getInt(_kPrayerMethod) ?? 3; // MWL
  static bool get prayerHanafi => _prefs.getBool(_kPrayerHanafi) ?? true;
  static double? get prayerLat => _prefs.getDouble(_kPrayerLat);
  static double? get prayerLng => _prefs.getDouble(_kPrayerLng);
  static bool get prayerUseCoords =>
      _prefs.getBool(_kPrayerUseCoords) ?? false;

  // ── Recent searches ─────────────────────────────────────────────────
  static const _kRecentSearches = 'recent_searches';

  static List<String> get recentSearches =>
      _prefs.getStringList(_kRecentSearches) ?? const [];

  static Future<void> addRecentSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return Future.value();
    final list = [q, ...recentSearches.where((e) => e != q)];
    return _prefs.setStringList(_kRecentSearches, list.take(8).toList());
  }

  static Future<void> clearRecentSearches() =>
      _prefs.remove(_kRecentSearches);

  static Future<void> setPrayerSettings({
    required String city,
    required String country,
    required int method,
    required bool hanafi,
    required bool useCoords,
    double? lat,
    double? lng,
  }) async {
    await _prefs.setString(_kPrayerCity, city);
    await _prefs.setString(_kPrayerCountry, country);
    await _prefs.setInt(_kPrayerMethod, method);
    await _prefs.setBool(_kPrayerHanafi, hanafi);
    await _prefs.setBool(_kPrayerUseCoords, useCoords);
    if (lat != null) await _prefs.setDouble(_kPrayerLat, lat);
    if (lng != null) await _prefs.setDouble(_kPrayerLng, lng);
  }
}
