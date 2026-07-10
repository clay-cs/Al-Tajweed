import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/animated_press.dart';

/// Labeled text field used across the auth flow.
class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                Icon(icon, size: 21, color: context.colors.onSurfaceVariant),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// "or continue with" divider + social buttons row.
class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: context.colors.outline)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(context.l10n.orContinueWith,
                  style: context.text.bodySmall),
            ),
            Expanded(child: Divider(color: context.colors.outline)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: const [
            Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata_rounded)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: _SocialButton(label: 'Apple', icon: Icons.apple_rounded)),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SocialButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: () =>
          context.showSnack(context.l10n.wiredLater('$label sign-in')),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colors.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: context.colors.onSurface),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: context.text.labelLarge),
          ],
        ),
      ),
    );
  }
}
