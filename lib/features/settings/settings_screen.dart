import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_dialogs.dart';
import '../auth/data/auth_repository.dart';

/// Settings: appearance (theme mode), reading, audio, notifications
/// and about — grouped in cards.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _prayerAlerts = true;
  bool _dailyVerse = true;
  bool _streakReminder = false;
  double _arabicSize = 0.5;
  String _reciter = 'Mishary Rashid Alafasy';
  String _translation = 'Saheeh International (English)';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
              AppSpacing.screen, AppSpacing.xxl + context.padding.bottom),
          children: [
            _GroupLabel(l10n.appearance),
            AppCard(
              shadow: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.mode,
                builder: (context, mode, _) => Column(
                  children: [
                    for (final (m, label, icon) in [
                      (
                        ThemeMode.system,
                        l10n.themeSystem,
                        Icons.brightness_auto_rounded
                      ),
                      (
                        ThemeMode.light,
                        l10n.themeLight,
                        Icons.light_mode_rounded
                      ),
                      (ThemeMode.dark, l10n.themeDark, Icons.dark_mode_rounded),
                    ])
                      RadioListTile<ThemeMode>(
                        value: m,
                        groupValue: mode,
                        onChanged: (v) => _setTheme(v!),
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Icon(icon,
                                size: 20,
                                color: context.colors.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.md),
                            Text(label, style: context.text.titleSmall),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _GroupLabel(l10n.language),
            AppCard(
              shadow: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ValueListenableBuilder<Locale?>(
                valueListenable: LocaleController.locale,
                builder: (context, locale, _) => Column(
                  children: [
                    for (final (loc, label) in [
                      (null, l10n.languageSystem),
                      (const Locale('en'), 'English'),
                      (const Locale('uz'), 'Oʻzbekcha'),
                    ])
                      RadioListTile<String>(
                        value: loc?.languageCode ?? 'system',
                        groupValue: locale?.languageCode ?? 'system',
                        onChanged: (_) => _setLanguage(loc),
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Icon(Icons.language_rounded,
                                size: 20,
                                color: context.colors.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.md),
                            Text(label, style: context.text.titleSmall),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _GroupLabel(l10n.reading),
            AppCard(
              shadow: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PickerRow(
                    icon: Icons.translate_rounded,
                    label: l10n.translation,
                    value: _translation,
                    onTap: () => _pick(
                      l10n.translation,
                      [
                        'Saheeh International (English)',
                        'Abdul Haleem (English)',
                        'Alauddin Mansour (Uzbek)',
                        'Elmalili Hamdi (Turkish)',
                      ],
                      _translation,
                      (v) => setState(() => _translation = v),
                    ),
                  ),
                  Divider(
                      height: AppSpacing.xxl,
                      color: context.colors.outline),
                  Text(l10n.arabicTextSize,
                      style: context.text.titleSmall),
                  Row(
                    children: [
                      const Text('أ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: _arabicSize,
                          onChanged: (v) =>
                              setState(() => _arabicSize = v),
                        ),
                      ),
                      const Text('أ', style: TextStyle(fontSize: 26)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _GroupLabel(l10n.audio),
            AppCard(
              shadow: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _PickerRow(
                icon: Icons.record_voice_over_rounded,
                label: l10n.reciter,
                value: _reciter,
                onTap: () => _pick(
                  l10n.reciter,
                  [
                    'Mishary Rashid Alafasy',
                    'Abdul Basit Abdus Samad',
                    'Saad Al-Ghamdi',
                    'Maher Al-Muaiqly',
                  ],
                  _reciter,
                  (v) => setState(() => _reciter = v),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _GroupLabel(l10n.notifications),
            AppCard(
              shadow: false,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.prayerAlerts),
                    subtitle: Text(l10n.prayerAlertsSub),
                    value: _prayerAlerts,
                    onChanged: (v) => setState(() => _prayerAlerts = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.dailyVerseSetting),
                    subtitle: Text(l10n.dailyVerseSub),
                    value: _dailyVerse,
                    onChanged: (v) => setState(() => _dailyVerse = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.streakReminder),
                    subtitle: Text(l10n.streakReminderSub),
                    value: _streakReminder,
                    onChanged: (v) => setState(() => _streakReminder = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _GroupLabel(l10n.about),
            AppCard(
              shadow: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _PickerRow(
                    icon: Icons.privacy_tip_outlined,
                    label: l10n.privacyPolicy,
                    value: '',
                    onTap: () {},
                  ),
                  Divider(
                      height: AppSpacing.xxl,
                      color: context.colors.outline),
                  _PickerRow(
                    icon: Icons.info_outline_rounded,
                    label: l10n.version,
                    value: '1.0.0 (1)',
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Applies + persists the theme locally, and mirrors it to the user's
  /// DB record when signed in.
  void _setTheme(ThemeMode mode) {
    ThemeController.mode.value = mode;
    final name = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    AppPrefs.setTheme(name);
    AuthRepository().updatePrefs({'theme': name});
  }

  /// Applies + persists the language locally, and mirrors it to the user's
  /// DB record when signed in.
  void _setLanguage(Locale? loc) {
    LocaleController.locale.value = loc;
    final code = loc?.languageCode ?? 'system';
    AppPrefs.setLanguage(code);
    AuthRepository().updatePrefs({'language': code});
  }

  Future<void> _pick(String title, List<String> options, String current,
      ValueChanged<String> onPicked) async {
    await AppDialogs.sheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (final option in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () {
                onPicked(option);
                Navigator.pop(context);
              },
              title: Text(option),
              trailing: option == current
                  ? Icon(Icons.check_circle_rounded,
                      color: context.colors.primary)
                  : null,
            ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.xs, bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(label.toUpperCase(),
          style: context.text.labelSmall
              ?.copyWith(letterSpacing: 1.2)),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.text.titleSmall)),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.primary),
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded,
                color: context.colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
