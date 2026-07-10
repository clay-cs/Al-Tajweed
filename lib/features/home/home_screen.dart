import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../auth/data/auth_models.dart';
import '../auth/data/auth_repository.dart';
import '../prayer/data/prayer_repository.dart';
import 'widgets/home_sections.dart';

/// Home dashboard: greeting, continue-reading hero, prayer strip,
/// quick actions, daily verse & hadith, recent surahs, learning progress
/// and daily goals.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(
              top: AppSpacing.md, bottom: 120 + context.padding.bottom),
          children: [
            const GreetingHeader(),
            const SizedBox(height: AppSpacing.xxl),
            const ContinueReadingCard(),
            const SizedBox(height: AppSpacing.xxl),
            const PrayerStrip(),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeaderPadded(title: context.l10n.quickActions),
            const SizedBox(height: AppSpacing.md),
            const QuickActionsGrid(),
            const SizedBox(height: AppSpacing.xxl),
            const DailyVerseCard(),
            const SizedBox(height: AppSpacing.lg),
            const DailyHadithCard(),
            const SizedBox(height: AppSpacing.xxl),
            // These two hide themselves until they have real data,
            // so their headers live inside the widgets.
            const RecentSurahsRow(),
            const LearningProgressCard(),
            SectionHeaderPadded(title: context.l10n.dailyGoals),
            const SizedBox(height: AppSpacing.md),
            const DailyGoalsCard(),
          ],
        ),
      ),
    );
  }
}

/// Section header without an action, aligned with screen padding.
class SectionHeaderPadded extends StatelessWidget {
  final String title;
  const SectionHeaderPadded({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Text(title, style: context.text.titleLarge),
    );
  }
}

/// Top row: greeting + today's date + notification bell. Rebuilds when
/// the session changes (login/logout) so the name is always current.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthSession.user,
      builder: (context, user, _) => ValueListenableBuilder<PrayerData?>(
        valueListenable: PrayerRepository.data,
        builder: (context, prayer, _) {
        final name = user?.name.split(' ').first ?? context.l10n.guest;
        final locale = Localizations.localeOf(context).toString();
        // Gregorian date + the real Hijri date from AlAdhan (once loaded).
        var today =
            DateFormat('d MMMM, EEEE', locale).format(DateTime.now());
        if (prayer != null) {
          today = '$today • ${prayer.hijriLabel}';
        }
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0E9D7B), Color(0xFF0B6E58)]),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? '?' : name.substring(0, 1),
                  style: context.text.titleLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.greeting(name),
                        style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(today, style: context.text.bodySmall),
                  ],
                ),
              ),
              _BellButton(
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.notifications),
              ),
            ],
          ),
        );
        },
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BellButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.colors.outline),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                color: context.colors.onSurface, size: 24),
            Positioned(
              top: 11,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.colors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: context.colors.surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
