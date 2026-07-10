import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import 'animated_press.dart';

enum AppButtonVariant { primary, secondary, ghost, gold }

/// The app's button. Filled emerald by default, with outline (secondary),
/// text-only (ghost) and gold-gradient (gold) variants, an optional icon
/// and a loading state.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (Color bg, Color fg, Gradient? gradient, BoxBorder? border) =
        switch (variant) {
      AppButtonVariant.primary => (colors.primary, colors.onPrimary, null, null),
      AppButtonVariant.secondary => (
          Colors.transparent,
          colors.onSurface,
          null,
          Border.all(color: colors.outline, width: 1.5),
        ),
      AppButtonVariant.ghost => (Colors.transparent, colors.primary, null, null),
      AppButtonVariant.gold => (
          Colors.transparent,
          const Color(0xFF3D2E05),
          const LinearGradient(
              colors: [Color(0xFFF2CE7B), Color(0xFFE3B23C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          null,
        ),
    };

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: context.text.labelLarge?.copyWith(fontSize: 16, color: fg),
          ),
        ],
      ],
    );

    return AnimatedPress(
      onTap: loading ? null : onPressed,
      pressedScale: 0.96,
      child: AnimatedOpacity(
        duration: AppDurations.fast,
        opacity: onPressed == null && !loading ? 0.5 : 1,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: variant == AppButtonVariant.primary
                ? [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}
