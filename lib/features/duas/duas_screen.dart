import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_repository.dart';
import '../../shared/data/content_models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chip.dart';
import '../../theme/app_typography.dart';

/// Daily duas grouped by category, expandable cards with Arabic,
/// transliteration and translation. Content is fully admin-managed —
/// an empty database shows an empty state, never bundled content.
class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  static const _categories = [
    'All', 'Morning', 'Evening', 'Travel', 'Food',
    'Sleep', 'Protection', 'Forgiveness',
  ];

  int _category = 0;
  int? _expanded = 0;
  List<DuaItem>? _duas; // null = loading

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_duas == null) _load();
  }

  Future<void> _load() async {
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final items = await ContentRepository().duas(lang);
      if (!mounted) return;
      setState(() => _duas = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _duas = const []); // offline / empty
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _categories[_category];
    final items = (_duas ?? const <DuaItem>[])
        .where((d) => _category == 0 || d.category == selected)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dailyDuas)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            ChipFilterRow(
              items: [
                for (final c in _categories)
                  context.l10n.duaCategory(c),
              ],
              selectedIndex: _category,
              onSelected: (i) => setState(() {
                _category = i;
                _expanded = 0;
              }),
            ),
            if (_duas == null)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Text(context.l10n.noDuasYet,
                      style: context.text.bodyMedium),
                ),
              )
            else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.xl,
                    AppSpacing.screen,
                    AppSpacing.xxl + context.padding.bottom),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => _DuaCard(
                  dua: items[index],
                  expanded: _expanded == index,
                  onTap: () => setState(
                      () => _expanded = _expanded == index ? null : index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final DuaItem dua;
  final bool expanded;
  final VoidCallback onTap;

  const _DuaCard({
    required this.dua,
    required this.expanded,
    required this.onTap,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(
        text:
            '${dua.arabic}\n\n${dua.transliteration}\n\n${dua.translation}'));
    if (context.mounted) context.showSnack(context.l10n.copied);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.tertiary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: Icon(Icons.volunteer_activism_rounded,
                    color: colors.tertiary, size: 20),
              ),
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
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: AppDurations.normal,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: colors.onSurfaceVariant),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: AppDurations.normal,
            sizeCurve: AppCurves.enter,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      dua.arabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.arabicDisplay(context)
                          .copyWith(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    dua.transliteration,
                    style: context.text.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(dua.translation,
                      style:
                          context.text.bodyMedium?.copyWith(height: 1.6)),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      const Spacer(),
                      InkWell(
                        onTap: () => _copy(context),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.copy_rounded,
                              size: 18, color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
