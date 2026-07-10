import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_repository.dart';
import '../../shared/data/guest_stats.dart';
import '../../shared/widgets/app_card.dart';
import '../../theme/app_colors.dart';
import '../auth/data/auth_repository.dart';
import 'lesson_viewer_screen.dart';

/// One course: its lesson list with per-lesson completion state and an
/// overall progress header. Lessons come from the admin panel; progress
/// is stored in the DB for users and on the phone for guests.
class CourseDetailsScreen extends StatefulWidget {
  final CourseItem course;
  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  List<LessonContent>? _lessons; // null = loading
  bool _error = false;
  Set<String> _completed = {};

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lessons == null && !_error) _load();
  }

  Future<void> _load() async {
    setState(() {
      _lessons = null;
      _error = false;
    });
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final items =
          await ContentRepository().courseLessons(widget.course.id, lang);
      if (!mounted) return;
      setState(() => _lessons = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  Future<void> _loadCompleted() async {
    try {
      final set = AuthSession.isLoggedIn
          ? (await ContentRepository().lessonProgress()).completedIds
          : await GuestStats.completedLessons();
      if (mounted) setState(() => _completed = set);
    } catch (_) {}
  }

  Future<void> _openLesson(int index) async {
    final lessons = _lessons!;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LessonViewerScreen(
        course: widget.course,
        lessons: lessons,
        initialIndex: index,
        completed: _completed,
      ),
    ));
    // The viewer mutates the shared `_completed` set — just repaint.
    if (mounted) setState(() {});
  }

  Color get _color {
    final hex = widget.course.color.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16) ?? 0x0E9D7B;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final lessons = _lessons;
    final done = lessons == null
        ? 0
        : lessons.where((l) => _completed.contains(l.id)).length;
    final total = lessons?.length ?? course.totalLessons;
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: SafeArea(
        child: lessons == null && !_error
            ? const Center(child: CircularProgressIndicator())
            : _error
                ? _ErrorState(onRetry: _load)
                : lessons!.isEmpty
                    ? _EmptyState(text: context.l10n.noLessonsYet)
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.lg,
                            AppSpacing.screen,
                            AppSpacing.xxl + context.padding.bottom),
                        children: [
                          // Progress header
                          AppCard(
                            gradient: AppColors.heroGradient,
                            radius: AppRadius.xl,
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course.subtitle,
                                    style: context.text.bodyMedium
                                        ?.copyWith(color: Colors.white70)),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                    context.l10n
                                        .lessonsCompleted(done, total),
                                    style: context.text.titleMedium
                                        ?.copyWith(color: Colors.white)),
                                const SizedBox(height: AppSpacing.sm),
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.25),
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppColors.accentLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          for (final (i, lesson) in lessons.indexed) ...[
                            _LessonTile(
                              lesson: lesson,
                              index: i,
                              color: _color,
                              done: _completed.contains(lesson.id),
                              onTap: () => _openLesson(i),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LessonContent lesson;
  final int index;
  final Color color;
  final bool done;
  final VoidCallback onTap;

  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.color,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: false,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: done ? AppColors.success : null,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: lesson.arabic.isNotEmpty
                ? Text(lesson.arabic,
                    style: TextStyle(fontSize: 22, color: color))
                : Text('${index + 1}',
                    style: context.text.titleMedium?.copyWith(color: color)),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.lessonOrder(index + 1),
                    style: context.text.labelSmall),
                const SizedBox(height: 2),
                Text(lesson.title, style: context.text.titleSmall),
              ],
            ),
          ),
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.play_circle_outline_rounded,
            color: done
                ? AppColors.success
                : context.colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 44, color: context.colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.networkError, style: context.text.titleMedium),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 44, color: context.colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(text,
                textAlign: TextAlign.center,
                style: context.text.titleMedium),
          ],
        ),
      ),
    );
  }
}
