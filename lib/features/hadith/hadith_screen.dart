import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_models.dart';
import '../../shared/data/content_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/app_search_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../auth/data/auth_repository.dart';

/// Hadith browser: admin-managed library from the backend with book filter
/// chips and search. Tapping a hadith opens the full detail sheet (book,
/// chapter, numbers, narrator, grade, both translations, tags) and records
/// it as read.
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  int _book = 0;
  String _query = '';
  List<HadithItem>? _hadiths; // null = loading
  final _read = <String>{}; // ids marked read this session

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hadiths == null) _load();
  }

  Future<void> _load() async {
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final items = await ContentRepository().hadiths(lang);
      if (mounted) setState(() => _hadiths = items);
    } catch (_) {
      if (mounted) setState(() => _hadiths = const []);
    }
  }

  /// Book names derived from the actual data, "All" first.
  List<String> get _books => [
        context.l10n.all,
        ...{for (final h in _hadiths ?? const <HadithItem>[]) h.book},
      ];

  Future<void> _open(HadithItem hadith) async {
    // Opening the detail view counts as reading it (once per hadith).
    final id = hadith.id;
    if (id != null && !_read.contains(id)) {
      setState(() => _read.add(id));
      if (AuthSession.isLoggedIn) {
        ContentRepository().markHadithRead(id).catchError((_) {});
      }
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HadithDetailSheet(hadith: hadith),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _hadiths;
    final books = _books;
    final items = (all ?? const <HadithItem>[]).where((h) {
      final byBook = _book == 0 || h.book == books[_book];
      final q = _query.toLowerCase();
      final byQuery = q.isEmpty ||
          h.translation.toLowerCase().contains(q) ||
          h.narrator.toLowerCase().contains(q) ||
          h.chapter.toLowerCase().contains(q) ||
          h.tags.any((t) => t.toLowerCase().contains(q));
      return byBook && byQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.hadith)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
              child: AppSearchBar(
                hint: context.l10n.searchHadithHint,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (books.length > 1)
              ChipFilterRow(
                items: books,
                selectedIndex: _book,
                onSelected: (i) => setState(() => _book = i),
              ),
            Expanded(
              child: all == null
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? Center(
                          child: Text(context.l10n.noHadithFound,
                              style: context.text.bodyMedium))
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                              AppSpacing.screen,
                              AppSpacing.xl,
                              AppSpacing.screen,
                              AppSpacing.xxl + context.padding.bottom),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.lg),
                          itemBuilder: (context, index) => _HadithCard(
                            hadith: items[index],
                            read: _read.contains(items[index].id),
                            onOpen: () => _open(items[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  final HadithItem hadith;
  final bool read;
  final VoidCallback onOpen;

  const _HadithCard({
    required this.hadith,
    required this.read,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.format_quote_rounded,
                    color: colors.secondary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${hadith.book} • №${hadith.hadithNumber}',
                        style: context.text.titleSmall),
                    Text(
                      hadith.chapter.isNotEmpty
                          ? hadith.chapter
                          : hadith.narrator,
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GradeBadge(grade: hadith.grade),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: Text(
              hadith.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTypography.arabicDisplay(context).copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('“${hadith.translation}”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(height: 1.6)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (hadith.tags.isNotEmpty)
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final tag in hadith.tags.take(3))
                        _TagChip(tag: tag),
                    ],
                  ),
                )
              else
                const Spacer(),
              read
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: AppSpacing.xs),
                        Text(context.l10n.hadithRead,
                            style: context.text.labelMedium
                                ?.copyWith(color: AppColors.success)),
                      ],
                    )
                  : Text(context.l10n.readMore,
                      style: context.text.labelMedium
                          ?.copyWith(color: colors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.colors.primary.withOpacity(0.25)),
      ),
      child: Text('#$tag',
          style: context.text.labelSmall
              ?.copyWith(color: context.colors.primary)),
    );
  }
}

class GradeBadge extends StatelessWidget {
  final String grade;
  const GradeBadge({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    final sahih = grade == 'Sahih';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: sahih ? AppColors.successContainer : AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        grade,
        style: context.text.labelSmall?.copyWith(
            color:
                sahih ? const Color(0xFF166534) : const Color(0xFF92400E)),
      ),
    );
  }
}

/// Full hadith detail: book, chapter, numbers, narrator, grade, Arabic,
/// both translations and tags — with a working copy button.
class HadithDetailSheet extends StatelessWidget {
  final HadithItem hadith;
  const HadithDetailSheet({super.key, required this.hadith});

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(
        text: '${hadith.arabic}\n\n'
            '${hadith.uzbek}\n\n'
            '${hadith.english}\n\n'
            '— ${hadith.book} №${hadith.hadithNumber}'
            '${hadith.chapter.isNotEmpty ? ' (${hadith.chapter})' : ''}, '
            '${hadith.narrator}'));
    if (context.mounted) context.showSnack(l10n.copied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl + context.padding.bottom),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outline,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Header: book + grade
          Row(
            children: [
              Expanded(
                child: Text('${hadith.book} • №${hadith.hadithNumber}',
                    style: context.text.titleLarge),
              ),
              GradeBadge(grade: hadith.grade),
              const SizedBox(width: AppSpacing.md),
              InkWell(
                onTap: () => _copy(context),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded,
                      size: 20, color: context.colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Info rows
          _InfoRow(
              icon: Icons.menu_book_rounded,
              label: l10n.bookLabel,
              value:
                  '${hadith.book} (${l10n.bookNumberLabel.toLowerCase()}: ${hadith.bookNumber})'),
          if (hadith.chapter.isNotEmpty)
            _InfoRow(
                icon: Icons.bookmark_outline_rounded,
                label: l10n.chapterLabel,
                value: hadith.chapter),
          _InfoRow(
              icon: Icons.tag_rounded,
              label: l10n.hadithNumberLabel,
              value: '${hadith.hadithNumber}'),
          if (hadith.narrator.isNotEmpty)
            _InfoRow(
                icon: Icons.person_outline_rounded,
                label: l10n.narratorLabel,
                value: hadith.narrator),
          _InfoRow(
              icon: Icons.verified_outlined,
              label: l10n.gradeLabel,
              value: hadith.grade),
          const SizedBox(height: AppSpacing.xl),

          // Arabic
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                hadith.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTypography.arabicDisplay(context)
                    .copyWith(fontSize: 26, height: 1.9),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Uzbek translation
          if (hadith.uzbek.isNotEmpty) ...[
            Text(l10n.uzbekTranslation, style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('“${hadith.uzbek}”',
                style: context.text.bodyLarge?.copyWith(height: 1.6)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // English translation
          if (hadith.english.isNotEmpty) ...[
            Text(l10n.englishTranslation, style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('“${hadith.english}”',
                style: context.text.bodyMedium?.copyWith(
                    height: 1.6, color: context.colors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Tags
          if (hadith.tags.isNotEmpty) ...[
            Text(l10n.tagsLabel, style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final tag in hadith.tags) _TagChip(tag: tag)],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 110,
            child: Text(label,
                style: context.text.labelMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: context.text.bodyMedium),
          ),
        ],
      ),
    );
  }
}
