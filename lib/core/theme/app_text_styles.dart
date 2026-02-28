import 'package:flutter/material.dart';

/// Typography tokens aligned with Teacher App theme.
@immutable
class AppTextStyles {
  const AppTextStyles();

  static const String fontFamily = 'Poppins';

  static TextStyle get h1 => const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.15,
      );

  static TextStyle get h2 => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.20,
      );

  static TextStyle get h3 => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );

  static TextStyle get bodyMuted => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.20,
      );

  static TextStyle get button => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.20,
      );

  static TextStyle get buttonSecondary => button;

  static TextStyle get fieldHint => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
      );

  static TextStyle get fieldLabel => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle onDark(TextStyle style) =>
      style.copyWith(color: Colors.white.withValues(alpha: 0.92));

  static TextStyle mutedOnDark(TextStyle style) =>
      style.copyWith(color: Colors.white.withValues(alpha: 0.72));
}
