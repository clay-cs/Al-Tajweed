import 'package:flutter/material.dart';

import '../../features/ai/tajweed_checker_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/duas/duas_screen.dart';
import '../../features/hadith/hadith_screen.dart';
import '../../features/language/language_select_screen.dart';
import '../../features/learning/quiz_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/prayer/prayer_times_screen.dart';
import '../../features/qibla/qibla_screen.dart';
import '../../features/quran/bookmarks_screen.dart';
import '../../features/quran/surah_details_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tasbeeh/tasbeeh_screen.dart';
import '../../shared/data/content_models.dart' show Surah;
import '../constants/app_constants.dart';

abstract class Routes {
  static const splash = '/';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const shell = '/shell';
  static const surahDetails = '/surah-details';
  static const hadith = '/hadith';
  static const duas = '/duas';
  static const prayerTimes = '/prayer-times';
  static const qibla = '/qibla';
  static const tasbeeh = '/tasbeeh';
  static const quiz = '/quiz';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const bookmarks = '/bookmarks';
  static const search = '/search';
}

abstract class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      Routes.splash => const SplashScreen(),
      Routes.language => const LanguageSelectScreen(),
      Routes.onboarding => const OnboardingScreen(),
      Routes.welcome => const WelcomeScreen(),
      Routes.login => const LoginScreen(),
      Routes.register => const RegisterScreen(),
      Routes.shell => const MainShell(),
      // A surah argument is required — with none, land back on the shell.
      Routes.surahDetails => settings.arguments is Surah
          ? SurahDetailsScreen(surah: settings.arguments as Surah)
          : const MainShell(),
      Routes.hadith => const HadithScreen(),
      Routes.duas => const DuasScreen(),
      Routes.prayerTimes => const PrayerTimesScreen(),
      Routes.qibla => const QiblaScreen(),
      Routes.tasbeeh => const TasbeehScreen(),
      Routes.quiz => const QuizScreen(),
      Routes.settings => const SettingsScreen(),
      Routes.notifications => const NotificationsScreen(),
      Routes.bookmarks => const BookmarksScreen(),
      Routes.search => const SearchScreen(),
      _ => const SplashScreen(),
    };

    // Fade-through for top-level flows, slide-up feel for detail pages.
    final slideUp = switch (settings.name) {
      Routes.surahDetails ||
      Routes.tasbeeh ||
      Routes.qibla ||
      Routes.quiz ||
      Routes.search =>
        true,
      _ => false,
    };

    return PageRouteBuilder(
      settings: settings,
      transitionDuration: AppDurations.page,
      reverseTransitionDuration: AppDurations.normal,
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: AppCurves.enter);
        if (slideUp) {
          return SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        }
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.985, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Access the special AI Tajweed screen used inside the shell.
  static Widget get tajweedChecker => const TajweedCheckerScreen();
}
