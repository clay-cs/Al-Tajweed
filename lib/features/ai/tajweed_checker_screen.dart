import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_models.dart';
import '../../shared/data/local_bookmarks.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_dialogs.dart';
import '../../theme/app_typography.dart';
import '../quran/data/quran_repository.dart';
import 'data/recorder_service.dart';
import 'data/tajweed_models.dart';
import 'data/tajweed_repository.dart';
import 'widgets/mic_button.dart';
import 'widgets/tajweed_result_view.dart';
import 'widgets/waveform.dart';

enum _CheckerState { idle, recording, analyzing, result }

/// AI Tajweed Coach. Records the user's recitation, sends it to the Python
/// Tajweed AI service (via the Node backend) and shows the real letter-level
/// analysis, mistakes and score. Verses come from the live Quran database.
class TajweedCheckerScreen extends StatefulWidget {
  const TajweedCheckerScreen({super.key});

  @override
  State<TajweedCheckerScreen> createState() => _TajweedCheckerScreenState();
}

class _TajweedCheckerScreenState extends State<TajweedCheckerScreen> {
  final _recorder = RecorderService();
  final _repo = TajweedRepository();

  _CheckerState _state = _CheckerState.idle;
  Timer? _timer;
  int _seconds = 0;

  List<Surah> _surahs = const [];
  List<Ayah> _ayahs = const [];
  Surah? _surah;
  Ayah? _ayah;
  bool _started = false;

