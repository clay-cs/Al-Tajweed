import 'package:flutter/material.dart';

/// Quran AI design-system palette.
///
/// Emerald primary (spiritual, calm), gold accent (heritage, reward),
/// deep-navy dark mode. Every color exists in a light and dark variant.
abstract class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────
  static const primary = Color(0xFF0E9D7B); // Emerald
  static const primaryDark = Color(0xFF0B7C61);
  static const primaryLight = Color(0xFF3DBD9C);
  static const primaryContainer = Color(0xFFD3F3EA);
  static const primaryContainerDark = Color(0xFF12433A);

  static const secondary = Color(0xFF1E3A5F); // Deep navy
  static const secondaryLight = Color(0xFF3E5F8A);
  static const secondaryContainer = Color(0xFFDCE7F5);
  static const secondaryContainerDark = Color(0xFF1A2C44);

  static const accent = Color(0xFFE3B23C); // Soft gold
  static const accentLight = Color(0xFFF2CE7B);
  static const accentContainer = Color(0xFFFBF0D7);
  static const accentContainerDark = Color(0xFF4A3B15);

  // ── Semantic ─────────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const successContainer = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningContainer = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorContainer = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoContainer = Color(0xFFDBEAFE);

  // ── Light theme neutrals ─────────────────────────────────────────────
  static const backgroundLight = Color(0xFFF7F8FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF0F2F5);
  static const outlineLight = Color(0xFFE4E7EC);
  static const textPrimaryLight = Color(0xFF101828);
  static const textSecondaryLight = Color(0xFF475467);
  static const textTertiaryLight = Color(0xFF98A2B3);

  // ── Dark theme neutrals ──────────────────────────────────────────────
  static const backgroundDark = Color(0xFF0B1220);
  static const surfaceDark = Color(0xFF131C2E);
  static const surfaceVariantDark = Color(0xFF1B2739);
  static const outlineDark = Color(0xFF283548);
  static const textPrimaryDark = Color(0xFFF2F4F7);
  static const textSecondaryDark = Color(0xFFAEB9C9);
  static const textTertiaryDark = Color(0xFF6C7A90);

  // ── Gradients ────────────────────────────────────────────────────────
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E9D7B), Color(0xFF0B6E58)],
  );

  static const nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14233C), Color(0xFF0B1220)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3B23C), Color(0xFFC98F1B)],
  );
}
