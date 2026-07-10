import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_repository.dart';
import '../../shared/data/guest_stats.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../theme/app_colors.dart';
import '../auth/data/auth_models.dart';
import '../auth/data/auth_repository.dart';
import 'course_details_screen.dart';

/// Learning Center: real XP/level banner, daily quiz CTA and the course
/// list managed from the admin panel. An empty database shows an empty
/// state — no bundled courses.
class LearningCenterScreen extends StatefulWidget {
  const LearningCenterScreen({super.key});

  @override
  State<LearningCenterScreen> createState() => _LearningCenterScreenState();
}

class _LearningCenterScreenState extends State<LearningCenterScreen> {
  List<CourseItem>? _courses;
  Map<String, int> _doneByCourse = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_courses == null) _load();
  }

  Future<void> _load() async {
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final items = await ContentRepository().lessons(lang);
      if (!mounted) return;
      setState(() => _courses = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _courses = const []); // offline / empty
    }
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final map = AuthSession.isLoggedIn
          ? (await ContentRepository().lessonProgress()).byCourse
          : await GuestStats.lessonsByCourse();
      if (mounted) setState(() => _doneByCourse = map);
    } catch (_) {}
  }

  Future<void> _openCourse(CourseItem course) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CourseDetailsScreen(course: course)));
    _loadProgress(); // refresh counts after studying
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<AuthUser?>(
          valueListenable: AuthSession.user,
          builder: (context, user, _) =>
              ValueListenableBuilder<GuestStatsData>(
            valueListenable: GuestStats.data,
            builder: (context, guest, _) {
              final xp = user?.xp ?? guest.xp;
              final level = user?.level ?? guest.level;
              final intoLevel = xp - (level - 1) * 200;
              final toNext = 200 - intoLevel;

              return ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
                    AppSpacing.screen, 120 + context.padding.bottom),
                children: [
                  Text(context.l10n.learningCenter,
                      style: context.text.headlineLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(context.l10n.masterRecitation,
                      style: context.text.bodyMedium),
                  const SizedBox(height: AppSpacing.xxl),

                  // Level banner — real XP from the DB / phone storage.
                  AppCard(
                    gradient: AppColors.heroGradient,
                    radius: AppRadius.xl,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      children: [
                        ProgressRing(
                          progress: intoLevel / 200,
                          size: 74,
                          strokeWidth: 7,
                          color: Colors.white,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Lv $level',
                                  style: context.text.titleMedium
                                      ?.copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.reciterRank(level),
                                  style: context.text.titleLarge
                                      ?.copyWith(color: Colors.white)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                  context.l10n
                                      .xpLine(xp, toNext, level + 1),
                                  style: context.text.bodySmall
                                      ?.copyWith(color: Colors.white70)),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                child: LinearProgressIndicator(
                                  value: intoLevel / 200,
                                  minHeight: 7,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.25),
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.accentLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Daily quiz CTA
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.quiz),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.quiz_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.dailyQuiz,
                                  style: context.text.titleMedium),
                              Text(context.l10n.dailyQuizSubtitle,
                                  style: context.text.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(
                          label: context.l10n.start,
                          expanded: false,
                          onPressed: () =>
                              Navigator.of(context).pushNamed(Routes.quiz),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(context.l10n.courses,
                      style: context.text.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  if (_courses == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_courses!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxl),
                      child: Center(
                        child: Text(context.l10n.noCoursesYet,
                            style: context.text.bodyMedium),
                      ),
                    )
                  else
                    for (final course in _courses!) ...[
                      _CourseCard(
                        course: course,
                        done: _doneByCourse[course.id] ?? 0,
                        onTap: () => _openCourse(course),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseItem course;
  final int done;
  final VoidCallback onTap;
  const _CourseCard({
    required this.course,
    required this.done,
    required this.onTap,
  });

  static const _icons = <String, IconData>{
    'translate': Icons.translate_rounded,
    'voice': Icons.record_voice_over_rounded,
    'eq': Icons.graphic_eq_rounded,
    'audio': Icons.multitrack_audio_rounded,
    'mic': Icons.mic_external_on_rounded,
    'school': Icons.school_rounded,
  };

  Color get _color {
    final hex = course.color.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16) ?? 0x0E9D7B;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final progress = course.totalLessons == 0
        ? 0.0
        : (done / course.totalLessons).clamp(0.0, 1.0);
    return AppCard(
      shadow: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_icons[course.icon] ?? Icons.school_rounded,
                color: color, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(course.title,
                            style: context.text.titleSmall)),
                    if (progress >= 1)
                      const Icon(Icons.verified_rounded,
                          size: 18, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 2),
                Text(course.subtitle, style: context.text.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('$done/${course.totalLessons}',
                        style: context.text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
