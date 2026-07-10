import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/extensions.dart';
import '../ai/tajweed_checker_screen.dart';
import '../home/home_screen.dart';
import '../learning/learning_center_screen.dart';
import '../profile/profile_screen.dart';
import '../quran/quran_screen.dart';

/// Root shell holding the five main tabs behind a custom, pill-highlighted
/// bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    QuranScreen(),
    LearningCenterScreen(),
    TajweedCheckerScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: AppDurations.normal,
        switchInCurve: AppCurves.enter,
        switchOutCurve: AppCurves.exit,
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _screens[_index],
        ),
      ),
      bottomNavigationBar: _AppNavBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _AppNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _AppNavBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final items = <_NavItem>[
      _NavItem(Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded, l10n.navQuran),
      _NavItem(Icons.school_outlined, Icons.school_rounded, l10n.navLearn),
      _NavItem(Icons.graphic_eq_outlined, Icons.graphic_eq_rounded, l10n.navAi),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, l10n.navProfile),
    ];
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        context.padding.bottom + AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: AppDurations.normal,
                curve: AppCurves.enter,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withOpacity(context.isDark ? 0.18 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      size: 24,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: context.text.labelSmall?.copyWith(
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
