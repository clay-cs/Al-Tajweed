import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/guest_stats.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_dialogs.dart';
import '../../shared/widgets/stat_card.dart';
import '../../theme/app_colors.dart';
import '../auth/data/auth_models.dart';
import '../auth/data/auth_repository.dart';
import '../auth/widgets/auth_widgets.dart';

/// Profile tab. Logged-in users see their DB profile with stats recomputed
/// server-side on every visit; guests see locally-tracked stats and a
/// sign-in prompt instead of account details.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Pull fresh, DB-computed stats every time the profile opens.
    AuthRepository().refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthSession.user,
      builder: (context, user, _) {
        if (user != null) return _ProfileBody(user: user);
        return ValueListenableBuilder<GuestStatsData>(
          valueListenable: GuestStats.data,
          builder: (context, guest, _) => _ProfileBody(guestStats: guest),
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final AuthUser? user;
  final GuestStatsData? guestStats;

  const _ProfileBody({this.user, this.guestStats});

  bool get isGuest => user == null;

  static const _supportEmail = 'hacknow.uz@gmail.com';

  /// Edit name + change password (signed-in users only).
  Future<void> _openEditSheet(BuildContext context, AuthUser user) async {
    final l10n = context.l10n;
    final name = TextEditingController(text: user.name);
    final currentPass = TextEditingController();
    final newPass = TextEditingController();
    var saving = false;

    await AppDialogs.sheet<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> save() async {
            if (saving) return;
            setSheetState(() => saving = true);
            try {
              final fields = <String, dynamic>{
                if (name.text.trim().isNotEmpty) 'name': name.text.trim(),
                if (newPass.text.isNotEmpty) ...{
                  'password': newPass.text,
                  'currentPassword': currentPass.text,
                },
              };
              await AuthRepository().updateProfile(fields);
              if (context.mounted) {
                Navigator.pop(context);
                context.showSnack(newPass.text.isNotEmpty
                    ? l10n.passwordChanged
                    : l10n.profileUpdated);
              }
            } catch (e) {
              if (context.mounted) {
                context.showSnack(
                    ApiClient.messageFrom(e, l10n.networkError));
              }
            } finally {
              setSheetState(() => saving = false);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.editProfile, style: context.text.titleLarge),
              const SizedBox(height: AppSpacing.xl),
              AuthField(
                label: l10n.fullName,
                hint: user.name,
                icon: Icons.person_outline_rounded,
                controller: name,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.changePassword,
                  style: context.text.labelLarge
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.md),
              AuthField(
                label: l10n.currentPassword,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: true,
                controller: currentPass,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthField(
                label: l10n.newPassword,
                hint: l10n.passwordHint8,
                icon: Icons.lock_reset_rounded,
                obscure: true,
                controller: newPass,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(label: l10n.save, loading: saving, onPressed: save),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
    name.dispose();
    currentPass.dispose();
    newPass.dispose();
  }

  /// Help & feedback: support address, copied with one tap.
  Future<void> _openHelpSheet(BuildContext context) {
    final l10n = context.l10n;
    return AppDialogs.sheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.helpFeedback, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.helpBody, style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            shadow: false,
            padding: const EdgeInsets.all(AppSpacing.lg),
            onTap: () async {
              await Clipboard.setData(
                  const ClipboardData(text: _supportEmail));
              if (context.mounted) {
                Navigator.pop(context);
                context.showSnack(l10n.copied);
              }
            },
            child: Row(
              children: [
                Icon(Icons.mail_outline_rounded,
                    color: context.colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(_supportEmail,
                      style: context.text.titleSmall),
                ),
                Icon(Icons.copy_rounded,
                    size: 18, color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l10n.version}: 1.0.0',
                  style: context.text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayName = user?.name ?? l10n.guest;
    final displayEmail = user?.email ?? l10n.guestHint;
    final firstLetter =
        displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();

    final streak = user?.streak ?? guestStats?.streak ?? 0;
    final completedSurahs =
        user?.completedSurahs ?? guestStats?.completedSurahs ?? 0;
    final pagesRead = user?.pagesRead ?? guestStats?.pagesRead ?? 0;
    final recitations = user?.recitationCount ?? guestStats?.recitationCount ?? 0;
    final avgTajweed = user?.avgTajweedScore ?? guestStats?.avgTajweedScore ?? 0;
    final xp = user?.xp ?? guestStats?.xp ?? 0;
    final level = user?.level ?? guestStats?.level ?? 1;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            // Pull the freshest DB-computed stats (or reload guest stats).
            await AuthRepository().refreshProfile();
            await GuestStats.load();
          },
          child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
              AppSpacing.screen, 120 + context.padding.bottom),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.profile, style: context.text.headlineLarge),
                IconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.settings),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Identity card
            AppCard(
              gradient: AppColors.heroGradient,
              radius: AppRadius.xl,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: isGuest
                        ? const Icon(Icons.person_outline_rounded,
                            size: 34, color: Colors.white)
                        : Text(
                            firstLetter,
                            style: context.text.displayMedium
                                ?.copyWith(color: Colors.white),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: context.text.titleLarge
                                ?.copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(displayEmail,
                            style: context.text.bodySmall
                                ?.copyWith(color: Colors.white70)),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  size: 14, color: AppColors.accentLight),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${l10n.levelBadgeN(level)} • $xp XP',
                                style: context.text.labelSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Stats — server-computed for users, phone-tracked for guests.
            Row(
              children: [
                Expanded(
                    child: StatCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '$streak',
                        label: l10n.statDayStreak,
                        color: AppColors.warning)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: StatCard(
                        icon: Icons.menu_book_rounded,
                        value: '$pagesRead',
                        label: l10n.statPagesRead,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                    child: StatCard(
                        icon: Icons.mic_rounded,
                        value: '$recitations',
                        label: l10n.statRecitations,
                        color: const Color(0xFF8B5CF6))),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: StatCard(
                        icon: Icons.grade_rounded,
                        value: '$avgTajweed',
                        label: l10n.statAvgTajweed,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Surahs the user marked as finished — counted from the DB
            // for accounts, from phone storage for guests.
            StatCard(
                icon: Icons.verified_rounded,
                value: '$completedSurahs / 114',
                label: l10n.statSurahsMemorized,
                color: AppColors.success),
            const SizedBox(height: AppSpacing.xxl),

            Text(l10n.achievements, style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _AchievementsRow(
              streak: streak,
              pagesRead: pagesRead,
              recitations: recitations,
              xp: xp,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Menu
            if (isGuest)
              _MenuTile(
                icon: Icons.login_rounded,
                label: l10n.signIn,
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.login),
              )
            else
              _MenuTile(
                icon: Icons.edit_outlined,
                label: l10n.editProfile,
                onTap: () => _openEditSheet(context, user!),
              ),
            _MenuTile(
              icon: Icons.bookmark_border_rounded,
              label: l10n.bookmarks,
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.bookmarks),
            ),
            _MenuTile(
              icon: Icons.notifications_none_rounded,
              label: l10n.notifications,
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.notifications),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: l10n.settings,
              onTap: () => Navigator.of(context).pushNamed(Routes.settings),
            ),
            _MenuTile(
              icon: Icons.help_outline_rounded,
              label: l10n.helpFeedback,
              onTap: () => _openHelpSheet(context),
            ),
            if (!isGuest)
              _MenuTile(
                icon: Icons.logout_rounded,
                label: l10n.signOut,
                destructive: true,
                onTap: () async {
                  await AuthRepository().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.welcome, (_) => false);
                  }
                },
              ),
          ],
          ),
        ),
      ),
    );
  }
}

