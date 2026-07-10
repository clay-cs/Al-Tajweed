import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/app_prefs.dart';
import '../../core/utils/extensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_dialogs.dart';
import '../../shared/widgets/glass_card.dart';
import '../../theme/app_colors.dart';
import 'data/prayer_repository.dart';

const _prayerIcons = <String, IconData>{
  'Fajr': Icons.wb_twilight_rounded,
  'Sunrise': Icons.wb_sunny_outlined,
  'Dhuhr': Icons.light_mode_rounded,
  'Asr': Icons.wb_cloudy_rounded,
  'Maghrib': Icons.nights_stay_outlined,
  'Isha': Icons.bedtime_rounded,
};

/// Real prayer times from the AlAdhan API: hero countdown, Hijri date,
/// Ramadan badge, full schedule, and settings (city/coords + method).
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final _muted = <String>{'Sunrise'};
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    PrayerRepository.ensureLoaded();
    // Keep the countdown fresh while the screen is open.
    _ticker = Timer.periodic(
        const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.prayerTimesTitle),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<PrayerData?>(
          valueListenable: PrayerRepository.data,
          builder: (context, data, _) {
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final (nextName, nextTime, left) = data.nextPrayer();
            return ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
                  AppSpacing.screen, AppSpacing.xxl + context.padding.bottom),
              children: [
                // Hero countdown
                AppCard(
                  gradient: AppColors.nightGradient,
                  radius: AppRadius.xl,
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: AppSpacing.xs),
                          Text(data.location,
                              style: context.text.bodySmall
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(context.l10n.nextPrayer,
                          style: context.text.labelMedium
                              ?.copyWith(color: Colors.white70)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(context.l10n.prayerName(nextName),
                          style: context.text.displayMedium
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(nextTime,
                          style: context.text.headlineSmall
                              ?.copyWith(color: AppColors.accentLight)),
                      const SizedBox(height: AppSpacing.xl),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md),
                        radius: AppRadius.pill,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_bottom_rounded,
                                size: 16, color: Colors.white),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              context.l10n.countdown(
                                  left.inHours, left.inMinutes % 60),
                              style: context.text.labelMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('${data.hijriLabel} AH',
                          style: context.text.labelSmall
                              ?.copyWith(color: Colors.white54)),
                      if (data.isRamadan) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.nightlight_round,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                context.l10n.ramadanDay(data.hijriDay),
                                style: context.text.labelSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(context.l10n.todaysSchedule,
                    style: context.text.titleLarge),
                const SizedBox(height: AppSpacing.md),
                for (final name in PrayerData.orderedNames) ...[
                  _PrayerRow(
                    name: name,
                    time: data.timings[name]!,
                    passed: data.passed(name),
                    isNext: name == nextName && !data.passed(name),
                    muted: _muted.contains(name),
                    onToggle: () => setState(() {
                      _muted.contains(name)
                          ? _muted.remove(name)
                          : _muted.add(name);
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    data.methodName,
                    style: context.text.labelSmall
                        ?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// City/coords + calculation method + Hanafi Asr — saved to prefs,
  /// then times reload from AlAdhan.
  Future<void> _openSettings() async {
    final l10n = context.l10n;
    final city = TextEditingController(text: AppPrefs.prayerCity);
    final country = TextEditingController(text: AppPrefs.prayerCountry);
    final lat =
        TextEditingController(text: AppPrefs.prayerLat?.toString() ?? '');
    final lng =
        TextEditingController(text: AppPrefs.prayerLng?.toString() ?? '');
    var method = AppPrefs.prayerMethod;
    var hanafi = AppPrefs.prayerHanafi;
    var useCoords = AppPrefs.prayerUseCoords;
    var saving = false;

    await AppDialogs.sheet<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> save() async {
            if (saving) return;
            double? latV;
            double? lngV;
            if (useCoords) {
              latV = double.tryParse(lat.text.trim());
              lngV = double.tryParse(lng.text.trim());
              if (latV == null || lngV == null) {
                context.showSnack(l10n.invalidCoords);
                return;
              }
            }
            setSheetState(() => saving = true);
            await AppPrefs.setPrayerSettings(
              city: city.text.trim().isEmpty ? 'Tashkent' : city.text.trim(),
              country: country.text.trim().isEmpty
                  ? 'Uzbekistan'
                  : country.text.trim(),
              method: method,
              hanafi: hanafi,
              useCoords: useCoords,
              lat: latV,
              lng: lngV,
            );
            await PrayerRepository.reload();
            if (context.mounted) Navigator.pop(context);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.prayerSettings, style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.lg),

              // Location mode
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l10n.byCity),
                      selected: !useCoords,
                      onSelected: (_) =>
                          setSheetState(() => useCoords = false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l10n.byCoords),
                      selected: useCoords,
                      onSelected: (_) =>
                          setSheetState(() => useCoords = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!useCoords) ...[
                TextField(
                  controller: city,
                  decoration: InputDecoration(
                    labelText: l10n.city,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: country,
                  decoration: InputDecoration(
                    labelText: l10n.country,
                    prefixIcon: const Icon(Icons.public_rounded),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: lat,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: l10n.latitude,
                    prefixIcon: const Icon(Icons.swap_vert_rounded),
                    hintText: '41.31',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: lng,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: l10n.longitude,
                    prefixIcon: const Icon(Icons.swap_horiz_rounded),
                    hintText: '69.24',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Calculation method
              DropdownButtonFormField<int>(
                initialValue: method,
                decoration: InputDecoration(
                  labelText: l10n.calcMethod,
                  prefixIcon: const Icon(Icons.calculate_outlined),
                ),
                items: [
                  for (final e in PrayerRepository.methods.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setSheetState(() => method = v ?? 3),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.hanafiAsr),
                value: hanafi,
                onChanged: (v) => setSheetState(() => hanafi = v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: l10n.save, loading: saving, onPressed: save),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
    city.dispose();
    country.dispose();
    lat.dispose();
    lng.dispose();
    if (mounted) setState(() {});
  }
}

class _PrayerRow extends StatelessWidget {
  final String name;
  final String time;
  final bool passed;
  final bool isNext;
  final bool muted;
  final VoidCallback onToggle;

  const _PrayerRow({
    required this.name,
    required this.time,
    required this.passed,
    required this.isNext,
    required this.muted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      shadow: false,
      color: isNext ? colors.primary : null,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(_prayerIcons[name] ?? Icons.mosque_rounded,
              size: 22,
              color: isNext
                  ? Colors.white
                  : passed
                      ? colors.onSurfaceVariant.withOpacity(0.5)
                      : colors.primary),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              context.l10n.prayerName(name),
              style: context.text.titleMedium?.copyWith(
                color: isNext
                    ? Colors.white
                    : passed
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
              ),
            ),
          ),
          Text(
            time,
            style: context.text.titleMedium?.copyWith(
              color: isNext ? Colors.white : colors.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              muted
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined,
              size: 21,
              color: isNext
                  ? Colors.white
                  : muted
                      ? colors.onSurfaceVariant.withOpacity(0.5)
                      : colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
