import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/app_prefs.dart';

/// One day of prayer times + the Hijri date, from the AlAdhan API.
class PrayerData {
  /// "Fajr" → "02:53" (24h), keys: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha.
  final Map<String, String> timings;
  final int hijriDay;
  final int hijriMonth; // 9 = Ramadan
  final String hijriMonthName;
  final int hijriYear;
  final String methodName;
  final String location;

  const PrayerData({
    required this.timings,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriMonthName,
    required this.hijriYear,
    required this.methodName,
    required this.location,
  });

  static const orderedNames = [
    'Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha',
  ];

  String get hijriLabel => '$hijriDay $hijriMonthName $hijriYear';
  bool get isRamadan => hijriMonth == 9;

  DateTime _timeToday(String hhmm) {
    final now = DateTime.now();
    final parts = hhmm.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]),
        int.parse(parts[1]));
  }

  /// True if the prayer's time has already passed today.
  bool passed(String name) =>
      DateTime.now().isAfter(_timeToday(timings[name] ?? '00:00'));

  /// The next upcoming prayer (skips Sunrise); after Isha → tomorrow's Fajr.
  (String name, String time, Duration left) nextPrayer() {
    final now = DateTime.now();
    for (final name in orderedNames) {
      if (name == 'Sunrise') continue;
      final t = _timeToday(timings[name]!);
      if (t.isAfter(now)) return (name, timings[name]!, t.difference(now));
    }
    final fajr = _timeToday(timings['Fajr']!).add(const Duration(days: 1));
    return ('Fajr', timings['Fajr']!, fajr.difference(now));
  }
}

/// AlAdhan API client (https://aladhan.com/prayer-times-api) with a
/// day-level cache shared by the home strip and the prayer screen.
/// Settings (city/coords, calculation method, Hanafi Asr) live in AppPrefs.
class PrayerRepository {
  static final data = ValueNotifier<PrayerData?>(null);
  static String? _loadedKey; // settings+date the cache was loaded for

  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.aladhan.com/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// AlAdhan calculation method ids offered in settings.
  static const methods = <int, String>{
    3: 'Muslim World League',
    1: 'University of Karachi',
    2: 'ISNA (North America)',
    4: 'Umm al-Qura (Makkah)',
    5: 'Egyptian Authority',
    13: 'Diyanet (Turkey)',
    14: 'Russia (Spiritual Adm.)',
  };

  static String get _settingsKey =>
      '${AppPrefs.prayerUseCoords ? '${AppPrefs.prayerLat},${AppPrefs.prayerLng}' : '${AppPrefs.prayerCity},${AppPrefs.prayerCountry}'}'
      '|${AppPrefs.prayerMethod}|${AppPrefs.prayerHanafi}'
      '|${DateTime.now().toIso8601String().substring(0, 10)}';

  /// Loads today's times once; later calls are no-ops until the date or
  /// the settings change. Errors leave the previous data in place.
  static Future<void> ensureLoaded() async {
    if (_loadedKey == _settingsKey && data.value != null) return;
    await reload();
  }

  static Future<void> reload() async {
    final key = _settingsKey;
    try {
      final school = AppPrefs.prayerHanafi ? 1 : 0;
      final Response res;
      final String location;
      if (AppPrefs.prayerUseCoords &&
          AppPrefs.prayerLat != null &&
          AppPrefs.prayerLng != null) {
        res = await _dio.get('/timings', queryParameters: {
          'latitude': AppPrefs.prayerLat,
          'longitude': AppPrefs.prayerLng,
          'method': AppPrefs.prayerMethod,
          'school': school,
        });
        location =
            '${AppPrefs.prayerLat!.toStringAsFixed(2)}, ${AppPrefs.prayerLng!.toStringAsFixed(2)}';
      } else {
        res = await _dio.get('/timingsByCity', queryParameters: {
          'city': AppPrefs.prayerCity,
          'country': AppPrefs.prayerCountry,
          'method': AppPrefs.prayerMethod,
          'school': school,
        });
        location = '${AppPrefs.prayerCity}, ${AppPrefs.prayerCountry}';
      }

      final body = res.data['data'] as Map<String, dynamic>;
      final rawTimings = body['timings'] as Map<String, dynamic>;
      final hijri = body['date']['hijri'] as Map<String, dynamic>;

      data.value = PrayerData(
        timings: {
          for (final name in PrayerData.orderedNames)
            // Some endpoints append " (+05)" — keep just HH:mm.
            name: (rawTimings[name] as String).split(' ').first,
        },
        hijriDay: int.parse(hijri['day'] as String),
        hijriMonth: (hijri['month']['number'] as num).toInt(),
        hijriMonthName: hijri['month']['en'] as String,
        hijriYear: int.parse(hijri['year'] as String),
        methodName:
            (body['meta']?['method']?['name'] ?? '') as String,
        location: location,
      );
      _loadedKey = key;
    } catch (_) {
      // Offline — keep whatever we had; screens show their fallbacks.
    }
  }
}