class _Achievement {
  final IconData icon;
  final String label;
  final bool earned;
  const _Achievement(this.icon, this.label, this.earned);
}

class _AchievementsRow extends StatelessWidget {
  final int streak;
  final int pagesRead;
  final int recitations;
  final int xp;

  const _AchievementsRow({
    required this.streak,
    required this.pagesRead,
    required this.recitations,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Earned flags derive from the same stats shown above — no hardcoding.
    final achievements = <_Achievement>[
      _Achievement(
          Icons.local_fire_department_rounded, l10n.achStreak, streak >= 7),
      _Achievement(Icons.auto_stories_rounded, l10n.achKhatmah,
          pagesRead >= 604),
      _Achievement(Icons.mic_rounded, l10n.achRecitations, recitations >= 50),
      _Achievement(Icons.school_rounded, l10n.achAlphabet, xp >= 100),
      _Achievement(Icons.quiz_rounded, l10n.achQuiz, xp >= 500),
    ];
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final a = achievements[index];
          return Opacity(
            opacity: a.earned ? 1 : 0.45,
            child: SizedBox(
              width: 96,
              child: AppCard(
                shadow: false,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: a.earned ? AppColors.goldGradient : null,
                        color: a.earned
                            ? null
                            : context.colors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon,
                          size: 20,
                          color: a.earned
                              ? Colors.white
                              : context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? context.colors.error : context.colors.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: onTap,
        tileColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: context.colors.outline),
        ),
        leading: Icon(icon, color: color, size: 22),
        title: Text(label,
            style: context.text.titleSmall?.copyWith(color: color)),
        trailing: destructive
            ? null
            : Icon(Icons.chevron_right_rounded,
                color: context.colors.onSurfaceVariant),
      ),
    );
  }
}
