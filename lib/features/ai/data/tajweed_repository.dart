import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'tajweed_models.dart';

/// Sends a recorded recitation to the backend, which proxies the Python
/// Tajweed AI service and (for signed-in users) logs the recitation.
class TajweedRepository {
  final _dio = ApiClient.instance.dio;

  /// Whether the AI service behind the backend is reachable.
  Future<bool> serviceUp() async {
    try {
      final res = await _dio.get('/ai/health');
      return res.data is Map && res.data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Analyze a recitation. [audioPath] is a local file recorded on device.
  /// [surahNumber]/[ayahNumber] let the server log the attempt for stats.
  Future<TajweedResult> assess({
    required String audioPath,
    required String reference,
    int? surahNumber,
    int? ayahNumber,
  }) async {
    final form = FormData.fromMap({
      'reference': reference,
      if (surahNumber != null) 'surahNumber': surahNumber,
      if (ayahNumber != null) 'ayahNumber': ayahNumber,
      'audio': await MultipartFile.fromFile(
        audioPath,
        filename: 'recitation.m4a',
      ),
    });
    final res = await _dio.post(
      '/ai/tajweed',
      data: form,
      // The AI pipeline can take a while on CPU — give it room.
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return TajweedResult.fromJson(res.data as Map<String, dynamic>);
  }
}