  TajweedResult? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final surahs = await QuranRepository().fetchSurahs(lang);
      if (!mounted || surahs.isEmpty) return;
      final ayahs =
          await QuranRepository().fetchAyahs(surahs.first.number, lang);
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _surah = surahs.first;
        _ayahs = ayahs;
        _ayah = ayahs.isNotEmpty ? ayahs.first : null;
      });
    } catch (_) {
      // Offline / empty DB — the screen shows its empty state below.
    }
  }

  Future<void> _pickSurah(
      Surah surah, void Function(void Function()) refresh) async {
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final ayahs = await QuranRepository().fetchAyahs(surah.number, lang);
      if (!mounted) return;
      setState(() {
        _surah = surah;
        _ayahs = ayahs;
        _ayah = ayahs.isNotEmpty ? ayahs.first : null;
      });
      refresh(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final ok = await _recorder.start();
    if (!ok) {
      if (mounted) context.showSnack(context.l10n.micPermissionNeeded);
      return;
    }
    setState(() {
      _state = _CheckerState.recording;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  Future<void> _stopAndAnalyze() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    final ayah = _ayah;
    final surah = _surah;
    if (path == null || ayah == null || surah == null) {
      setState(() => _state = _CheckerState.idle);
      return;
    }
    if (_seconds < 1) {
      if (mounted) context.showSnack(context.l10n.tooShort);
      await _recorder.cleanup();
      setState(() => _state = _CheckerState.idle);
      return;
    }
    setState(() => _state = _CheckerState.analyzing);
    try {
      final result = await _repo.assess(
        audioPath: path,
        reference: ayah.arabic,
        surahNumber: surah.number,
        ayahNumber: ayah.number,
      );
      await _recorder.cleanup();
      if (!mounted) return;
      // Recitation counts toward today's goals on this device too.
      TodayActivity.addRecitation();
      setState(() {
        _result = result;
        _state = _CheckerState.result;
      });
    } catch (e) {
      await _recorder.cleanup();
      if (!mounted) return;
      final message = _errorMessage(e);
      setState(() => _state = _CheckerState.idle);
      context.showSnack(message);
    }
  }

  String _errorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('503') || msg.toLowerCase().contains('unavailable')) {
      return context.l10n.aiServiceDown;
    }
    return context.l10n.analysisFailed;
  }

  void _reset() => setState(() {
        _state = _CheckerState.idle;
        _result = null;
      });

  String get _timeLabel =>
      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final surah = _surah;
    final ayah = _ayah;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.aiCoachTitle)),
      body: SafeArea(
        bottom: false,
        child: surah == null || ayah == null
            ? Center(
                child: Text(context.l10n.dbEmptyTitle,
                    style: context.text.bodyMedium))
            : AnimatedSwitcher(
                duration: AppDurations.normal,
                switchInCurve: AppCurves.enter,
                child: switch (_state) {
                  _CheckerState.result when result != null =>
                    TajweedResultView(
                      key: const ValueKey('result'),
                      result: result,
                      surah: surah,
                      ayah: ayah,
                      onTryAgain: _reset,
                    ),
                  _ => _RecordView(
                      key: const ValueKey('record'),
                      state: _state,
                      surah: surah,
                      ayah: ayah,
                      timeLabel: _timeLabel,
                      onPickVerse: _pickVerse,
                      onMicTap: () => _state == _CheckerState.recording
                          ? _stopAndAnalyze()
                          : _startRecording(),
                    ),
                },
              ),
      ),
    );
  }

  Future<void> _pickVerse() async {
    await AppDialogs.sheet<void>(
      context,
      child: StatefulBuilder(
        builder: (context, refresh) => SizedBox(
          height: context.screenSize.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.chooseVerse, style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<int>(
                initialValue: _surah?.number,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
                items: [
                  for (final s in _surahs)
                    DropdownMenuItem(
                      value: s.number,
                      child: Text('${s.number}. ${s.name}',
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (n) {
                  final surah =
                      _surahs.where((s) => s.number == n).firstOrNull;
                  if (surah != null) _pickSurah(surah, refresh);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: _ayahs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final ayah = _ayahs[index];
                    return ListTile(
                      onTap: () {
                        setState(() => _ayah = ayah);
                        Navigator.pop(context);
                      },
                      leading: CircleAvatar(
                        backgroundColor:
                            context.colors.primary.withOpacity(0.1),
                        child: Text('${ayah.number}',
                            style: context.text.labelMedium?.copyWith(
                                color: context.colors.primary)),
                      ),
                      title: Text(
                        ayah.transliteration.isNotEmpty
                            ? ayah.transliteration
                            : ayah.arabic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(context.l10n.surahVerse(
                          _surah?.name ?? '', ayah.number)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Record view (idle / recording / analyzing)
// ─────────────────────────────────────────────────────────────────────────

class _RecordView extends StatelessWidget {
  final _CheckerState state;
  final Surah surah;
  final Ayah ayah;
  final String timeLabel;
  final VoidCallback onPickVerse;
  final VoidCallback onMicTap;

  const _RecordView({
    super.key,
    required this.state,
    required this.surah,
    required this.ayah,
    required this.timeLabel,
    required this.onPickVerse,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final recording = state == _CheckerState.recording;
    final analyzing = state == _CheckerState.analyzing;

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
          AppSpacing.screen, 130 + context.padding.bottom),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          onTap: recording || analyzing ? null : onPickVerse,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      context.l10n.surahVerse(surah.name, ayah.number),
                      style: context.text.labelMedium
                          ?.copyWith(color: context.colors.primary),
                    ),
                  ),
                  const Spacer(),
                  if (!recording && !analyzing) ...[
                    Icon(Icons.swap_horiz_rounded,
                        size: 20, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(context.l10n.change,
                        style: context.text.labelMedium?.copyWith(
                            color: context.colors.onSurfaceVariant)),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: Text(
                  ayah.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicDisplay(context)
                      .copyWith(fontSize: 30),
                ),
              ),
              if (ayah.transliteration.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    ayah.transliteration,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.huge),
        Center(
          child: AnimatedSwitcher(
            duration: AppDurations.normal,
            child: Text(
              analyzing
                  ? context.l10n.analyzing
                  : recording
                      ? timeLabel
                      : context.l10n.tapMicAndRecite,
              key: ValueKey('$state$timeLabel'),
              style: recording
                  ? context.text.headlineMedium
                  : context.text.bodyLarge
                      ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          height: 72,
          child: Center(
            child: analyzing
                ? const AnalyzingDots()
                : Waveform(active: recording),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: MicButton(
            recording: recording,
            enabled: !analyzing,
            onTap: onMicTap,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            analyzing
                ? context.l10n.preparingModels
                : recording
                    ? context.l10n.tapToStop
                    : context.l10n.holdDevice,
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
        ),
      ],
    );
  }
}
