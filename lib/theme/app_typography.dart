import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale for Quran AI.
///
/// UI text: Plus Jakarta Sans — geometric, warm, premium.
/// Quran / Arabic text: Amiri — a classical Naskh face designed for Mushaf
/// typesetting.
abstract class AppTypography {
  static TextTheme textTheme(Color primary, Color secondary) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(
          fontSize: 40, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1, color: primary),
      displayMedium: base.displayMedium!.copyWith(
          fontSize: 32, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5, color: primary),
      headlineLarge: base.headlineLarge!.copyWith(
          fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5, color: primary),
      headlineMedium: base.headlineMedium!.copyWith(
          fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.25, color: primary),
      headlineSmall: base.headlineSmall!.copyWith(
          fontSize: 20, fontWeight: FontWeight.w700, height: 1.3, color: primary),
      titleLarge: base.titleLarge!.copyWith(
          fontSize: 18, fontWeight: FontWeight.w700, height: 1.3, color: primary),
      titleMedium: base.titleMedium!.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, color: primary),
      titleSmall: base.titleSmall!.copyWith(
          fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, color: primary),
      bodyLarge: base.bodyLarge!.copyWith(
          fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: primary),
      bodyMedium: base.bodyMedium!.copyWith(
          fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: secondary),
      bodySmall: base.bodySmall!.copyWith(
          fontSize: 12, fontWeight: FontWeight.w400, height: 1.45, color: secondary),
      labelLarge: base.labelLarge!.copyWith(
          fontSize: 14, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.1, color: primary),
      labelMedium: base.labelMedium!.copyWith(
          fontSize: 12, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.2, color: secondary),
      labelSmall: base.labelSmall!.copyWith(
          fontSize: 10, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.4, color: secondary),
    );
  }

  /// Large Quranic script, used in reading views and the daily verse card.
  static TextStyle arabicDisplay(BuildContext context) => GoogleFonts.amiri(
        fontSize: 28,
        height: 2.0,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface,
      );

  /// Medium Arabic — surah names, dua lines.
  static TextStyle arabicTitle(BuildContext context) => GoogleFonts.amiri(
        fontSize: 20,
        height: 1.7,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      );
}
