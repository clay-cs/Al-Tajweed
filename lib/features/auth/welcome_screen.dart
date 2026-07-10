import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../theme/app_colors.dart';

/// Welcome screen: brand moment + entry points into login / register /
/// guest browsing.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              context.isDark ? AppColors.nightGradient : null,
          color: context.isDark ? null : context.colors.surface,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_stories_rounded,
                        size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  context.l10n.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: context.text.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const Spacer(flex: 3),
                AppButton(
                  label: context.l10n.createAccount,
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.register),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: context.l10n.signIn,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.login),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(Routes.shell, (_) => false),
                  child: Text(context.l10n.continueAsGuest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
