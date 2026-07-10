import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/extensions.dart';

/// Animated audio waveform bars. Idle: a flat quiet line.
/// Active: bars dance with pseudo-random amplitudes.
class Waveform extends StatefulWidget {
  final bool active;
  final int barCount;

  const Waveform({super.key, required this.active, this.barCount = 36});

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: const Size(280, 64),
        painter: _WaveformPainter(
          t: _controller.value,
          active: widget.active,
          barCount: widget.barCount,
          color: widget.active
              ? context.colors.primary
              : context.colors.onSurfaceVariant.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double t;
  final bool active;
  final int barCount;
  final Color color;

  _WaveformPainter({
    required this.t,
    required this.active,
    required this.barCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final gap = size.width / barCount;
    for (var i = 0; i < barCount; i++) {
      final x = gap * i + gap / 2;
      // Layered sines give an organic, speech-like envelope.
      final phase = t * 2 * math.pi;
      final env = 0.5 +
          0.5 * math.sin(i * 0.55 + phase * 2) *
              math.sin(i * 0.21 - phase) *
              math.cos(i * 0.13 + phase * 1.4);
      final h = active ? (6 + env * (size.height - 10)) : 5.0;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.t != t || old.active != active || old.color != color;
}

/// Three softly bouncing dots shown while "analyzing".
class AnalyzingDots extends StatefulWidget {
  const AnalyzingDots({super.key});

  @override
  State<AnalyzingDots> createState() => _AnalyzingDotsState();
}

class _AnalyzingDotsState extends State<AnalyzingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (_controller.value + i * 0.2) % 1;
          final bounce = math.sin(t * math.pi);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 12,
            height: 12,
            transform: Matrix4.translationValues(0, -bounce * 10, 0),
            decoration: BoxDecoration(
              color: context.colors.primary
                  .withOpacity(0.4 + bounce * 0.6),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
