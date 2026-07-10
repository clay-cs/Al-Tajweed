import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/utils/extensions.dart';
import '../../theme/app_colors.dart';
import '../auth/data/auth_repository.dart';

/// Animated splash: breathing logo mark over a deep emerald gradient,
/// then auto-advances to onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutBack));
  late final _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1, curve: Curves.easeOut));

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    // Restore a saved session in the background while the logo animates.
    AuthRepository().tryRestoreSession();
    _navTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      // Very first launch → pick a language. Returning logged-in users go
      // straight to the app; everyone else sees onboarding.
      final next = !AppPrefs.languageChosen
          ? Routes.language
          : AuthSession.isLoggedIn
              ? Routes.shell
              : Routes.onboarding;
      Navigator.of(context).pushReplacementNamed(next);
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_stories_rounded,
                      size: 54, color: Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Text(
                      'Quran AI',
                      style: context.text.displayMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.splashTagline,
                      style: context.text.bodyLarge
                          ?.copyWith(color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _textFade,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}
