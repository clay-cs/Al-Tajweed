import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/data/content_repository.dart';
import '../../../shared/data/guest_stats.dart';
import '../../../shared/data/local_bookmarks.dart';
import '../../../shared/data/content_models.dart';
import '../../../shared/widgets/animated_press.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../learning/course_details_screen.dart';
import '../../prayer/data/prayer_repository.dart';
import '../../quran/data/quran_repository.dart';

/// Hero card: pick up where you left off — real last-read surah with the
/// reader's actual progress. Hidden while the Quran DB is empty.
class ContinueReadingCard extends StatefulWidget {
  const ContinueReadingCard({super.key});

  @override
  State<ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends State<ContinueReadingCard> {
  Surah? _surah;
  double? _progress; // null = unknown (guest)
  int? _lastVerse;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final surahs = await QuranRepository().fetchSurahs(lang);
      if (surahs.isEmpty) return;
      final byNumber = {for (final s in surahs) s.number: s};

      final lastNumber = await LastRead.surahNumber();
      var surah = byNumber[lastNumber] ?? surahs.first;

      double? progress;
      int? lastVerse;
      if (AuthSession.isLoggedIn) {
        try {
          final items = await QuranRepository().fetchProgress();
          if (lastNumber == null && items.isNotEmpty) {
            // No local record (fresh install) — server knows best.
            surah = byNumber[items.first.surahNumber] ?? surah;
          }
          for (final p in items) {
            if (p.surahNumber == surah.number) {
              progress = p.progress;
              lastVerse = p.lastVerse;
            }
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _surah = surah;
        _progress = progress;
        _lastVerse = lastVerse;
      });
    } catch (_) {
      // Offline / empty DB — card stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final surah = _surah;
    if (surah == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        gradient: AppColors.heroGradient,
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.xl),
        onTap: () => Navigator.of(context)
            .pushNamed(Routes.surahDetails, arguments: surah),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  radius: AppRadius.pill,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_stories_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: AppSpacing.xs),
                      Text(context.l10n.continueReading,
                          style: context.text.labelSmall
                              ?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(surah.arabicName,
                    style: AppTypography.arabicTitle(context)
                        .copyWith(color: Colors.white, fontSize: 22)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(surah.name,
                style:
                    context.text.headlineMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              _lastVerse != null
                  ? '${surah.meaning} • ${context.l10n.verseOfTotal(_lastVerse!, surah.verses)}'
                  : '${surah.meaning} • ${context.l10n.versesCount(surah.verses)}',
              style: context.text.bodySmall
                  ?.copyWith(color: Colors.white.withOpacity(0.8)),
            ),
            if (_progress != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('${(_progress! * 100).round()}%',
                      style: context.text.labelMedium
                          ?.copyWith(color: Colors.white)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal prayer times strip — real AlAdhan times with the next
/// prayer highlighted and a live countdown label.
class PrayerStrip extends StatefulWidget {
  const PrayerStrip({super.key});

  @override
  State<PrayerStrip> createState() => _PrayerStripState();
}

class _PrayerStripState extends State<PrayerStrip> {
  static const _icons = <String, IconData>{
    'Fajr': Icons.wb_twilight_rounded,
    'Dhuhr': Icons.light_mode_rounded,
    'Asr': Icons.wb_cloudy_rounded,
    'Maghrib': Icons.nights_stay_outlined,
    'Isha': Icons.bedtime_rounded,
  };

  @override
  void initState() {
    super.initState();
    PrayerRepository.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PrayerData?>(
      valueListenable: PrayerRepository.data,
      builder: (context, data, _) {
        final next = data?.nextPrayer();
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            onTap: () =>
                Navigator.of(context).pushNamed(Routes.prayerTimes),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.mosque_rounded,
                        size: 18, color: context.colors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(context.l10n.prayerTimes,
                        style: context.text.titleSmall),
                    const Spacer(),
                    Text(
                      next != null
                          ? context.l10n.prayerIn(
                              context.l10n.prayerName(next.$1),
                              next.$3.inHours,
                              next.$3.inMinutes % 60)
                          : '…',
                      style: context.text.labelMedium
                          ?.copyWith(color: context.colors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (data == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      for (final name in PrayerData.orderedNames
                          .where((n) => n != 'Sunrise'))
                        Expanded(
                          child: _PrayerCell(
                            name: name,
                            time: data.timings[name]!,
                            icon: _icons[name] ?? Icons.mosque_rounded,
                            passed: data.passed(name),
                            highlight: name == next?.$1,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrayerCell extends StatelessWidget {
  final String name;
  final String time;
  final IconData icon;
  final bool passed;
  final bool highlight;

  const _PrayerCell({
    required this.name,
    required this.time,
    required this.icon,
    required this.passed,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight
            ? colors.primary
            : colors.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 18,
              color: highlight
                  ? Colors.white
                  : passed
                      ? colors.onSurfaceVariant.withOpacity(0.5)
                      : colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.prayerName(name),
              style: context.text.labelSmall?.copyWith(
                  color: highlight
                      ? Colors.white
                      : colors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(time,
              style: context.text.labelMedium?.copyWith(
                  color: highlight ? Colors.white : colors.onSurface)),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickAction(this.icon, this.label, this.color, this.route);
}

/// Quick actions: 2×3 gradient tiles, every one a working shortcut.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = <_QuickAction>[
      _QuickAction(Icons.explore_rounded, l10n.qibla,
          const Color(0xFF3B82F6), Routes.qibla),
      _QuickAction(Icons.radio_button_checked_rounded, l10n.tasbeeh,
          const Color(0xFF0E9D7B), Routes.tasbeeh),
      _QuickAction(Icons.volunteer_activism_rounded, l10n.duas,
          const Color(0xFFE3B23C), Routes.duas),
      _QuickAction(Icons.format_quote_rounded, l10n.hadith,
          const Color(0xFF8B5CF6), Routes.hadith),
      _QuickAction(Icons.mosque_rounded, l10n.prayers,
          const Color(0xFFEF4444), Routes.prayerTimes),
      _QuickAction(Icons.search_rounded, l10n.search,
          const Color(0xFF06B6D4), Routes.search),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.55,
        children: [
          for (final a in actions)
            AnimatedPress(
              onTap: () => Navigator.of(context).pushNamed(a.route),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      a.color.withOpacity(0.16),
                      a.color.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: a.color.withOpacity(0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [a.color, Color.lerp(a.color, Colors.black, 0.25)!],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: a.color.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(a.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(a.label,
                        style: context.text.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ayah of the day — served by the backend, rotates daily. Copy and
/// bookmark buttons really work.
class DailyVerseCard extends StatefulWidget {
  const DailyVerseCard({super.key});

  @override
  State<DailyVerseCard> createState() => _DailyVerseCardState();
}

class _DailyVerseCardState extends State<DailyVerseCard> {
  DailyVerse? _verse;
  bool _loaded = false;
  bool _bookmarked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final verse = await ContentRepository().verseOfDay(lang);
      if (!mounted || verse == null) return;
      setState(() => _verse = verse);
      final keys = AuthSession.isLoggedIn
          ? await QuranRepository().fetchBookmarkKeys()
          : await LocalBookmarks.load();
      if (mounted) {
        setState(() => _bookmarked = keys.contains(
            LocalBookmarks.ayahKey(verse.surahNumber, verse.number)));
      }
    } catch (_) {
      // Offline — fall back to the bundled verse below.
    }
  }

  Future<void> _copy() async {
    final v = _verse;
    if (v == null) return;
    final text =
        '${v.arabic}\n\n${v.translation}\n\n— ${v.surahName} ${v.surahNumber}:${v.number}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) context.showSnack(context.l10n.copied);
  }

  Future<void> _toggleBookmark() async {
    final v = _verse;
    if (v == null) return;
    final key = LocalBookmarks.ayahKey(v.surahNumber, v.number);
    final was = _bookmarked;
    setState(() => _bookmarked = !was);
    try {
      if (AuthSession.isLoggedIn) {
        was
            ? await QuranRepository()
                .removeBookmark(v.surahNumber, ayahNumber: v.number)
            : await QuranRepository()
                .addBookmark(v.surahNumber, ayahNumber: v.number);
      } else {
        await LocalBookmarks.toggle(key);
      }
    } catch (_) {
      if (mounted) setState(() => _bookmarked = was); // revert
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _verse;
    // Hidden until the backend serves today's verse — no bundled content.
    if (v == null) return const SizedBox.shrink();
    final arabic = v.arabic;
    final translation = v.translation;
    final reference = '${v.surahName} ${v.surahNumber}:${v.number}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 18, color: context.colors.tertiary),
                const SizedBox(width: AppSpacing.sm),
                Text(context.l10n.verseOfTheDay,
                    style: context.text.titleSmall),
                const Spacer(),
                InkWell(
                  onTap: _copy,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.copy_rounded,
                        size: 19, color: context.colors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                InkWell(
                  onTap: _toggleBookmark,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: _bookmarked
                          ? context.colors.tertiary
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: Text(
                arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTypography.arabicDisplay(context),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('“$translation”',
                style: context.text.bodyMedium?.copyWith(height: 1.6)),
            const SizedBox(height: AppSpacing.sm),
            Text(reference,
                style: context.text.labelMedium
                    ?.copyWith(color: context.colors.primary)),
          ],
        ),
      ),
    );
  }
}

/// Hadith of the day — served by the backend (admin-managed), rotates
/// daily. Hidden while the hadith DB is empty.
class DailyHadithCard extends StatefulWidget {
  const DailyHadithCard({super.key});

  @override
  State<DailyHadithCard> createState() => _DailyHadithCardState();
}

class _DailyHadithCardState extends State<DailyHadithCard> {
  HadithItem? _hadith;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final item = await ContentRepository().hadithOfDay(lang);
      if (mounted && item != null) setState(() => _hadith = item);
    } catch (_) {
      // Offline / empty DB — card stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final hadith = _hadith;
    if (hadith == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        onTap: () => Navigator.of(context).pushNamed(Routes.hadith),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded,
                    size: 18, color: context.colors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Text(context.l10n.hadithOfTheDay,
                    style: context.text.titleSmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(hadith.grade,
                      style: context.text.labelSmall
                          ?.copyWith(color: const Color(0xFF166534))),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('“${hadith.translation}”',
                style: context.text.bodyLarge?.copyWith(height: 1.6)),
            const SizedBox(height: AppSpacing.sm),
            Text('${hadith.book} №${hadith.hadithNumber} — ${hadith.narrator}',
                style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Recently-read surahs with real reading progress (signed-in users get
/// the full server history; guests see their last-read surah). The whole
/// section hides itself while there is nothing to show.
class RecentSurahsRow extends StatefulWidget {
  const RecentSurahsRow({super.key});

  @override
  State<RecentSurahsRow> createState() => _RecentSurahsRowState();
}

class _RecentSurahsRowState extends State<RecentSurahsRow> {
  List<(Surah, double)>? _recents;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final surahs = await QuranRepository().fetchSurahs(lang);
      final byNumber = {for (final s in surahs) s.number: s};
      final recents = <(Surah, double)>[];

      if (AuthSession.isLoggedIn) {
        final items = await QuranRepository().fetchProgress();
        for (final p in items.take(10)) {
          final s = byNumber[p.surahNumber];
          if (s != null) recents.add((s, p.progress));
        }
      } else {
        final last = await LastRead.surahNumber();
        final s = byNumber[last];
        if (s != null) recents.add((s, 1));
      }
      if (mounted && recents.isNotEmpty) {
        setState(() => _recents = recents);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final recents = _recents;
    if (recents == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Text(context.l10n.recentlyOpened,
              style: context.text.titleLarge),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: recents.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final (surah, progress) = recents[index];
              return SizedBox(
                width: 150,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  onTap: () => Navigator.of(context)
                      .pushNamed(Routes.surahDetails, arguments: surah),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${surah.number}'.padLeft(3, '0'),
                              style: context.text.labelSmall?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                          ProgressRing(
                              progress: progress,
                              size: 28,
                              strokeWidth: 3.5),
                        ],
                      ),
                      const Spacer(),
                      Text(surah.name,
                          style: context.text.titleSmall,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(context.l10n.versesCount(surah.verses),
                          style: context.text.bodySmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

/// The course you're furthest into, with your real streak — taps through
/// to that course. Hidden until courses load.
class LearningProgressCard extends StatefulWidget {
  const LearningProgressCard({super.key});

  @override
  State<LearningProgressCard> createState() =>
      _LearningProgressCardState();
}

class _LearningProgressCardState extends State<LearningProgressCard> {
  CourseItem? _course;
  int _done = 0;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final courses = await ContentRepository().lessons(lang);
      if (courses.isEmpty) return;
      final byCourse = AuthSession.isLoggedIn
          ? (await ContentRepository().lessonProgress()).byCourse
          : await GuestStats.lessonsByCourse();

      // The most-progressed course, else the first one.
      CourseItem best = courses.first;
      var bestDone = byCourse[best.id] ?? 0;
      for (final c in courses) {
        final done = byCourse[c.id] ?? 0;
        if (done > bestDone) {
          best = c;
          bestDone = done;
        }
      }
      if (mounted) {
        setState(() {
          _course = best;
          _done = bestDone;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    if (course == null) return const SizedBox.shrink();
    final total = course.totalLessons;
    final progress = total == 0 ? 0.0 : (_done / total).clamp(0.0, 1.0);
    final streak = AuthSession.user.value?.streak ??
        GuestStats.data.value.streak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Text(context.l10n.learningProgress,
              style: context.text.titleLarge),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(course: course)));
              _load(); // refresh after studying
            },
            child: Row(
              children: [
                ProgressRing(
                  progress: progress,
                  size: 84,
                  strokeWidth: 8,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(progress * 100).round()}%',
                          style: context.text.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title, style: context.text.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(context.l10n.lessonsCompleted(_done, total),
                          style: context.text.bodySmall),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 18, color: context.colors.tertiary),
                          const SizedBox(width: AppSpacing.xs),
                          Text('🔥 $streak',
                              style: context.text.labelMedium?.copyWith(
                                  color: context.colors.tertiary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _Goal {
  final String label;
  final int done;
  final int target;
  final IconData icon;
  const _Goal(this.label, this.done, this.target, this.icon);

  double get value => (done / target).clamp(0.0, 1.0);
}

/// Daily goals driven by what you actually did today on this phone:
/// verses read, recitation practice and finished lessons.
class DailyGoalsCard extends StatefulWidget {
  const DailyGoalsCard({super.key});

  @override
  State<DailyGoalsCard> createState() => _DailyGoalsCardState();
}

class _DailyGoalsCardState extends State<DailyGoalsCard> {
  int _verses = 0;
  int _recitations = 0;
  int _lessons = 0;

  @override
  void initState() {
    super.initState();
    TodayActivity.load().then((v) {
      if (mounted) {
        setState(() {
          _verses = v.$1;
          _recitations = v.$2;
          _lessons = v.$3;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final goals = <_Goal>[
      _Goal(l10n.goalRead10, _verses, 10, Icons.menu_book_rounded),
      _Goal(l10n.goalPractice, _recitations, 1, Icons.mic_rounded),
      _Goal(l10n.goalLesson, _lessons, 1, Icons.school_rounded),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            for (var i = 0; i < goals.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              _GoalRow(goal: goals[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final _Goal goal;
  const _GoalRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    final done = goal.value >= 1;
    final color = done ? AppColors.success : context.colors.primary;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          ),
          child: Icon(done ? Icons.check_rounded : goal.icon,
              color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(goal.label, style: context.text.titleSmall),
                  Text('${goal.done} / ${goal.target}',
                      style: context.text.labelSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: goal.value,
                  minHeight: 6,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
