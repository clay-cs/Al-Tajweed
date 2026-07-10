import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot of a guest's locally-tracked activity.
class GuestStatsData {
  final int versesRead;
  final int streak;
  final int recitationCount;
  final int avgTajweedScore;
  final int xp;
  final int tasbeehToday;
  final int completedSurahs;

  const GuestStatsData({
    this.versesRead = 0,
    this.streak = 0,
    this.recitationCount = 0,
    this.avgTajweedScore = 0,
    this.xp = 0,
    this.tasbeehToday = 0,
    this.completedSurahs = 0,
  });

  /// Madani mushaf: 6236 verses over 604 pages.
  int get pagesRead => (versesRead / (6236 / 604)).round();
  int get level => 1 + xp ~/ 200;
}

/// Guest-mode stats persisted on the phone (SharedPreferences), so the app
/// stays fully usable without an account. Mirrors what the backend computes
/// for logged-in users.
abstract class GuestStats {
  static const _kVerses = 'guest_verses_read';
  static const _kDays = 'guest_active_days'; // ISO dates, newest last
  static const _kRecitations = 'guest_recitations';
  static const _kScoreTotal = 'guest_score_total';
  static const _kXp = 'guest_xp';
  static const _kTasbeehDate = 'guest_tasbeeh_date';
  static const _kTasbeehCount = 'guest_tasbeeh_count';
  static const _kCompleted = 'guest_completed_surahs'; // surah numbers
  static const _kMemorized = 'guest_memorized_ayahs'; // "surah:ayah" keys
  static const _kLessons = 'guest_completed_lessons'; // "courseId:itemId"

  static final data = ValueNotifier<GuestStatsData>(const GuestStatsData());

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  /// Loads persisted values into [data]. Call on app start.
  static Future<void> load() async {
    final p = await _prefs;
    final days = p.getStringList(_kDays) ?? const [];
    final recitations = p.getInt(_kRecitations) ?? 0;
    final scoreTotal = p.getInt(_kScoreTotal) ?? 0;
    final lessonsDone = (p.getStringList(_kLessons) ?? const []).length;
    data.value = GuestStatsData(
      versesRead: p.getInt(_kVerses) ?? 0,
      streak: _streakFrom(days),
      recitationCount: recitations,
      avgTajweedScore: recitations == 0 ? 0 : (scoreTotal / recitations).round(),
      // Quiz XP + 10 XP per finished lesson, mirroring the backend.
      xp: (p.getInt(_kXp) ?? 0) + lessonsDone * 10,
      tasbeehToday:
          p.getString(_kTasbeehDate) == _today() ? p.getInt(_kTasbeehCount) ?? 0 : 0,
      completedSurahs: (p.getStringList(_kCompleted) ?? const []).length,
    );
  }

  /// Surah numbers marked as finished (guest mode).
  static Future<Set<int>> completedSurahs() async {
    final p = await _prefs;
    return (p.getStringList(_kCompleted) ?? const [])
        .map(int.parse)
        .toSet();
  }

  /// Completed lesson item ids (guest mode).
  static Future<Set<String>> completedLessons() async {
    final p = await _prefs;
    return (p.getStringList(_kLessons) ?? const [])
        .map((e) => e.split(':').last)
        .toSet();
  }

  /// Completed-lesson counts per course id (guest mode).
  static Future<Map<String, int>> lessonsByCourse() async {
    final p = await _prefs;
    final map = <String, int>{};
    for (final e in p.getStringList(_kLessons) ?? const <String>[]) {
      final course = e.split(':').first;
      map[course] = (map[course] ?? 0) + 1;
    }
    return map;
  }

  /// Returns the new state: true = now completed.
  static Future<bool> toggleLesson(String courseId, String itemId) async {
    final p = await _prefs;
    final set = (p.getStringList(_kLessons) ?? const []).toSet();
    final key = '$courseId:$itemId';
    final added = !set.remove(key);
    if (added) {
      set.add(key);
      await _touchDay(p);
    }
    await p.setStringList(_kLessons, set.toList());
    await load();
    return added;
  }

  /// Memorized ayah numbers of one surah (guest mode).
  static Future<Set<int>> memorizedAyahs(int surahNumber) async {
    final p = await _prefs;
    return (p.getStringList(_kMemorized) ?? const [])
        .where((e) => e.startsWith('$surahNumber:'))
        .map((e) => int.parse(e.split(':')[1]))
        .toSet();
  }

  /// Returns the new state: true = now memorized.
  static Future<bool> toggleMemorizedAyah(int surahNumber, int ayah) async {
    final p = await _prefs;
    final set = (p.getStringList(_kMemorized) ?? const []).toSet();
    final key = '$surahNumber:$ayah';
    final added = !set.remove(key);
    if (added) {
      set.add(key);
      await _touchDay(p);
    }
    await p.setStringList(_kMemorized, set.toList());
    await load();
    return added;
  }

  /// Returns the new state: true = now completed.
  static Future<bool> toggleCompleted(int surahNumber) async {
    final p = await _prefs;
    final set = (p.getStringList(_kCompleted) ?? const []).toSet();
    final added = !set.remove('$surahNumber');
    if (added) {
      set.add('$surahNumber');
      await _touchDay(p);
    }
    await p.setStringList(_kCompleted, set.toList());
    await load();
    return added;
  }

  /// Consecutive-day streak ending today or yesterday.
  static int _streakFrom(List<String> days) {
    if (days.isEmpty) return 0;
    final set = days.toSet();
    var cursor = DateTime.now();
    String iso(DateTime d) => d.toIso8601String().substring(0, 10);
    if (!set.contains(iso(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (set.contains(iso(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static Future<void> _touchDay(SharedPreferences p) async {
    final days = p.getStringList(_kDays) ?? [];
    final today = _today();
    if (!days.contains(today)) {
      days.add(today);
      // Keep the last year of activity — plenty for any streak.
      if (days.length > 366) days.removeRange(0, days.length - 366);
      await p.setStringList(_kDays, days);
    }
  }

  static Future<void> logReading({required int versesDelta}) async {
    final p = await _prefs;
    await p.setInt(_kVerses, (p.getInt(_kVerses) ?? 0) + versesDelta);
    await _touchDay(p);
    await load();
  }

  static Future<void> logRecitation({required int score}) async {
    final p = await _prefs;
    await p.setInt(_kRecitations, (p.getInt(_kRecitations) ?? 0) + 1);
    await p.setInt(_kScoreTotal, (p.getInt(_kScoreTotal) ?? 0) + score);
    await _touchDay(p);
    await load();
  }

  static Future<void> logQuiz({required int xpEarned}) async {
    final p = await _prefs;
    await p.setInt(_kXp, (p.getInt(_kXp) ?? 0) + xpEarned);
    await _touchDay(p);
    await load();
  }

  static Future<void> logTasbeeh({required int count}) async {
    final p = await _prefs;
    final today = _today();
    final sameDay = p.getString(_kTasbeehDate) == today;
    await p.setString(_kTasbeehDate, today);
    await p.setInt(
        _kTasbeehCount, (sameDay ? p.getInt(_kTasbeehCount) ?? 0 : 0) + count);
    await _touchDay(p);
    await load();
  }
}
