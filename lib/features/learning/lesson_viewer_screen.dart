import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_config.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_repository.dart';
import '../../shared/data/guest_stats.dart';
import '../../shared/data/local_bookmarks.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../auth/data/auth_repository.dart';

/// A single lesson: image, big Arabic example, body text, and a
/// "completed" button that stores progress (DB for users, phone for
/// guests). Swipes/buttons move between the course's lessons.
class LessonViewerScreen extends StatefulWidget {
  final CourseItem course;
  final List<LessonContent> lessons;
  final int initialIndex;

  /// Shared with the course screen — mutated in place so the list
  /// updates as soon as the viewer pops.
  final Set<String> completed;

  const LessonViewerScreen({
    super.key,
    required this.course,
    required this.lessons,
    required this.initialIndex,
    required this.completed,
  });

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _saving = false;

  LessonContent get _lesson => widget.lessons[_index];
  bool get _done => widget.completed.contains(_lesson.id);

  Future<void> _toggleDone() async {
    if (_saving) return;
    final lesson = _lesson;
    final was = widget.completed.contains(lesson.id);
    setState(() {
      _saving = true;
      was
          ? widget.completed.remove(lesson.id)
          : widget.completed.add(lesson.id);
    });
    try {
      if (AuthSession.isLoggedIn) {
        await ContentRepository().setLessonCompleted(lesson.id, !was);
        AuthRepository().refreshProfile(); // XP/level recomputed in the DB
      } else {
        await GuestStats.toggleLesson(widget.course.id, lesson.id);
      }
      if (!was) TodayActivity.addLesson(); // daily-goals counter
      if (mounted && !was) context.showSnack(context.l10n.lessonDone);
    } catch (_) {
      if (mounted) {
        setState(() => was
            ? widget.completed.add(lesson.id)
            : widget.completed.remove(lesson.id)); // revert
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.lessons.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.course.title} • ${context.l10n.lessonOrder(_index + 1)}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: (_index + 1) / total,
                  minHeight: 6,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: total,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final lesson = widget.lessons[i];
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    children: [
                      if (lesson.imageUrl != null &&
                          lesson.imageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          child: Image.network(
                            ApiConfig.fileUrl(lesson.imageUrl!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      if (lesson.arabic.isNotEmpty) ...[
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              lesson.arabic,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: AppTypography.arabicDisplay(context)
                                  .copyWith(fontSize: 64),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      Text(lesson.title,
                          style: context.text.headlineSmall),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        lesson.body,
                        style: context.text.bodyLarge
                            ?.copyWith(height: 1.7),
                      ),
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  );
                },
              ),
            ),

            // Bottom bar: completed toggle + next lesson.
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
                  AppSpacing.screen, AppSpacing.lg + context.padding.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _done
                          ? context.l10n.lessonDoneBadge
                          : context.l10n.markLessonDone,
                      icon: _done
                          ? Icons.verified_rounded
                          : Icons.check_circle_outline_rounded,
                      variant: _done
                          ? AppButtonVariant.secondary
                          : AppButtonVariant.primary,
                      loading: _saving,
                      onPressed: _toggleDone,
                    ),
                  ),
                  if (_index + 1 < total) ...[
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      label: context.l10n.nextLesson,
                      icon: Icons.arrow_forward_rounded,
                      variant: AppButtonVariant.secondary,
                      expanded: false,
                      onPressed: () => _pages.nextPage(
                        duration: AppDurations.normal,
                        curve: AppCurves.enter,
                      ),
                    ),
                  ] else if (_done) ...[
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.emoji_events_rounded,
                        color: AppColors.accent, size: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
