import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../theme/app_colors.dart';

/// Qibla compass — a designed compass dial with a Kaaba needle.
/// Sensor integration comes later; the dial gently sways to feel alive.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  // Kaaba, Makkah.
  static const _kaabaLat = 21.4225;
  static const _kaabaLng = 39.8262;
  // Default point when the user hasn't set coordinates (Tashkent).
  static const _defaultLat = 41.3111;
  static const _defaultLng = 69.2797;

  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  double get _lat =>
      (AppPrefs.prayerUseCoords ? AppPrefs.prayerLat : null) ?? _defaultLat;
  double get _lng =>
      (AppPrefs.prayerUseCoords ? AppPrefs.prayerLng : null) ?? _defaultLng;

  /// Great-circle initial bearing to the Kaaba, degrees from north.
  double get _bearingDeg {
    final lat1 = _lat * math.pi / 180;
    final lat2 = _kaabaLat * math.pi / 180;
    final dLng = (_kaabaLng - _lng) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Haversine distance to the Kaaba in km.
  double get _distanceKm {
    const r = 6371.0;
    final dLat = (_kaabaLat - _lat) * math.pi / 180;
    final dLng = (_kaabaLng - _lng) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_lat * math.pi / 180) *
            math.cos(_kaabaLat * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.qibla)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              AppCard(
                shadow: false,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 20, color: context.colors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${AppPrefs.prayerCity}, ${AppPrefs.prayerCountry}',
                              style: context.text.titleSmall),
                          Text(
                              context.l10n
                                  .qiblaFromNorth(_bearingDeg.round()),
                              style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    Text(
                        context.l10n.kmToKaaba(
                            _distanceKm.round().toString()),
                        style: context.text.labelMedium
                            ?.copyWith(color: context.colors.primary)),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _sway,
                builder: (context, _) {
                  // Real bearing to the Kaaba, with a gentle sway until
                  // compass-sensor integration lands.
                  final angle = -_bearingDeg * math.pi / 180 +
                      math.sin(_sway.value * math.pi) * 0.05;
                  return Transform.rotate(
                    angle: angle,
                    child: _CompassDial(size: context.screenSize.width - 96),
                  );
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: Color(0xFF166534)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(context.l10n.alignedWithQibla,
                        style: context.text.labelMedium
                            ?.copyWith(color: const Color(0xFF166534))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.holdPhoneFlat,
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  final double size;
  const _CompassDial({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring with tick marks
          CustomPaint(
            size: Size.square(size),
            painter: _DialPainter(
              tickColor: colors.onSurfaceVariant.withOpacity(0.4),
              cardinalColor: colors.onSurface,
              ringColor: colors.outline,
            ),
          ),
          // Needle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.mosque_rounded,
                    color: Colors.white, size: 32),
              ),
              Container(
                width: 4,
                height: size * 0.22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accent,
                      AppColors.accent.withOpacity(0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: size * 0.18),
            ],
          ),
          // Center cap
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 3),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final Color tickColor;
  final Color cardinalColor;
  final Color ringColor;

  _DialPainter({
    required this.tickColor,
    required this.cardinalColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (var i = 0; i < 72; i++) {
      final isCardinal = i % 18 == 0;
      final angle = i * math.pi / 36;
      final outer = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - (isCardinal ? 26 : 16)) * math.cos(angle),
        center.dy + (radius - (isCardinal ? 26 : 16)) * math.sin(angle),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = isCardinal ? cardinalColor : tickColor
          ..strokeWidth = isCardinal ? 3 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cardinal letters
    const labels = ['E', 'S', 'W', 'N'];
    final textStyle = TextStyle(
      color: cardinalColor,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final pos = Offset(
        center.dx + (radius - 44) * math.cos(angle),
        center.dy + (radius - 44) * math.sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) => false;
}
