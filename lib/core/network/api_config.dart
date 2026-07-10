import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where the Quran AI backend lives.
///
/// The default is chosen per platform:
///  - Android emulator → 10.0.2.2 (the emulator's alias for the host)
///  - Linux/macOS/Windows desktop, iOS simulator, web → localhost
///
/// Running on a REAL PHONE? The phone can't see your computer's localhost —
/// pass your computer's LAN IP instead (both on the same Wi-Fi):
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.63:5000/api
abstract class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (kIsWeb) return 'http://localhost:5000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000/api';
    return 'http://localhost:5000/api';
  }

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);

  /// Backend origin for uploaded files (ayah audio) — [baseUrl] minus `/api`.
  static String get filesBase =>
      baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  /// Turns a server-relative upload path into an absolute URL.
  static String fileUrl(String path) =>
      path.startsWith('http') ? path : '$filesBase$path';
}
