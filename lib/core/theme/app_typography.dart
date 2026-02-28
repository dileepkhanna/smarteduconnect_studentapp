// // lib/core/theme/app_typography.dart
// import 'package:flutter/material.dart';

// import 'app_colors.dart';

// /// Typography system built around Poppins (already added in pubspec.yaml).
// /// Style goals:
// /// - Clean, modern, readable (school app)
// /// - Consistent scale for headings/body/labels
// /// - Slightly higher letter spacing for labels/buttons for clarity
// class AppTypography {
//   static const String fontFamily = 'Poppins';

//   // --- Display / Headings ---
//   static TextStyle get displayLarge => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 34,
//         height: 1.15,
//         fontWeight: FontWeight.w700,
//         letterSpacing: -0.5,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get displayMedium => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 28,
//         height: 1.18,
//         fontWeight: FontWeight.w700,
//         letterSpacing: -0.3,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get displaySmall => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 24,
//         height: 1.2,
//         fontWeight: FontWeight.w700,
//         letterSpacing: -0.2,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get headlineLarge => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 22,
//         height: 1.25,
//         fontWeight: FontWeight.w600,
//         letterSpacing: -0.15,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get headlineMedium => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 20,
//         height: 1.25,
//         fontWeight: FontWeight.w600,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get headlineSmall => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 18,
//         height: 1.3,
//         fontWeight: FontWeight.w600,
//         color: AppColors.textPrimary,
//       );

//   // --- Body ---
//   static TextStyle get bodyLarge => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 16,
//         height: 1.45,
//         fontWeight: FontWeight.w400,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get bodyMedium => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 14,
//         height: 1.45,
//         fontWeight: FontWeight.w400,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get bodySmall => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 12.5,
//         height: 1.45,
//         fontWeight: FontWeight.w400,
//         color: AppColors.textSecondary,
//       );

//   // --- Labels / Buttons ---
//   static TextStyle get labelLarge => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 14,
//         height: 1.2,
//         fontWeight: FontWeight.w600,
//         letterSpacing: 0.25,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get labelMedium => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 12.5,
//         height: 1.2,
//         fontWeight: FontWeight.w600,
//         letterSpacing: 0.35,
//         color: AppColors.textPrimary,
//       );

//   static TextStyle get labelSmall => const TextStyle(
//         fontFamily: fontFamily,
//         fontSize: 11.5,
//         height: 1.2,
//         fontWeight: FontWeight.w600,
//         letterSpacing: 0.4,
//         color: AppColors.textSecondary,
//       );

//   // --- Helper to switch to dark scheme colors easily ---
//   static TextTheme textThemeLight() {
//     return TextTheme(
//       displayLarge: displayLarge,
//       displayMedium: displayMedium,
//       displaySmall: displaySmall,
//       headlineLarge: headlineLarge,
//       headlineMedium: headlineMedium,
//       headlineSmall: headlineSmall,
//       bodyLarge: bodyLarge,
//       bodyMedium: bodyMedium,
//       bodySmall: bodySmall,
//       labelLarge: labelLarge,
//       labelMedium: labelMedium,
//       labelSmall: labelSmall,
//     );
//   }

//   static TextTheme textThemeDark() {
//     // Copy styles but with light text colors
//     TextStyle dark(TextStyle s, {Color? color}) => s.copyWith(
//           color: color ?? AppColors.textPrimaryDark,
//         );

//     return TextTheme(
//       displayLarge: dark(displayLarge),
//       displayMedium: dark(displayMedium),
//       displaySmall: dark(displaySmall),
//       headlineLarge: dark(headlineLarge),
//       headlineMedium: dark(headlineMedium),
//       headlineSmall: dark(headlineSmall),
//       bodyLarge: dark(bodyLarge),
//       bodyMedium: dark(bodyMedium),
//       bodySmall: dark(bodySmall, color: AppColors.textSecondaryDark),
//       labelLarge: dark(labelLarge),
//       labelMedium: dark(labelMedium),
//       labelSmall: dark(labelSmall, color: AppColors.textSecondaryDark),
//     );
//   }
// }








// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography system built around Poppins (already added in pubspec.yaml).
/// Style goals:
/// - Clean, modern, readable (school app)
/// - Consistent scale for headings/body/labels
/// - Slightly higher letter spacing for labels/buttons for clarity
class AppTypography {
  static const String fontFamily = 'Poppins';

  // ---------------------------------------------------------------------------
  // Compatibility aliases (required by some widgets/screens)
  // ---------------------------------------------------------------------------
  /// Used by some widgets expecting a short "H3" heading.
  static TextStyle get h3 => headlineMedium;

  /// Used by some widgets expecting a generic "body" style.
  static TextStyle get body => bodyMedium;

  // --- Display / Headings ---
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // --- Body ---
  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12.5,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // --- Labels / Buttons ---
  static TextStyle get labelLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  // --- Helper to switch to dark scheme colors easily ---
  static TextTheme textThemeLight() {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }

  static TextTheme textThemeDark() {
    // Copy styles but with light text colors
    TextStyle dark(TextStyle s, {Color? color}) => s.copyWith(
          color: color ?? AppColors.textPrimaryDark,
        );

    return TextTheme(
      displayLarge: dark(displayLarge),
      displayMedium: dark(displayMedium),
      displaySmall: dark(displaySmall),
      headlineLarge: dark(headlineLarge),
      headlineMedium: dark(headlineMedium),
      headlineSmall: dark(headlineSmall),
      bodyLarge: dark(bodyLarge),
      bodyMedium: dark(bodyMedium),
      bodySmall: dark(bodySmall, color: AppColors.textSecondaryDark),
      labelLarge: dark(labelLarge),
      labelMedium: dark(labelMedium),
      labelSmall: dark(labelSmall, color: AppColors.textSecondaryDark),
    );
  }
}
