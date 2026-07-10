import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'theme/app_theme.dart';

/// App-wide theme mode controller. UI-only for now — persistence comes with
/// the settings feature's data layer.
class ThemeController {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);
}

/// App-wide locale override. `null` follows the system locale
/// (resolved against [AppLocalizations.supportedLocales]).
class LocaleController {
  static final locale = ValueNotifier<Locale?>(null);
}

/// Lets horizontal lists (juz chips, achievements…) be dragged with a
/// mouse too — desktop Flutter only allows touch/stylus by default.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class QuranAiApp extends StatelessWidget {
  const QuranAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.locale,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Quran AI',
              debugShowCheckedModeBanner: false,
              scrollBehavior: _AppScrollBehavior(),
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: Routes.splash,
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          },
        );
      },
    );
  }
}
