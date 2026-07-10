import '../../../core/network/api_client.dart';
import '../../../shared/data/content_models.dart';

class ReadingProgress {
  final int surahNumber;
  final int lastVerse;
  final int totalVerses;
  final double progress;

  const ReadingProgress({
    required this.surahNumber,
    required this.lastVerse,
    required this.totalVerses,
    required this.progress,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        surahNumber: json['surahNumber'] as int,
        lastVerse: json['lastVerse'] as int,
        totalVerses: json['totalVerses'] as int,
        progress: (json['progress'] as num).toDouble(),
      );
}

/// Reading progress + bookmarks (/api/progress, /api/bookmarks).
/// Only used when logged in — guest mode keeps local/mock state.
class QuranRepository {
  final _dio = ApiClient.instance.dio;
  Future<List<Surah>> fetchSurahs(String lang) async {
    final res =
        await _dio.get('/quran/surahs', queryParameters: {'lang': lang});
    return [
      for (final item in res.data['items'] as List)
        _surahFromJson(item as Map<String, dynamic>),
    ];
  }

  /// One surah's ayahs (Arabic, transliteration, translation, juz, audio).
  Future<List<Ayah>> fetchAyahs(int surahNumber, String lang) async {
    final res = await _dio
        .get('/quran/surahs/$surahNumber', queryParameters: {'lang': lang});
    return [
      for (final item in res.data['ayahs'] as List)
        _ayahFromJson(item as Map<String, dynamic>),
    ];
  }

  static Surah _surahFromJson(Map<String, dynamic> json) => Surah(
        number: json['number'] as int,
        name: json['name'] as String,
        arabicName: json['arabicName'] as String,
        meaning: json['meaning'] as String,
        revelation: json['revelation'] as String,
        verses: (json['verses'] ?? 0) as int,
        juzStart: (json['juzStart'] ?? 0) as int,
        juzEnd: (json['juzEnd'] ?? 0) as int,
      );

  static Ayah _ayahFromJson(Map<String, dynamic> json) => Ayah(
        number: json['number'] as int,
        arabic: json['arabic'] as String,
        translation: (json['translation'] ?? '') as String,
        transliteration: (json['transliteration'] ?? '') as String,
        juz: (json['juz'] ?? 1) as int,
        audioUrl: json['audioUrl'] as String?,
      );

  Future<List<ReadingProgress>> fetchProgress() async {
    final res = await _dio.get('/progress');
    return [
      for (final item in res.data['items'] as List)
        ReadingProgress.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> saveProgress({
    required int surahNumber,
    required int lastVerse,
    required int totalVerses,
  }) =>
      _dio.put('/progress/$surahNumber',
          data: {'lastVerse': lastVerse, 'totalVerses': totalVerses});

  Future<Set<int>> fetchCompletedSurahs() async {
    final res = await _dio.get('/progress/completed');
    return {for (final n in res.data['items'] as List) n as int};
  }

  Future<int> setCompleted(int surahNumber, bool completed) async {
    final res = await _dio.put('/progress/$surahNumber/completed',
        data: {'completed': completed});
    return (res.data['completedSurahs'] ?? 0) as int;
  }

  Future<Set<int>> fetchMemorizedAyahs(int surahNumber) async {
    final res = await _dio.get('/progress/$surahNumber/memorized');
    return {for (final n in res.data['items'] as List) n as int};
  }

  Future<void> setAyahMemorized(
          int surahNumber, int ayahNumber, bool memorized) =>
      _dio.put('/progress/$surahNumber/memorized/$ayahNumber',
          data: {'memorized': memorized});

  Future<Set<int>> fetchBookmarkedSurahs() async {
    final res = await _dio.get('/bookmarks');
    return {
      for (final item in res.data['items'] as List)
        (item as Map<String, dynamic>)['surahNumber'] as int,
    };
  }

  Future<Set<String>> fetchBookmarkKeys() async {
    final res = await _dio.get('/bookmarks');
    return {
      for (final item in res.data['items'] as List)
        (item as Map<String, dynamic>)['ayahNumber'] == null
            ? '${item['surahNumber']}'
            : '${item['surahNumber']}:${item['ayahNumber']}',
    };
  }

  Future<void> addBookmark(int surahNumber, {int? ayahNumber}) =>
      _dio.post('/bookmarks',
          data: {'surahNumber': surahNumber, 'ayahNumber': ayahNumber});

  Future<void> removeBookmark(int surahNumber, {int? ayahNumber}) =>
      _dio.delete('/bookmarks/$surahNumber',
          queryParameters: ayahNumber == null ? null : {'ayah': ayahNumber});
}
