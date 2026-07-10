import '../../core/network/api_client.dart';
import 'content_models.dart';

/// A daily-quiz question as served by the backend (already localized).
class QuizQuestionItem {
  final String id;
  final String question;
  final List<String> options;
  final int answer;

  const QuizQuestionItem({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizQuestionItem.fromJson(Map<String, dynamic> json) =>
      QuizQuestionItem(
        id: json['id'] as String,
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        answer: json['answer'] as int,
      );
}

/// A Learning Center course as served by the backend (already localized).
class CourseItem {
  final String id;
  final String title;
  final String subtitle;
  final int totalLessons;
  final String icon;
  final String color;

  const CourseItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.totalLessons,
    required this.icon,
    required this.color,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) => CourseItem(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        totalLessons: json['totalLessons'] as int,
        icon: (json['icon'] ?? 'school') as String,
        color: (json['color'] ?? '#0E9D7B') as String,
      );
}

/// One lesson INSIDE a course, as served by the backend (localized).
class LessonContent {
  final String id;
  final String courseId;
  final int order;
  final String title;
  final String body;
  final String arabic;
  final String? imageUrl;

  const LessonContent({
    required this.id,
    required this.courseId,
    required this.order,
    required this.title,
    required this.body,
    required this.arabic,
    this.imageUrl,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) => LessonContent(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        order: (json['order'] ?? 0) as int,
        title: json['title'] as String,
        body: json['body'] as String,
        arabic: (json['arabic'] ?? '') as String,
        imageUrl: json['imageUrl'] as String?,
      );
}

/// The verse of the day (rotates at midnight, same for everyone).
class DailyVerse {
  final int surahNumber;
  final int number;
  final String surahName;
  final String arabic;
  final String translation;

  const DailyVerse({
    required this.surahNumber,
    required this.number,
    required this.surahName,
    required this.arabic,
    required this.translation,
  });

  factory DailyVerse.fromJson(Map<String, dynamic> json) => DailyVerse(
        surahNumber: json['surahNumber'] as int,
        number: json['number'] as int,
        surahName: json['surahName'] as String,
        arabic: json['arabic'] as String,
        translation: (json['translation'] ?? '') as String,
      );
}

/// Completed lessons of the signed-in user.
class LessonProgress {
  final Set<String> completedIds;
  final Map<String, int> byCourse;
  const LessonProgress(this.completedIds, this.byCourse);
}

/// Admin-managed content: daily quiz questions and Learning Center courses.
/// Public endpoints — guests get them too.
class ContentRepository {
  final _dio = ApiClient.instance.dio;

  /// All lessons of one course, in order.
  Future<List<LessonContent>> courseLessons(
      String courseId, String lang) async {
    final res = await _dio.get('/content/lessons/$courseId/items',
        queryParameters: {'lang': lang});
    return [
      for (final item in res.data['items'] as List)
        LessonContent.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Completed lesson ids + per-course counts (auth required).
  Future<LessonProgress> lessonProgress() async {
    final res = await _dio.get('/progress/lessons');
    return LessonProgress(
      {for (final id in res.data['items'] as List) id as String},
      {
        for (final e in (res.data['byCourse'] as Map).entries)
          e.key as String: e.value as int,
      },
    );
  }

  Future<void> setLessonCompleted(String lessonId, bool completed) =>
      _dio.put('/progress/lessons/$lessonId', data: {'completed': completed});

  /// Admin-managed duas, already localized.
  Future<List<DuaItem>> duas(String lang) async {
    final res =
        await _dio.get('/content/duas', queryParameters: {'lang': lang});
    return [
      for (final item in res.data['items'] as List)
        DuaItem(
          title: item['title'] as String,
          category: (item['category'] ?? 'Morning') as String,
          arabic: item['arabic'] as String,
          transliteration: (item['transliteration'] ?? '') as String,
          translation: (item['translation'] ?? '') as String,
        ),
    ];
  }

  /// Admin-managed hadith library, already localized.
  Future<List<HadithItem>> hadiths(String lang) async {
    final res =
        await _dio.get('/content/hadiths', queryParameters: {'lang': lang});
    return [
      for (final item in res.data['items'] as List)
        _hadithFromJson(item as Map<String, dynamic>),
    ];
  }

  /// Hadith of the day — null while the hadith DB is empty.
  Future<HadithItem?> hadithOfDay(String lang) async {
    final res = await _dio
        .get('/content/hadith-of-day', queryParameters: {'lang': lang});
    final item = res.data['item'];
    return item == null
        ? null
        : _hadithFromJson(item as Map<String, dynamic>);
  }

  /// Records that the signed-in user read this hadith (idempotent).
  Future<void> markHadithRead(String id) =>
      _dio.post('/content/hadiths/$id/read');

  static HadithItem _hadithFromJson(Map<String, dynamic> json) => HadithItem(
        id: json['id'] as String?,
        book: (json['book'] ?? '') as String,
        bookNumber: (json['bookNumber'] ?? 1) as int,
        chapter: (json['chapter'] ?? '') as String,
        hadithNumber: (json['hadithNumber'] ?? 0) as int,
        narrator: (json['narrator'] ?? '') as String,
        arabic: json['arabic'] as String,
        translation: (json['translation'] ?? '') as String,
        uzbek: (json['uzbek'] ?? '') as String,
        english: (json['english'] ?? '') as String,
        grade: (json['grade'] ?? 'Sahih') as String,
        tags: [for (final t in (json['tags'] ?? []) as List) t as String],
      );

  /// Verse of the day — null while the Quran DB is empty.
  Future<DailyVerse?> verseOfDay(String lang) async {
    final res = await _dio
        .get('/content/verse-of-day', queryParameters: {'lang': lang});
    final item = res.data['item'];
    return item == null
        ? null
        : DailyVerse.fromJson(item as Map<String, dynamic>);
  }

  Future<List<QuizQuestionItem>> dailyQuiz(String lang) async {
    final res = await _dio.get('/content/quiz/daily',
        queryParameters: {'lang': lang});
    return [
      for (final item in res.data['items'] as List)
        QuizQuestionItem.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<List<CourseItem>> lessons(String lang) async {
    final res =
        await _dio.get('/content/lessons', queryParameters: {'lang': lang});
    return [
      for (final item in res.data['items'] as List)
        CourseItem.fromJson(item as Map<String, dynamic>),
    ];
  }
}
