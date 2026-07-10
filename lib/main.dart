import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/storage/app_prefs.dart';
import 'shared/data/guest_stats.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  await AppPrefs.init();
  await GuestStats.load();

  // Apply the saved language before the first frame.
  final lang = AppPrefs.language;
  if (lang != null && lang != 'system') {
    LocaleController.locale.value = Locale(lang);
  }
  ThemeController.mode.value = switch (AppPrefs.theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  runApp(const QuranAiApp());
}
