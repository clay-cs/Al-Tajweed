import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_config.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/guest_stats.dart';
import '../../shared/data/local_bookmarks.dart';
import '../../shared/data/content_models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_dialogs.dart';
import '../../shared/widgets/audio_player_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../auth/data/auth_repository.dart';
import 'data/quran_repository.dart';

/// Reading view for a single surah: gradient header with Bismillah,
/// verse cards (Arabic, transliteration, translation) and a real audio
/// player that recites the whole surah verse by verse.
class SurahDetailsScreen extends StatefulWidget {
  final Surah surah;
  const SurahDetailsScreen({super.key, required this.surah});

  @override
  State<SurahDetailsScreen> createState() => _SurahDetailsScreenState();
}

enum _PlayMode { none, full, single }

class _SurahDetailsScreenState extends State<SurahDetailsScreen> {
  // Reading options
  bool _showTransliteration = true;
  bool _showTranslation = true;
  double _arabicScale = 0.5; // 0..1 → font size below

  // Data
  List<Ayah>? _ayahs; // null = loading
  bool _error = false;

  // Bookmarks: "surah:ayah" keys, synced with backend or phone storage.
  Set<String> _bookmarks = {};

  // "I finished this surah" — synced with backend or phone storage.
  bool _completed = false;
  bool _savingCompleted = false;

  // Memorized ayah numbers — synced with backend or phone storage.
  Set<int> _memorized = {};

