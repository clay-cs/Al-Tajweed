import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/content_models.dart';
import '../../shared/data/content_repository.dart';
import '../../shared/data/guest_stats.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/data/auth_repository.dart';
import '../prayer/data/prayer_repository.dart';

/// Notification inbox built from real app state: the next prayer with a
/// live countdown, today's verse and hadith, and the user's streak.
/// Nothing here is canned content.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem>? _items; // null = loading
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _build();
    }
  }

  Future<void> _build() async {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final items = <NotificationItem>[];

    // Next prayer with a real countdown.
    await PrayerRepository.ensureLoaded();
    final prayer = PrayerRepository.data.value;
    if (prayer != null) {
      final (name, time, left) = prayer.nextPrayer();
      items.add(NotificationItem(
        title: l10n.prayerIn(
            l10n.prayerName(name), left.inHours, left.inMinutes % 60),
        body: '${l10n.prayerName(name)} — $time',
        time: l10n.nowLabel,
        icon: Icons.notifications_active_rounded,
        unread: true,
      ));
    }

    // Today's verse (backend, rotates daily).
    try {
      final verse = await ContentRepository().verseOfDay(lang);
      if (verse != null) {
        items.add(NotificationItem(
          title: l10n.dailyVerseReady,
          body:
              '“${verse.translation}” — ${verse.surahName} ${verse.surahNumber}:${verse.number}',
          time: l10n.nowLabel,
          icon: Icons.auto_stories_rounded,
          unread: true,
        ));
      }
    } catch (_) {}

    // Today's hadith (backend, rotates daily).
    try {
      final hadith = await ContentRepository().hadithOfDay(lang);
      if (hadith != null) {
        items.add(NotificationItem(
          title: l10n.dailyHadithReady,
          body: '“${hadith.translation}” — ${hadith.book}',
          time: l10n.nowLabel,
          icon: Icons.format_quote_rounded,
        ));
      }
    } catch (_) {}

    // Real streak — server for signed-in users, phone for guests.
    final streak = AuthSession.user.value?.streak ??
        GuestStats.data.value.streak;
    if (streak > 1) {
      items.add(NotificationItem(
        title: l10n.streakNotif(streak),
        body: l10n.dailyGoals,
        time: l10n.nowLabel,
        icon: Icons.local_fire_department_rounded,
      ));
    }

    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          TextButton(
            onPressed: items == null
                ? null
                : () => setState(() {
                      _items = [
                        for (final n in items)
                          NotificationItem(
                            title: n.title,
                            body: n.body,
                            time: n.time,
                            icon: n.icon,
                          ),
                      ];
                    }),
            child: Text(context.l10n.markAllRead),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: items == null
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.sm,
                        AppSpacing.screen,
                        AppSpacing.xxl + context.padding.bottom),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return Dismissible(
                        key: ValueKey('${n.title}$index'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            setState(() => items.removeAt(index)),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding:
                              const EdgeInsets.only(right: AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: context.colors.error,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white),
                        ),
                        child: _NotificationTile(item: n),
                      );
                    },
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      shadow: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: item.unread
          ? colors.primary.withOpacity(context.isDark ? 0.1 : 0.05)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(item.title,
                            style: context.text.titleSmall)),
                    Text(item.time, style: context.text.labelSmall),
                    if (item.unread) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(item.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined,
                size: 40, color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.allCaughtUp, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.newNotificationsHere,
              style: context.text.bodyMedium),
        ],
      ),
    );
  }
}
