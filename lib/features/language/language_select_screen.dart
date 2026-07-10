import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/animated_press.dart';
import '../../shared/widgets/app_button.dart';
import '../../theme/app_colors.dart';

/// First-launch language picker. Uzbek is preselected; the choice is saved
/// on the phone and applied immediately, then the app moves to onboarding.
class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  String _selected = 'uz'; // default — O'zbekcha

  static const _languages = [
    ('uz', 'Oʻzbekcha', 'UZ', '🇺🇿'),
    ('en', 'English', 'EN', '🇬🇧'),
  ];

  void _continue() {
    AppPrefs.setLanguage(_selected);
    LocaleController.locale.value = Locale(_selected);
    Navigator.of(context).pushReplacementNamed(Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.language_rounded,
                      size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Tilni tanlang',
                textAlign: TextAlign.center,
                style: context.text.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose your language',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              for (final (code, label, short, flag) in _languages) ...[
                _LanguageTile(
                  flag: flag,
                  label: label,
                  short: short,
                  selected: _selected == code,
                  onTap: () => setState(() => _selected = code),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const Spacer(flex: 2),
              AppButton(
                label: _selected == 'uz' ? 'Davom etish' : 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String label;
  final String short;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.short,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withOpacity(0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(label, style: context.text.titleMedium),
            ),
            Text(short,
                style: context.text.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(width: AppSpacing.md),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? colors.primary : colors.outline,
            ),
          ],
        ),
      ),
    );
  }
}
