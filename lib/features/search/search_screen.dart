import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_models.dart';
import '../../shared/data/content_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/app_search_bar.dart';
import '../../shared/widgets/skeleton.dart';
import '../../theme/app_typography.dart';
import '../quran/data/quran_repository.dart';

/// Global search across the real database content — surahs, hadiths and
/// duas — with persistent recent searches.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  int _scope = 0;
  bool _loading = true;

  List<Surah> _surahs = const [];
  List<HadithItem> _hadiths = const [];
  List<DuaItem> _duas = const [];
  List<String> _recent = AppPrefs.recentSearches;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    final lang = Localizations.localeOf(context).languageCode;
    // Each source is independent — one failing must not empty the others.
    final results = await Future.wait<Object?>([
      QuranRepository().fetchSurahs(lang).catchError((_) => <Surah>[]),
      ContentRepository().hadiths(lang).catchError((_) => <HadithItem>[]),
      ContentRepository().duas(lang).catchError((_) => <DuaItem>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _surahs = results[0] as List<Surah>;
      _hadiths = results[1] as List<HadithItem>;
      _duas = results[2] as List<DuaItem>;
      _loading = false;
    });
  }

  void _search(String value) {
    setState(() => _query = value);
    if (value.trim().length >= 2) {
      AppPrefs.addRecentSearch(value).then((_) {
        if (mounted) setState(() => _recent = AppPrefs.recentSearches);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scopes = [l10n.all, l10n.surahs, l10n.hadithPlural, l10n.duasPlural];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.search)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
              child: AppSearchBar(
                hint: l10n.searchGlobalHint,
                autofocus: true,
                onChanged: _search,
              ),
            ),
            ChipFilterRow(
              items: scopes,
              selectedIndex: _scope,
              onSelected: (i) => setState(() => _scope = i),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _query.isEmpty
                  ? _RecentSearches(
                      items: _recent,
                      onPick: _search,
                      onClear: () async {
                        await AppPrefs.clearRecentSearches();
                        if (mounted) setState(() => _recent = const []);
                      },
                    )
                  : _loading
                      ? const SkeletonList()
                      : _Results(
                          query: _query,
                          scope: _scope,
                          surahs: _surahs,
                          hadiths: _hadiths,
                          duas: _duas,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;
  const _RecentSearches({
    required this.items,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.recentSearches,
                style: context.text.titleMedium),
            InkWell(
              onTap: onClear,
              child: Text(context.l10n.clear,
                  style: context.text.labelMedium
                      ?.copyWith(color: context.colors.primary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => onPick(item),
            leading: Icon(Icons.history_rounded,
                color: context.colors.onSurfaceVariant, size: 22),
            title: Text(item, style: context.text.bodyLarge),
            trailing: Icon(Icons.north_west_rounded,
                color: context.colors.onSurfaceVariant, size: 18),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  final String query;
  final int scope;
  final List<Surah> surahs;
  final List<HadithItem> hadiths;
  final List<DuaItem> duas;

  const _Results({
    required this.query,
    required this.scope,
    required this.surahs,
    required this.hadiths,
    required this.duas,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final surahHits = (scope == 0 || scope == 1)
        ? surahs
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                s.meaning.toLowerCase().contains(q) ||
                s.arabicName.contains(query))
            .take(6)
            .toList()
        : <Surah>[];
    final hadithHits = (scope == 0 || scope == 2)
        ? hadiths
            .where((h) =>
                h.translation.toLowerCase().contains(q) ||
                h.narrator.toLowerCase().contains(q) ||
                h.book.toLowerCase().contains(q))
            .take(4)
            .toList()
        : <HadithItem>[];
    final duaHits = (scope == 0 || scope == 3)
        ? duas
            .where((d) =>
                d.title.toLowerCase().contains(q) ||
                d.translation.toLowerCase().contains(q))
            .take(4)
            .toList()
        : <DuaItem>[];

    if (surahHits.isEmpty && hadithHits.isEmpty && duaHits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: context.colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.noResultsFor(query),
                style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.tryDifferent,
                style: context.text.bodySmall),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen,
          AppSpacing.xxl + context.padding.bottom),
      children: [
        if (surahHits.isNotEmpty) ...[
          Text(context.l10n.surahs, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final surah in surahHits)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                shadow: false,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                onTap: () => Navigator.of(context)
                    .pushNamed(Routes.surahDetails, arguments: surah),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          context.colors.primary.withOpacity(0.1),
                      child: Text('${surah.number}',
                          style: context.text.labelMedium?.copyWith(
                              color: context.colors.primary)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(surah.name,
                              style: context.text.titleSmall),
                          Text(
                              '${surah.meaning} • ${context.l10n.versesCount(surah.verses)}',
                              style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    Text(surah.arabicName,
                        style: AppTypography.arabicTitle(context)
                            .copyWith(fontSize: 17)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (hadithHits.isNotEmpty) ...[
          Text(context.l10n.hadithPlural,
              style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final hadith in hadithHits)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                shadow: false,
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.hadith),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('“${hadith.translation}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${hadith.book} №${hadith.hadithNumber}',
                        style: context.text.labelSmall),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (duaHits.isNotEmpty) ...[
          Text(context.l10n.duasPlural,
              style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final dua in duaHits)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                shadow: false,
                onTap: () => Navigator.of(context).pushNamed(Routes.duas),
                child: Row(
                  children: [
                    Icon(Icons.volunteer_activism_rounded,
                        size: 20, color: context.colors.tertiary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dua.title, style: context.text.titleSmall),
                          Text(context.l10n.duaCategory(dua.category),
                              style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
