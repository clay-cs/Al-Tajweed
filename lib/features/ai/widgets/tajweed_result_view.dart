import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/data/content_models.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../data/tajweed_models.dart';

/// Full results screen built entirely from the real AI analysis: score ring,
/// timing, "what we heard", letter-by-letter grid and the Tajweed mistakes.
class TajweedResultView extends StatelessWidget {
  final TajweedResult result;
  final Surah surah;
  final Ayah ayah;
  final VoidCallback onTryAgain;

  const TajweedResultView({
    super.key,
    required this.result,
    required this.surah,
    required this.ayah,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
          AppSpacing.screen, 130 + context.padding.bottom),
      children: [
        _ScoreCard(
          result: result,
          label: context.l10n.surahVerse(surah.name, ayah.number),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (result.feedback.isNotEmpty) ...[
          _FeedbackCard(lines: result.feedback),
          const SizedBox(height: AppSpacing.lg),
        ],
        _LetterGrid(letters: result.letters),
        const SizedBox(height: AppSpacing.lg),
        _ErrorsCard(errors: result.errors),
        const SizedBox(height: AppSpacing.lg),
        _HeardCard(transcript: result.transcript, reference: ayah.arabic),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: context.l10n.tryAgain,
          icon: Icons.refresh_rounded,
          onPressed: onTryAgain,
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final TajweedResult result;
  final String label;
  const _ScoreCard({required this.result, required this.label});

  @override
  Widget build(BuildContext context) {
    final correct = result.letters
        .where((l) => l.status == 'correct')
        .length;
    final problems = result.letters.where((l) => l.isProblem).length;
    final missing =
        result.letters.where((l) => l.status == 'missing').length;
    return AppCard(
      gradient: AppColors.heroGradient,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Text(context.l10n.tajweedScore,
              style: context.text.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: context.text.bodySmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpacing.xl),
          ProgressRing(
            progress: result.score / 100,
            size: 150,
            strokeWidth: 12,
            color: Colors.white,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: result.score.toDouble()),
                  duration: AppDurations.slow,
                  curve: AppCurves.enter,
                  builder: (context, value, _) => Text(
                    '${value.round()}',
                    style: context.text.displayMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
                Text(context.l10n.outOf100,
                    style: context.text.labelSmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _StatPill(
                  label: context.l10n.correctLetters, value: '$correct'),
              const SizedBox(width: AppSpacing.sm),
              _StatPill(
                  label: context.l10n.problemLetters, value: '$problems'),
              const SizedBox(width: AppSpacing.sm),
              _StatPill(
                  label: context.l10n.missingLetters, value: '$missing'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${context.l10n.pronunciationAccuracy}: '
                '${(result.confidence * 100).round()}%',
                style:
                    context.text.labelMedium?.copyWith(color: Colors.white70),
              ),
              if (result.wordsPerMinute != null) ...[
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.speed_rounded,
                    size: 16, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: AppSpacing.xs),
                Text('${result.wordsPerMinute!.round()} wpm',
                    style: context.text.labelMedium
                        ?.copyWith(color: Colors.white70)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: context.text.titleLarge?.copyWith(color: Colors.white)),
            Text(label,
                textAlign: TextAlign.center,
                style: context.text.labelSmall
                    ?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final List<String> lines;
  const _FeedbackCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  i == 0
                      ? Icons.insights_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                  color: context.colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(lines[i],
                      style: i == 0
                          ? context.text.titleSmall
                          : context.text.bodyMedium?.copyWith(height: 1.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Letter-by-letter grid: each reference letter coloured by its status.
class _LetterGrid extends StatelessWidget {
  final List<TajweedLetter> letters;
  const _LetterGrid({required this.letters});

  Color _color(BuildContext context, String status) => switch (status) {
        'correct' => AppColors.success,
        'unclear' => AppColors.warning,
        'missing' => context.colors.onSurfaceVariant,
        'extra' => AppColors.info,
        _ => AppColors.error, // incorrect | substituted
      };

  @override
  Widget build(BuildContext context) {
    if (letters.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.letterAnalysis, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final l in letters)
                  _LetterChip(letter: l, color: _color(context, l.status)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendDot(color: AppColors.success, label: context.l10n.correctLetters),
              _LegendDot(color: AppColors.error, label: context.l10n.problemLetters),
              _LegendDot(
                  color: context.colors.onSurfaceVariant,
                  label: context.l10n.missingLetters),
            ],
          ),
        ],
      ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  final TajweedLetter letter;
  final Color color;
  const _LetterChip({required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    final showHeard =
        letter.heard != null && letter.heard != letter.letter;
    return Tooltip(
      message: '${context.l10n.letterStatus(letter.status)}'
          '${letter.rule != null ? ' • ${letter.rule}' : ''}'
          '${showHeard ? ' • ${letter.heard}' : ''}',
      child: Container(
        width: 44,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              letter.letter,
              style: AppTypography.arabicTitle(context)
                  .copyWith(fontSize: 22, color: color),
            ),
            if (showHeard)
              Text(letter.heard!,
                  textDirection: TextDirection.rtl,
                  style: context.text.labelSmall?.copyWith(
                      color: color.withValues(alpha: 0.8), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: context.text.labelSmall),
      ],
    );
  }
}

/// The Tajweed mistakes list — the failed rules, severity-coloured.
class _ErrorsCard extends StatelessWidget {
  final List<TajweedError> errors;
  const _ErrorsCard({required this.errors});

  Color _color(String severity) => switch (severity) {
        'high' => AppColors.error,
        'medium' => AppColors.warning,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: AppColors.success, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(context.l10n.noTajweedErrors,
                  style: context.text.titleSmall),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.l10n.areasToImprove,
                  style: context.text.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(context.l10n.nFound(errors.length),
                    style: context.text.labelSmall
                        ?.copyWith(color: const Color(0xFF92400E))),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < errors.length; i++) ...[
            if (i > 0)
              Divider(height: AppSpacing.xxl, color: context.colors.outline),
            _ErrorRow(error: errors[i], color: _color(errors[i].severity)),
          ],
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final TajweedError error;
  final Color color;
  const _ErrorRow({required this.error, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.priority_high_rounded, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(error.rule,
                          style: context.text.titleSmall)),
                  if (error.expected != null || error.observed != null)
                    Text(
                      [error.observed, error.expected]
                          .where((e) => e != null)
                          .join(' → '),
                      style: context.text.labelSmall?.copyWith(color: color),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(error.feedback,
                  style: context.text.bodySmall?.copyWith(height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

/// "What we heard" vs the reference — with a copy button.
class _HeardCard extends StatelessWidget {
  final String transcript;
  final String reference;
  const _HeardCard({required this.transcript, required this.reference});

  @override
  Widget build(BuildContext context) {
    if (transcript.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hearing_rounded,
                  size: 18, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(context.l10n.whatWeHeard, style: context.text.titleSmall),
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: transcript));
                  context.showSnack(context.l10n.copied);
                },
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded,
                      size: 18, color: context.colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: Text(
              transcript,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicDisplay(context).copyWith(fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}
