import '../../core/network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import 'guest_stats.dart';

/// Activity logging: tasbeeh sessions, quiz results, AI recitation scores.
/// Logged-in users → backend (/api/stats/*); guests → local phone storage,
/// so stats survive without an account.
class StatsRepository {
  final _dio = ApiClient.instance.dio;

  Future<void> logTasbeeh({
    required String dhikr,
    required int count,
    int rounds = 0,
  }) async {
    if (!AuthSession.isLoggedIn) {
      return GuestStats.logTasbeeh(count: count);
    }
    await _dio.post('/stats/tasbeeh',
        data: {'dhikr': dhikr, 'count': count, 'rounds': rounds});
  }

  Future<void> logQuiz({
    required int correct,
    required int total,
    required int xpEarned,
  }) async {
    if (!AuthSession.isLoggedIn) {
      return GuestStats.logQuiz(xpEarned: xpEarned);
    }
    await _dio.post('/stats/quiz',
        data: {'correct': correct, 'total': total, 'xpEarned': xpEarned});
  }

  Future<void> logRecitation({
    required int surahNumber,
    required int ayahNumber,
    required int score,
    List<Map<String, String>> mistakes = const [],
  }) async {
    if (!AuthSession.isLoggedIn) {
      return GuestStats.logRecitation(score: score);
    }
    await _dio.post('/stats/recitation', data: {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'score': score,
      'mistakes': mistakes,
    });
  }

  /// Last 7 days of average recitation scores for the progress chart.
  Future<List<double>> weeklyScores() async {
    final res = await _dio.get('/stats/recitations/weekly');
    return [
      for (final item in res.data['items'] as List)
        ((item as Map<String, dynamic>)['score'] as num).toDouble(),
    ];
  }
}