  // Playback. Two modes:
  //  • full   — one continuous full-surah recording (the Listen button)
  //  • single — one ayah, looped until stopped (the ▶ on a verse card)
  final _player = AudioPlayer();
  final _scroll = ScrollController();
  _PlayMode _mode = _PlayMode.none;
  int? _currentIndex; // single mode: index into _ayahs
  bool _playing = false;
  bool _showPlayer = false;
  bool _repeat = false;
  double _speed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) => _onTrackComplete());
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _loadBookmarks();
    _loadCompleted();
    _loadMemorized();
    // Remember this spot for the Quran tab and home screen.
    LastRead.save('${widget.surah.name} • ${widget.surah.number}',
        surahNumber: widget.surah.number);
  }

  Future<void> _loadMemorized() async {
    try {
      final set = AuthSession.isLoggedIn
          ? await QuranRepository().fetchMemorizedAyahs(widget.surah.number)
          : await GuestStats.memorizedAyahs(widget.surah.number);
      if (mounted) setState(() => _memorized = set);
    } catch (_) {}
  }

  Future<void> _toggleMemorized(Ayah ayah) async {
    final was = _memorized.contains(ayah.number);
    setState(() =>
        was ? _memorized.remove(ayah.number) : _memorized.add(ayah.number));
    try {
      if (AuthSession.isLoggedIn) {
        await QuranRepository()
            .setAyahMemorized(widget.surah.number, ayah.number, !was);
      } else {
        await GuestStats.toggleMemorizedAyah(
            widget.surah.number, ayah.number);
      }
    } catch (_) {
      if (mounted) {
        setState(() => was
            ? _memorized.add(ayah.number)
            : _memorized.remove(ayah.number)); // revert
      }
    }
  }

  Future<void> _loadCompleted() async {
    try {
      final set = AuthSession.isLoggedIn
          ? await QuranRepository().fetchCompletedSurahs()
          : await GuestStats.completedSurahs();
      if (mounted) {
        setState(() => _completed = set.contains(widget.surah.number));
      }
    } catch (_) {}
  }

  Future<void> _toggleCompleted() async {
    if (_savingCompleted) return;
    setState(() {
      _savingCompleted = true;
      _completed = !_completed;
    });
    try {
      if (AuthSession.isLoggedIn) {
        await QuranRepository()
            .setCompleted(widget.surah.number, _completed);
        AuthRepository().refreshProfile(); // profile stat updates from DB
      } else {
        await GuestStats.toggleCompleted(widget.surah.number);
      }
      if (mounted && _completed) {
        context.showSnack(context.l10n.surahCompleted);
      }
    } catch (_) {
      if (mounted) setState(() => _completed = !_completed); // revert
    } finally {
      if (mounted) setState(() => _savingCompleted = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ayahs == null && !_error) _load();
  }

  Future<void> _load() async {
    setState(() {
      _ayahs = null;
      _error = false;
    });
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final items =
          await QuranRepository().fetchAyahs(widget.surah.number, lang);
      if (!mounted) return;
      setState(() => _ayahs = items);
    } on DioException catch (e) {
      if (!mounted) return;
      // Surah not in the DB yet → an "empty" state, not a network error.
      if (e.response?.statusCode == 404) {
        setState(() => _ayahs = const []);
      } else {
        setState(() => _error = true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final keys = AuthSession.isLoggedIn
          ? await QuranRepository().fetchBookmarkKeys()
          : await LocalBookmarks.load();
      if (mounted) setState(() => _bookmarks = keys);
    } catch (_) {
      // Offline — bookmarks stay empty; toggling still works locally.
    }
  }

  // ── Playback ────────────────────────────────────────────────────────

  /// Full-surah recording (Mishary Alafasy, mp3quran.net).
  String get _fullSurahUrl =>
      'https://server8.mp3quran.net/afs/${widget.surah.number.toString().padLeft(3, '0')}.mp3';

  /// The Listen button: one continuous recording of the whole surah.
  Future<void> _playFullSurah() async {
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setPlaybackRate(_speed);
    await _player.play(UrlSource(_fullSurahUrl));
    if (!mounted) return;
    setState(() {
      _mode = _PlayMode.full;
      _currentIndex = null;
      _playing = true;
      _showPlayer = true;
      _repeat = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  /// The ▶ on a verse card: that single ayah, looped until stopped.
  Future<void> _playAyah(int index) async {
    final ayahs = _ayahs;
    if (ayahs == null || ayahs.isEmpty) return;
    final ayah = ayahs[index.clamp(0, ayahs.length - 1)];
    if (ayah.audioUrl == null || ayah.audioUrl!.isEmpty) {
      context.showSnack(context.l10n.noAudioForAyah);
      return;
    }
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop); // repeat this ayah
    await _player.setPlaybackRate(_speed);
    await _player.play(UrlSource(ApiConfig.fileUrl(ayah.audioUrl!)));
    if (!mounted) return;
    setState(() {
      _mode = _PlayMode.single;
      _currentIndex = index;
      _playing = true;
      _showPlayer = true;
      _repeat = true;
      _position = Duration.zero;
    });
    _scrollTo(index);
  }

  // Fires only when looping is off (ReleaseMode.stop).
  void _onTrackComplete() {
    if (!mounted) return;
    if (_mode == _PlayMode.full && _repeat) {
      _playFullSurah();
      return;
    }
    setState(() {
      _playing = false;
      _position = Duration.zero;
    });
  }

  Future<void> _togglePlayPause() async {
    if (_mode == _PlayMode.none) {
      await _playFullSurah();
      return;
    }
    if (_playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  void _next() {
    if (_mode == _PlayMode.full) {
      // Whole-surah recording: jump forward 10 seconds.
      final target = _position + const Duration(seconds: 10);
      _player.seek(target > _duration ? _duration : target);
    } else if (_mode == _PlayMode.single &&
        _ayahs != null &&
        (_currentIndex ?? 0) + 1 < _ayahs!.length) {
      _playAyah(_currentIndex! + 1);
    }
  }

  void _previous() {
    if (_mode == _PlayMode.full) {
      final target = _position - const Duration(seconds: 10);
      _player.seek(target.isNegative ? Duration.zero : target);
    } else if (_mode == _PlayMode.single && _currentIndex != null) {
      // Restart if >2s in, else the previous ayah.
      if (_position.inSeconds > 2 || _currentIndex == 0) {
        _player.seek(Duration.zero);
      } else {
        _playAyah(_currentIndex! - 1);
      }
    }
  }

  void _seek(double fraction) {
    if (_duration == Duration.zero) return;
    _player.seek(_duration * fraction);
  }

  void _toggleRepeat() {
    setState(() => _repeat = !_repeat);
    if (_mode == _PlayMode.single) {
      _player.setReleaseMode(_repeat ? ReleaseMode.loop : ReleaseMode.stop);
    }
  }

  void _cycleSpeed() {
    const speeds = [1.0, 1.25, 1.5, 2.0, 0.75];
    _speed = speeds[(speeds.indexOf(_speed) + 1) % speeds.length];
    _player.setPlaybackRate(_speed);
    setState(() {});
  }

  Future<void> _closePlayer() async {
    await _player.stop();
    setState(() {
      _mode = _PlayMode.none;
      _showPlayer = false;
      _playing = false;
      _currentIndex = null;
      _repeat = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  void _scrollTo(int index) {
    if (!_scroll.hasClients) return;
    // Verse cards vary in height; an estimate is enough to keep the
    // playing ayah in view.
    final target = (index * 230.0 - 120).clamp(
        0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
  }

  // ── Per-ayah actions ────────────────────────────────────────────────

  Future<void> _toggleBookmark(Ayah ayah) async {
    final key = LocalBookmarks.ayahKey(widget.surah.number, ayah.number);
    final wasBookmarked = _bookmarks.contains(key);
    setState(() =>
        wasBookmarked ? _bookmarks.remove(key) : _bookmarks.add(key));
    try {
      if (AuthSession.isLoggedIn) {
        if (wasBookmarked) {
          await QuranRepository().removeBookmark(widget.surah.number,
              ayahNumber: ayah.number);
        } else {
          await QuranRepository()
              .addBookmark(widget.surah.number, ayahNumber: ayah.number);
        }
      } else {
        await LocalBookmarks.toggle(key);
      }
    } catch (_) {
      // Revert on failure so the UI never lies.
      if (mounted) {
        setState(() => wasBookmarked
            ? _bookmarks.add(key)
            : _bookmarks.remove(key));
      }
    }
  }

  Future<void> _shareAyah(Ayah ayah) async {
    final text = '${ayah.arabic}\n\n'
        '${ayah.translation}\n\n'
        '— ${widget.surah.name} ${widget.surah.number}:${ayah.number}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) context.showSnack(context.l10n.copied);
  }

  void _practiceAyah() {
    _player.pause();
    setState(() => _playing = false);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AppRouter.tajweedChecker));
  }

  @override
  void dispose() {
    _player.dispose();
    _scroll.dispose();
    // Record the reading session: server progress (feeds pages read +
    // day streak) for users, phone storage for guests.
    final versesRead = _ayahs?.length ?? 0;
    if (versesRead > 0) {
      TodayActivity.addVerses(versesRead); // daily-goals counter
      if (AuthSession.isLoggedIn) {
        QuranRepository()
            .saveProgress(
              surahNumber: widget.surah.number,
              lastVerse: versesRead,
              totalVerses:
                  widget.surah.verses > 0 ? widget.surah.verses : versesRead,
            )
            .catchError((_) {});
      } else {
        GuestStats.logReading(versesDelta: versesRead);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final arabicSize = 20 + _arabicScale * 14; // 20..34
    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            backgroundColor: const Color(0xFF0B6E58),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: _openOptionsSheet,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.heroGradient),
                // OverflowBox keeps the header content anchored to the
                // bottom without throwing overflow errors while the app
                // bar collapses.
                child: ClipRect(
                  child: OverflowBox(
                    minHeight: 0,
                    maxHeight: double.infinity,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Text(surah.arabicName,
                          style: AppTypography.arabicTitle(context).copyWith(
                              color: Colors.white, fontSize: 30)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(surah.name,
                          style: context.text.headlineSmall
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${surah.meaning} • ${context.l10n.revelation(surah.revelation)} • ${context.l10n.versesCount(surah.verses)}',
                        style: context.text.bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (surah.number != 1 && surah.number != 9)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            style: AppTypography.arabicTitle(context)
                                .copyWith(color: Colors.white, fontSize: 22),
                          ),
                        )
                      else
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_ayahs == null && !_error)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error || _ayahs!.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _error
                          ? Icons.wifi_off_rounded
                          : Icons.menu_book_rounded,
                      size: 44,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _error
                          ? context.l10n.networkError
                          : context.l10n.noAyahsYet,
                      textAlign: TextAlign.center,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xl,
                AppSpacing.screen,
                (_showPlayer ? 300 : 120) + context.padding.bottom,
              ),
              sliver: SliverList.separated(
                // +2 = memorize-progress header and "I finished" button
                itemCount: _ayahs!.length + 2,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _MemorizeProgressCard(
                      memorized: _memorized.length,
                      total: _ayahs!.length,
                    );
                  }
                  if (index == _ayahs!.length + 1) {
                    return _CompleteSurahButton(
                      completed: _completed,
                      saving: _savingCompleted,
                      onTap: _toggleCompleted,
                    );
                  }
                  final ayahIndex = index - 1;
                  final ayah = _ayahs![ayahIndex];
                  final isCurrent = _mode == _PlayMode.single &&
                      _currentIndex == ayahIndex;
                  return _AyahCard(
                    ayah: ayah,
                    surahNumber: surah.number,
                    showTransliteration: _showTransliteration,
                    showTranslation: _showTranslation,
                    arabicSize: arabicSize,
                    playing: _playing && isCurrent,
                    highlighted: isCurrent,
                    bookmarked: _bookmarks.contains(
                        LocalBookmarks.ayahKey(surah.number, ayah.number)),
                    memorized: _memorized.contains(ayah.number),
                    onPlay: () => isCurrent
                        ? _togglePlayPause()
                        : _playAyah(ayahIndex),
                    onMic: _practiceAyah,
                    onBookmark: () => _toggleBookmark(ayah),
                    onMemorize: () => _toggleMemorized(ayah),
                    onShare: () => _shareAyah(ayah),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _showPlayer ||
              _ayahs == null ||
              _ayahs!.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _playFullSurah,
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(context.l10n.listen),
            ),
      bottomSheet: _showPlayer
          ? Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
                  context.padding.bottom + AppSpacing.lg),
              child: Stack(
                children: [
                  AudioPlayerBar(
                    subtitle: _mode == _PlayMode.full
                        ? '${surah.name} • ${context.l10n.fullSurah}'
                        : '${context.l10n.verseOfTotal((_currentIndex ?? 0) + 1, _ayahs?.length ?? 0)} • ${context.l10n.repeatingAyah}',
                    playing: _playing,
                    position: _position,
                    duration: _duration,
                    repeatOn: _repeat,
                    speed: _speed,
                    onPlayPause: _togglePlayPause,
                    onPrevious: _previous,
                    onNext: _next,
                    onSeek: _seek,
                    onRepeatToggle: _toggleRepeat,
                    onSpeedTap: _cycleSpeed,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: _closePlayer,
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _openOptionsSheet() {
    AppDialogs.sheet<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.readingOptions,
                style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.showTransliteration),
              value: _showTransliteration,
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _showTransliteration = v);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.showTranslation),
              value: _showTranslation,
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _showTranslation = v);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.arabicTextSize,
                style: context.text.labelLarge),
            Slider(
              value: _arabicScale,
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _arabicScale = v);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Memorization progress for this surah: percent ring, "X of N memorized"
/// and how many verses remain.
class _MemorizeProgressCard extends StatelessWidget {
  final int memorized;
  final int total;

  const _MemorizeProgressCard({
    required this.memorized,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = total == 0 ? 0.0 : (memorized / total).clamp(0.0, 1.0);
    final left = (total - memorized).clamp(0, total);
    return AppCard(
      shadow: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5.5,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                      progress >= 1 ? AppColors.success : colors.primary),
                ),
                Text('${(progress * 100).round()}%',
                    style: context.text.labelMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.memorizedOfTotal(memorized, total),
                    style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(context.l10n.versesLeft(left),
                    style: context.text.bodySmall),
              ],
            ),
          ),
          if (progress >= 1)
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.accent, size: 28),
        ],
      ),
    );
  }
}

/// "I finished this surah" — records the completion so the memorized-surah
/// count on the profile grows (DB for users, phone storage for guests).
class _CompleteSurahButton extends StatelessWidget {
  final bool completed;
  final bool saving;
  final VoidCallback onTap;

  const _CompleteSurahButton({
    required this.completed,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppCard(
        onTap: saving ? null : onTap,
        shadow: false,
        color: completed ? colors.primary.withOpacity(0.08) : null,
        borderColor: completed ? colors.primary : null,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (saving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Icon(
                completed
                    ? Icons.verified_rounded
                    : Icons.check_circle_outline_rounded,
                color: completed ? colors.primary : colors.onSurfaceVariant,
              ),
            const SizedBox(width: AppSpacing.md),
            Text(
              completed
                  ? context.l10n.completedBadge
                  : context.l10n.markCompleted,
              style: context.text.titleSmall?.copyWith(
                  color: completed ? colors.primary : colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;
  final bool showTransliteration;
  final bool showTranslation;
  final double arabicSize;
  final bool playing;
  final bool highlighted;
  final bool bookmarked;
  final bool memorized;
  final VoidCallback onPlay;
  final VoidCallback onMic;
  final VoidCallback onBookmark;
  final VoidCallback onMemorize;
  final VoidCallback onShare;

  const _AyahCard({
    required this.ayah,
    required this.surahNumber,
    required this.showTransliteration,
    required this.showTranslation,
    required this.arabicSize,
    required this.playing,
    required this.highlighted,
    required this.bookmarked,
    required this.memorized,
    required this.onPlay,
    required this.onMic,
    required this.onBookmark,
    required this.onMemorize,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      shadow: false,
      borderColor: highlighted ? colors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('$surahNumber:${ayah.number}',
                    style: context.text.labelMedium
                        ?.copyWith(color: colors.primary)),
              ),
              const Spacer(),
              _ActionIcon(
                icon: playing
                    ? Icons.pause_circle_rounded
                    : Icons.play_circle_outline_rounded,
                color: playing || highlighted
                    ? colors.primary
                    : ayah.audioUrl != null
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                onTap: onPlay,
              ),
              const SizedBox(width: AppSpacing.md),
              _ActionIcon(
                icon: Icons.mic_none_rounded,
                color: colors.onSurfaceVariant,
                onTap: onMic,
              ),
              const SizedBox(width: AppSpacing.md),
              // "I memorized this ayah" toggle.
              _ActionIcon(
                icon: memorized
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                color:
                    memorized ? AppColors.success : colors.onSurfaceVariant,
                onTap: onMemorize,
              ),
              const SizedBox(width: AppSpacing.md),
              _ActionIcon(
                icon: bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color:
                    bookmarked ? colors.tertiary : colors.onSurfaceVariant,
                onTap: onBookmark,
              ),
              const SizedBox(width: AppSpacing.md),
              _ActionIcon(
                icon: Icons.copy_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
                onTap: onShare,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: Text(
              ayah.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTypography.arabicDisplay(context)
                  .copyWith(fontSize: arabicSize),
            ),
          ),
          if (showTransliteration && ayah.transliteration.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              ayah.transliteration,
              style: context.text.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.primary.withOpacity(0.9)),
            ),
          ],
          if (showTranslation) ...[
            const SizedBox(height: AppSpacing.md),
            Text(ayah.translation,
                style: context.text.bodyMedium?.copyWith(height: 1.6)),
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
