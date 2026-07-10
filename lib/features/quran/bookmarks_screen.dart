import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/local_bookmarks.dart';
import '../../shared/data/content_models.dart';
import '../../shared/widgets/app_card.dart';
import '../../theme/app_typography.dart';
import '../auth/data/auth_repository.dart';
import 'data/quran_repository.dart';
import 'surah_details_screen.dart';

/// A saved bookmark: whole surah (`ayah == null`) or a single verse.
class _BookmarkEntry {
  final Surah surah;
  final int? ayah;
  const _BookmarkEntry(this.surah, this.ayah);

  String get key => ayah == null
      ? LocalBookmarks.surahKey(surah.number)
      : LocalBookmarks.ayahKey(surah.number, ayah!);
}

/// All bookmarks (surahs + verses) — from the DB for users, from phone
/// storage for guests. Tap opens the surah; the trash icon removes it.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<_BookmarkEntry>? _entries; // null = loading
  bool _error = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entries == null && !_error) _load();
  }

  Future<void> _load() async {
    setState(() {
      _entries = null;
      _error = false;
    });
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final results = await Future.wait([
        QuranRepository().fetchSurahs(lang),
        AuthSession.isLoggedIn
            ? QuranRepository().fetchBookmarkKeys()
            : LocalBookmarks.load(),
      ]);
      final surahs = {
        for (final s in results[0] as List<Surah>) s.number: s,
      };
      final keys = results[1] as Set<String>;

      final entries = <_BookmarkEntry>[];
      for (final key in keys) {
        final parts = key.split(':');
        final surah = surahs[int.tryParse(parts[0])];
        if (surah == null) continue; // surah removed from the DB
        entries.add(_BookmarkEntry(
            surah, parts.length > 1 ? int.tryParse(parts[1]) : null));
      }
      entries.sort((a, b) {
        final s = a.surah.number.compareTo(b.surah.number);
        return s != 0 ? s : (a.ayah ?? 0).compareTo(b.ayah ?? 0);
      });
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  Future<void> _remove(_BookmarkEntry entry) async {
    setState(() => _entries = [..._entries!]..remove(entry));
    try {
      if (AuthSession.isLoggedIn) {
        await QuranRepository()
            .removeBookmark(entry.surah.number, ayahNumber: entry.ayah);
      } else {
        await LocalBookmarks.toggle(entry.key);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _entries = [..._entries!, entry]); // revert
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookmarks)),
      body: SafeArea(
        child: entries == null && !_error
            ? const Center(child: CircularProgressIndicator())
            : _error
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 44,
                            color: context.colors.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.lg),
                        Text(l10n.networkError,
                            style: context.text.titleMedium),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  )
                : entries!.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_border_rounded,
                                  size: 52,
                                  color: context.colors.onSurfaceVariant),
                              const SizedBox(height: AppSpacing.lg),
                              Text(l10n.bookmarksEmpty,
                                  style: context.text.titleLarge),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.bookmarksEmptyBody,
                                textAlign: TextAlign.center,
                                style: context.text.bodyMedium?.copyWith(
                                    color:
                                        context.colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.lg,
                            AppSpacing.screen,
                            AppSpacing.xxl + context.padding.bottom),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return AppCard(
                            shadow: false,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SurahDetailsScreen(
                                    surah: entry.surah),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  entry.ayah == null
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_added_rounded,
                                  color: context.colors.tertiary,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.surah.name,
                                          style: context.text.titleSmall),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.ayah == null
                                            ? l10n.wholeSurah
                                            : l10n.ayahRef(
                                                entry.surah.number,
                                                entry.ayah!),
                                        style: context.text.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  entry.surah.arabicName,
                                  style: AppTypography.arabicTitle(context)
                                      .copyWith(
                                          fontSize: 18,
                                          color: context.colors.primary),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                IconButton(
                                  onPressed: () => _remove(entry),
                                  icon: Icon(Icons.delete_outline_rounded,
                                      size: 22,
                                      color:
                                          context.colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
