// lib/core/theme/app_spacing.dart

/// Spacing scale used across the app for consistent paddings/margins.
///
/// Use:
/// - AppSpacing.xs / sm / md / lg / xl etc.
/// - Border radius helpers below.
class AppSpacing {
  // Base spacing scale (4pt grid)
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  // Screen paddings
  static const double screenH = 16;
  static const double screenV = 16;

  // Card paddings
  static const double cardPadding = 16;

  // Button height
  static const double buttonHeight = 52;

  // Input height
  static const double inputHeight = 54;

  // Radius scale
  static const double rSm = 12;
  static const double rMd = 16;
  static const double rLg = 20;
  static const double rXl = 28;

  // Frequently used gaps
  static const double gap8 = 8;
  static const double gap12 = 12;
  static const double gap16 = 16;
  static const double gap20 = 20;
  static const double gap24 = 24;
  static const double gap32 = 32;
}
