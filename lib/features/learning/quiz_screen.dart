import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_repository.dart';
import '../../shared/data/stats_repository.dart';
import '../../shared/widgets/animated_press.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../theme/app_colors.dart';

/// Daily quiz. Questions come from the backend (admin-managed, localized) —
/// no bundled questions. Results are logged to the server for signed-in
/// users and to phone storage for guests.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestionItem>? _questions;
  int _index = 0;
  int? _selected;
  int _correct = 0;
  bool _finished = false;
  bool _logged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questions == null) _load();
  }

  Future<void> _load() async {
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final items = await ContentRepository().dailyQuiz(lang);
      if (!mounted) return;
      setState(() => _questions = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _questions = const []); // offline / empty
    }
  }

  QuizQuestionItem get _question => _questions![_index];

  void _select(int i) {
    if (_selected != null) return;
    setState(() {
      _selected = i;
      if (i == _question.answer) _correct++;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        if (_index == _questions!.length - 1) {
          _finished = true;
          _logResult();
        } else {
          _index++;
          _selected = null;
        }
      });
    });
  }

  void _logResult() {
    if (_logged) return;
    _logged = true;
    StatsRepository()
        .logQuiz(
          correct: _correct,
          total: _questions!.length,
          xpEarned: _correct * 20,
        )
        .catchError((_) {}); // fire-and-forget
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _questions != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(!loaded || _questions!.isEmpty
            ? context.l10n.dailyQuiz
            : _finished
                ? context.l10n.results
                : context.l10n.questionXofY(_index + 1, _questions!.length)),
      ),
      body: SafeArea(
        child: !loaded
            ? const Center(child: CircularProgressIndicator())
            : _questions!.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text(context.l10n.noQuizToday,
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: AppDurations.normal,
                    child: _finished
                        ? _buildResult(context)
                        : _buildQuestion(context),
                  ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final options = _question.options;
    return Padding(
      key: ValueKey('q$_index'),
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (_index + 1) / _questions!.length,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              _question.question,
              style: context.text.headlineSmall?.copyWith(height: 1.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < options.length; i++) ...[
            _OptionTile(
              label: options[i],
              index: i,
              state: _selected == null
                  ? _OptionState.idle
                  : i == _question.answer
                      ? _OptionState.correct
                      : i == _selected
                          ? _OptionState.wrong
                          : _OptionState.dimmed,
              onTap: () => _select(i),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 18, color: context.colors.tertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(context.l10n.correctSoFar(_correct),
                  style: context.text.labelMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final total = _questions!.length;
    final pct = total == 0 ? 0.0 : _correct / total;
    return Padding(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: ProgressRing(
              progress: pct,
              size: 170,
              strokeWidth: 13,
              color: pct >= 0.6 ? AppColors.success : AppColors.warning,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_correct/$total',
                      style: context.text.displayMedium),
                  Text(context.l10n.correct,
                      style: context.text.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            pct >= 0.8
                ? context.l10n.resultExcellent
                : pct >= 0.6
                    ? context.l10n.resultGood
                    : context.l10n.resultRetry,
            textAlign: TextAlign.center,
            style: context.text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.earnedXp(_correct * 20),
            textAlign: TextAlign.center,
            style: context.text.bodyMedium
                ?.copyWith(color: context.colors.tertiary),
          ),
          const Spacer(),
          AppButton(
            label: context.l10n.backToLearning,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: context.l10n.retryQuiz,
            variant: AppButtonVariant.secondary,
            onPressed: () => setState(() {
              _index = 0;
              _selected = null;
              _correct = 0;
              _finished = false;
              _logged = false;
            }),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  final String label;
  final int index;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color border, Color? fill, IconData? icon) = switch (state) {
      _OptionState.correct => (
          AppColors.success,
          AppColors.success.withOpacity(0.1),
          Icons.check_circle_rounded
        ),
      _OptionState.wrong => (
          AppColors.error,
          AppColors.error.withOpacity(0.08),
          Icons.cancel_rounded
        ),
      _ => (colors.outline, null, null),
    };

    return AnimatedPress(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: state == _OptionState.dimmed ? 0.5 : 1,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: fill ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(String.fromCharCode(65 + index),
                    style: context.text.labelMedium),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: context.text.bodyLarge)),
              if (icon != null)
                Icon(icon,
                    color: state == _OptionState.correct
                        ? AppColors.success
                        : AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}
