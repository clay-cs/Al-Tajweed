import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/stats_repository.dart';
import '../../shared/widgets/animated_press.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class _Dhikr {
  final String arabic;
  final String name;
  final int target;
  const _Dhikr(this.arabic, this.name, this.target);
}

const _adhkar = <_Dhikr>[
  _Dhikr('سُبْحَانَ اللَّهِ', 'SubhanAllah', 33),
  _Dhikr('الْحَمْدُ لِلَّهِ', 'Alhamdulillah', 33),
  _Dhikr('اللَّهُ أَكْبَرُ', 'Allahu Akbar', 34),
  _Dhikr('أَسْتَغْفِرُ اللَّهَ', 'Astaghfirullah', 100),
];

/// Digital tasbeeh: giant tap surface, animated count ring, dhikr presets
/// and haptic feedback on every count.
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _dhikrIndex = 0;
  int _count = 0;
  int _rounds = 0;
  int _sessionTotal = 0;

  _Dhikr get _dhikr => _adhkar[_dhikrIndex];

  @override
  void dispose() {
    // Persist the session — backend for users, phone storage for guests.
    if (_sessionTotal > 0) {
      StatsRepository()
          .logTasbeeh(
              dhikr: _dhikr.name, count: _sessionTotal, rounds: _rounds)
          .catchError((_) {});
    }
    super.dispose();
  }

  void _increment() {
    HapticFeedback.lightImpact();
    _sessionTotal++;
    setState(() {
      _count++;
      if (_count >= _dhikr.target) {
        HapticFeedback.mediumImpact();
        _count = 0;
        _rounds++;
        _dhikrIndex = (_dhikrIndex + 1) % _adhkar.length;
      }
    });
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _count = 0;
      _rounds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tasbeeh),
        actions: [
          IconButton(
              onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              // Dhikr presets
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _adhkar.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final selected = i == _dhikrIndex;
                    return AnimatedPress(
                      onTap: () => setState(() {
                        _dhikrIndex = i;
                        _count = 0;
                      }),
                      child: AnimatedContainer(
                        duration: AppDurations.normal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? context.colors.primary
                              : context.colors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: selected
                                  ? context.colors.primary
                                  : context.colors.outline),
                        ),
                        child: Text(
                          '${_adhkar[i].name} • ${_adhkar[i].target}',
                          style: context.text.labelMedium?.copyWith(
                              color: selected
                                  ? Colors.white
                                  : context.colors.onSurfaceVariant),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              Text(
                _dhikr.arabic,
                style:
                    AppTypography.arabicDisplay(context).copyWith(fontSize: 36),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(_dhikr.name, style: context.text.bodyMedium),
              const Spacer(),
              // Tap target
              AnimatedPress(
                onTap: _increment,
                pressedScale: 0.94,
                child: ProgressRing(
                  progress: _count / _dhikr.target,
                  size: 260,
                  strokeWidth: 14,
                  center: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$_count',
                            style: context.text.displayLarge?.copyWith(
                                color: Colors.white, fontSize: 64)),
                        Text(context.l10n.ofN(_dhikr.target),
                            style: context.text.bodyMedium
                                ?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(context.l10n.tapCircle, style: context.text.bodySmall),
              const Spacer(),
              // Session stats
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      shadow: false,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text('$_rounds', style: context.text.headlineSmall),
                          Text(context.l10n.rounds,
                              style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppCard(
                      shadow: false,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text('${_rounds * 33 + _count}',
                              style: context.text.headlineSmall),
                          Text(context.l10n.totalToday,
                              style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
