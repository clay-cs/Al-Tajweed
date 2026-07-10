import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/guest_stats.dart';
import '../../shared/data/local_bookmarks.dart';
import '../../shared/data/content_models.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/app_search_bar.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../theme/app_typography.dart';
import '../auth/data/auth_repository.dart';
import 'data/quran_repository.dart';

/// Quran tab. The surah list comes from the database (admin-managed);
/// when the DB has no content yet, an explicit empty state is shown.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String _query = '';
  int _juz = 0;
  Set<String> _bookmarks = {};
  Set<int> _completed = {};
  String? _lastRead;

  List<Surah>? _surahs; // null = loading
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    LastRead.load().then((v) {
      if (mounted) setState(() => _lastRead = v);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_surahs == null && !_error) _load();
  }

  Future<void> _load() async {
    setState(() {
      _surahs = null;
      _error = false;
    });
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final items = await QuranRepository().fetchSurahs(lang);
      if (!mounted) return;
      setState(() => _surahs = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final keys = AuthSession.isLoggedIn
          ? await QuranRepository().fetchBookmarkKeys()
          : await LocalBookmarks.load();
      if (mounted) setState(() => _bookmarks = keys);
    } catch (_) {
      // Offline — start empty, toggling still persists locally.
    }
    try {
      final done = AuthSession.isLoggedIn
          ? await QuranRepository().fetchCompletedSurahs()
          : await GuestStats.completedSurahs();
      if (mounted) setState(() => _completed = done);
    } catch (_) {}
  }

  Future<void> _toggleBookmark(Surah surah) async {
    final key = LocalBookmarks.surahKey(surah.number);
    final was = _bookmarks.contains(key);
    setState(() => was ? _bookmarks.remove(key) : _bookmarks.add(key));
    try {
      if (AuthSession.isLoggedIn) {
        was
            ? await QuranRepository().removeBookmark(surah.number)
            : await QuranRepository().addBookmark(surah.number);
      } else {
        await LocalBookmarks.toggle(key);
      }
    } catch (_) {
      if (mounted) {
        setState(() => was ? _bookmarks.add(key) : _bookmarks.remove(key));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final juzFilters = <String>[
      context.l10n.all,
      for (var i = 1; i <= 30; i++) context.l10n.juzN(i),
    ];
    final surahs = (_surahs ?? const <Surah>[])
        .where((s) =>
            _juz == 0 ||
            s.juzStart == 0 || // no juz info — never hide the surah
            (s.juzStart <= _juz && _juz <= s.juzEnd))
        .where((s) =>
            _query.isEmpty ||
            s.name.toLowerCase().contains(_query.toLowerCase()) ||
            s.meaning.toLowerCase().contains(_query.toLowerCase()) ||
            '${s.number}' == _query)
        .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                    AppSpacing.lg, AppSpacing.screen, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n.theQuran,
                            style: context.text.headlineLarge),
                        IconButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(Routes.search),
                          icon: const Icon(Icons.manage_search_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSearchBar(
                      hint: context.l10n.searchSurahHint,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ChipFilterRow(
                items: juzFilters,
                selectedIndex: _juz,
                onSelected: (i) => setState(() => _juz = i),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl)),
            SliverToBoxAdapter(
                child: _ReadingProgressHeader(lastRead: _lastRead)),
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl)),
            if (_surahs == null && !_error)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error || _surahs!.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(error: _error, onRetry: _load),
              )
            else
              SliverPadding(
                padding: EdgeInsets.only(
                    left: AppSpacing.screen,
                    right: AppSpacing.screen,
                    bottom: 120 + context.padding.bottom),
                sliver: SliverList.separated(
                  itemCount: surahs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return _SurahTile(
                      surah: surah,
                      bookmarked: _bookmarks
                          .contains(LocalBookmarks.surahKey(surah.number)),
                      completed: _completed.contains(surah.number),
                      onBookmark: () => _toggleBookmark(surah),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the database has no surahs yet (or the server is unreachable).
class _EmptyState extends StatelessWidget {
  final bool error;
  final VoidCallback onRetry;

  const _EmptyState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              error ? Icons.wifi_off_rounded : Icons.menu_book_rounded,
              size: 38,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            error ? l10n.networkError : l10n.dbEmptyTitle,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error ? '' : l10n.dbEmptyBody,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.retry,
            expanded: false,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Khatmah progress + last-read shortcut — driven by real reading stats.
class _ReadingProgressHeader extends StatelessWidget {
  final String? lastRead;
  const _ReadingProgressHeader({this.lastRead});

  @override
  Widget build(BuildContext context) {
    // Pages read: server-computed for users, phone-tracked for guests.
    final user = AuthSession.user.value;
    final pagesRead = user?.pagesRead ?? GuestStats.data.value.pagesRead;
    final progress = (pagesRead / 604).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            ProgressRing(
              progress: progress,
              size: 58,
              strokeWidth: 6,
              center: Text('${(progress * 100).round()}%',
                  style: context.text.labelMedium),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.khatmahProgress,
                      style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text('$pagesRead / 604', style: context.text.bodySmall),
                ],
              ),
            ),
            if (lastRead != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(context.l10n.lastRead,
                      style: context.text.labelSmall),
                  const SizedBox(height: 2),
                  Text(lastRead!,
                      style: context.text.labelMedium
                          ?.copyWith(color: context.colors.primary)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final Surah surah;
  final bool bookmarked;
  final bool completed;
  final VoidCallback onBookmark;

  const _SurahTile({
    required this.surah,
    required this.bookmarked,
    required this.completed,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      shadow: false,
      onTap: () => Navigator.of(context)
          .pushNamed(Routes.surahDetails, arguments: surah),
      child: Row(
        children: [
          // Number in an eight-point-star-like rotated square
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: 0.785398, // 45°
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                      border:
                          Border.all(color: colors.primary.withOpacity(0.35)),
                    ),
                  ),
                ),
                Text('${surah.number}',
                    style: context.text.labelMedium
                        ?.copyWith(color: colors.primary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                        child: Text(surah.name,
                            style: context.text.titleSmall,
                            overflow: TextOverflow.ellipsis)),
                    if (completed) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.verified_rounded,
                          size: 15, color: context.colors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.l10n.revelation(surah.revelation)} • ${context.l10n.versesCount(surah.verses)}',
                  style: context.text.bodySmall,
                ),
                if (surah.progress > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                        value: surah.progress, minHeight: 4),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(surah.arabicName,
              style: AppTypography.arabicTitle(context)
                  .copyWith(fontSize: 18, color: colors.primary)),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onBookmark,
            child: Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 22,
              color: bookmarked ? colors.tertiary : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
