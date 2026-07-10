import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_store.dart';
import 'auth_models.dart';

/// In-memory session state. `null` user = guest mode — screens fall back
/// to mock data so the whole UI stays browsable without a backend.
abstract class AuthSession {
  static final user = ValueNotifier<AuthUser?>(null);
  static bool get isLoggedIn => user.value != null;
}

/// Talks to /api/auth on the backend.
class AuthRepository {
  final _dio = ApiClient.instance.dio;

  Future<AuthUser> login(String email, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    return _storeSession(res.data as Map<String, dynamic>);
  }

  Future<AuthUser> register(
      String name, String email, String password) async {
    final res = await _dio.post('/auth/register',
        data: {'name': name, 'email': email, 'password': password});
    return _storeSession(res.data as Map<String, dynamic>);
  }

  /// Restores the session from a stored token on app start.
  /// Silently stays in guest mode if the token is missing/expired
  /// or the server is unreachable.
  Future<void> tryRestoreSession() async {
    final token = await TokenStore.read();
    if (token == null) return;
    try {
      final res = await _dio.get('/auth/me');
      AuthSession.user.value =
          AuthUser.fromJson(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      // Expired/invalid token — drop it so we don't retry forever.
      if (e.response?.statusCode == 401) await TokenStore.clear();
    } catch (_) {
      // Server unreachable — keep guest mode; token stays for a later retry.
    }
  }

  /// Re-fetches the profile with stats freshly computed from the database
  /// (/api/stats/summary recalculates before answering).
  Future<AuthUser?> refreshProfile() async {
    if (!AuthSession.isLoggedIn) return null;
    try {
      final res = await _dio.get('/stats/summary');
      final user =
          AuthUser.fromJson(res.data['user'] as Map<String, dynamic>);
      AuthSession.user.value = user;
      return user;
    } catch (_) {
      return AuthSession.user.value; // offline — keep what we have
    }
  }

  /// Persists a preference (language/theme/name…) to the user's DB record.
  Future<void> updatePrefs(Map<String, dynamic> fields) async {
    if (!AuthSession.isLoggedIn) return;
    try {
      await updateProfile(fields);
    } catch (_) {
      // Non-fatal — the local setting still applies.
    }
  }

  /// Like [updatePrefs] but rethrows, for flows that must show the error
  /// (profile editing, password change).
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final res = await _dio.patch('/auth/me', data: fields);
    AuthSession.user.value =
        AuthUser.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await TokenStore.clear();
    AuthSession.user.value = null;
  }

  Future<AuthUser> _storeSession(Map<String, dynamic> data) async {
    await TokenStore.save(data['token'] as String);
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    AuthSession.user.value = user;
    return user;
  }
}
