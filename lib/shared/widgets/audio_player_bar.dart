import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import 'animated_press.dart';
import 'app_card.dart';

/// Recitation audio player — reciter, scrubber, transport controls.
/// Fully controlled: the owning screen passes state and callbacks.
class AudioPlayerBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool playing;
  final Duration position;
  final Duration duration;
  final bool repeatOn;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<double> onSeek; // 0..1 within the current track
  final VoidCallback onRepeatToggle;
  final VoidCallback onSpeedTap;

  const AudioPlayerBar({
    super.key,
    this.title = 'Mishary Rashid Alafasy',
    required this.subtitle,
    required this.playing,
    required this.position,
    required this.duration,
    required this.repeatOn,
    required this.speed,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSeek,
    required this.onRepeatToggle,
    required this.onSpeedTap,
  });

  static String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0E9D7B), Color(0xFF0B6E58)]),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child:
                    const Icon(Icons.headphones_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: context.text.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(value: progress, onChanged: onSeek),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(position), style: context.text.labelSmall),
                Text(_fmt(duration), style: context.text.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: onRepeatToggle,
                icon: Icon(Icons.repeat_rounded,
                    color: repeatOn ? colors.primary : colors.onSurfaceVariant,
                    size: 22),
              ),
              IconButton(
                onPressed: onPrevious,
                icon: Icon(Icons.skip_previous_rounded,
                    color: colors.onSurface, size: 32),
              ),
              AnimatedPress(
                onTap: onPlayPause,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: Icon(
                      playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      key: ValueKey(playing),
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: Icon(Icons.skip_next_rounded,
                    color: colors.onSurface, size: 32),
              ),
              AnimatedPress(
                onTap: onSpeedTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: colors.outline),
                  ),
                  child: Text(
                    '${speed % 1 == 0 ? speed.toInt() : speed}x',
                    style: context.text.labelMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
