import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/extensions.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String body;
  final List<Color> gradient;

  const _OnboardPage(this.icon, this.title, this.body, this.gradient);
}

List<_OnboardPage> _buildPages(AppLocalizations l10n) => [
      _OnboardPage(
        Icons.menu_book_rounded,
        l10n.onb1Title,
        l10n.onb1Body,
        const [Color(0xFF0E9D7B), Color(0xFF0B6E58)],
      ),
      _OnboardPage(
        Icons.graphic_eq_rounded,
        l10n.onb2Title,
        l10n.onb2Body,
        const [Color(0xFF1E3A5F), Color(0xFF14233C)],
      ),
      _OnboardPage(
        Icons.local_fire_department_rounded,
        l10n.onb3Title,
        l10n.onb3Body,
        const [Color(0xFFB07E1B), Color(0xFF8A5F0C)],
      ),
    ];

/// Premium 3-page onboarding with animated gradient background,
/// parallax icon and springy page indicator.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int pageCount) {
    if (_page == pageCount - 1) {
      Navigator.of(context).pushReplacementNamed(Routes.welcome);
    } else {
      _controller.nextPage(
          duration: AppDurations.page, curve: AppCurves.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(context.l10n);
    final page = pages[_page];
    return Scaffold(
      body: AnimatedContainer(
        duration: AppDurations.slow,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(Routes.welcome),
                    child: Text(
                      context.l10n.skip,
                      style: context.text.labelLarge
                          ?.copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) =>
                      _OnboardPageView(page: pages[index]),
                ),
              ),
              // Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: AppDurations.normal,
                    curve: AppCurves.enter,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: _WhiteButton(
                  label: _page == pages.length - 1
                      ? context.l10n.getStarted
                      : context.l10n.continueLabel,
                  onTap: () => _next(pages.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1),
            duration: AppDurations.slow,
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(page.icon, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: context.text.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.85), height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// White-filled CTA used on colored gradient backgrounds.
class _WhiteButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WhiteButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF101828),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
