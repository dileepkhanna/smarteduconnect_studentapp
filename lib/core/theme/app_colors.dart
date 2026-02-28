import 'package:flutter/material.dart';

/// Parent App color tokens aligned with Teacher App theme system.
@immutable
class AppColors {
  const AppColors._();

  // ===== Brand colors (ASE) =====
  static const Color brandTeal = Color(0xFF074D56);
  static const Color brandOrange = Color(0xFFF89E2B);
  static const Color brandRed = Color(0xFFD8222B);
  static const Color brandGrey = Color(0xFF676E75);

  // Extra accent colors used by some screens.
  static const Color brandBlue = Color(0xFF2563EB);
  static const Color brandPurple = Color(0xFF7C3AED);
  static const Color brandGreen = Color(0xFF22C55E);

  /// Seed for Material 3 tonal palette.
  static const Color seed = brandTeal;

  /// Core app accents.
  static const Color primary = brandTeal;
  static const Color secondary = brandOrange;
  static const Color tertiary = brandGrey;

  // ===== Semantic colors =====
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = brandOrange;
  static const Color danger = brandRed;
  static const Color info = Color(0xFF0288D1);

  // ===== Surfaces (light) =====
  static const Color background = Color(0xFFF1F6FB);
  static const Color surface = Color(0xFFF8FBFF);
  static const Color card = Color(0xFFF4F8FD);

  /// Borders around cards/inputs/dividers.
  static const Color border = Color(0xFFD7E2EF);
  static const Color divider = Color(0xFFE2EAF4);

  // ===== Text (light) =====
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = brandGrey;
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF64748B);

  // ===== Dark surfaces =====
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF111C33);
  static const Color borderDark = Color(0xFF26324A);
  static const Color dividerDark = Color(0xFF2A2F3A);
  static const Color surfaceAltDark = Color(0xFF1F2937);

  // ===== Text (dark) =====
  static const Color textDark = Color(0xFFF1F5F9);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Compatibility tokens used by existing Parent screens.
  static const Color text = textPrimary;
  static const Color textPrimaryDark = textDark;
  static const Color textSecondaryDark = textMutedDark;
  static const Color textTertiaryDark = textMutedDark;
  static const Color brandPrimary = primary;
  static const Color surfaceSoft = card;
  static const Color borderSoft = divider;

  // Attendance aliases.
  static const Color attendancePresent = success;
  static const Color attendanceAbsent = danger;
  static const Color attendanceHalfDay = warning;

  // Chips.
  static const Color chipBg = Color(0xFFEAF1FA);

  // Gradients used in headers/drawer blocks.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandTeal, brandOrange],
  );

  static const LinearGradient brandGradientSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33074D56),
      Color(0x26F89E2B),
      Color(0x1F2563EB),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  // ===== Material ColorSchemes =====
  static ColorScheme lightScheme({Color seedColor = seed}) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: surface,
      error: danger,
    );
  }

  static ColorScheme darkScheme({Color seedColor = seed}) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: surfaceDark,
      error: danger,
    );
  }
}
