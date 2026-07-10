import 'package:shared_preferences/shared_preferences.dart';

/// Phone-side bookmark storage used in guest mode (and as an instant cache).
/// Entries are `"surah"` for whole-surah bookmarks and `"surah:ayah"` for
/// single verses — mirroring the backend's Bookmark collection.
abstract class LocalBookmarks {
  static const _key = 'quran_bookmarks';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  /// Returns the new state: true = bookmarked.
  static Future<bool> toggle(String entry) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? const []).toSet();
    final added = !set.remove(entry);
    if (added) set.add(entry);
    await prefs.setStringList(_key, set.toList());
    return added;
  }

  static String surahKey(int surah) => '$surah';
  static String ayahKey(int surah, int ayah) => '$surah:$ayah';
}

/// Remembers where the reader left off — powers the Quran tab header and
/// the home screen's continue-reading card.
abstract class LastRead {
  static const _kLabel = 'last_read_label';
  static const _kSurah = 'last_read_surah';

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLabel);
  }

  /// Surah number of the last opened surah, or null.
  static Future<int?> surahNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSurah);
  }

  static Future<void> save(String label, {int? surahNumber}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLabel, label);
    if (surahNumber != null) await prefs.setInt(_kSurah, surahNumber);
  }
}

/// Today's activity counters for the home screen's daily goals —
/// reset automatically when the date changes.
abstract class TodayActivity {
  static const _kDate = 'today_date';
  static const _kVerses = 'today_verses';
  static const _kRecitations = 'today_recitations';
  static const _kLessons = 'today_lessons';

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  static Future<SharedPreferences> _fresh() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kDate) != _today()) {
      await prefs.setString(_kDate, _today());
      await prefs.setInt(_kVerses, 0);
      await prefs.setInt(_kRecitations, 0);
      await prefs.setInt(_kLessons, 0);
    }
    return prefs;
  }

  static Future<(int verses, int recitations, int lessons)> load() async {
    final p = await _fresh();
    return (
      p.getInt(_kVerses) ?? 0,
      p.getInt(_kRecitations) ?? 0,
      p.getInt(_kLessons) ?? 0,
    );
  }

  static Future<void> addVerses(int n) async {
    final p = await _fresh();
    await p.setInt(_kVerses, (p.getInt(_kVerses) ?? 0) + n);
  }

  static Future<void> addRecitation() async {
    final p = await _fresh();
    await p.setInt(_kRecitations, (p.getInt(_kRecitations) ?? 0) + 1);
  }

  static Future<void> addLesson() async {
    final p = await _fresh();
    await p.setInt(_kLessons, (p.getInt(_kLessons) ?? 0) + 1);
  }
}
