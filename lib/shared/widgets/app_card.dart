import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import 'animated_press.dart';

/// The app's standard elevated surface: soft shadow, hairline border,
/// generous radius. Optionally tappable with a press animation.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  final bool shadow;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.gradient,
    this.radius = AppRadius.lg,
    this.shadow = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? context.colors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: gradient == null
            ? Border.all(
                color: borderColor ?? context.colors.outline,
                width: borderColor != null ? 1.4 : 1)
            : null,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: context.isDark
                      ? Colors.black.withOpacity(0.25)
                      : const Color(0xFF101828).withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return AnimatedPress(onTap: onTap, child: card);
  }
}
