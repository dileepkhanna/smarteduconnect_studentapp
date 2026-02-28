// lib/core/theme/app_shadows.dart
import 'package:flutter/material.dart';

/// Subtle, premium shadows (avoid heavy Material default shadows).
/// Use for cards/bottom sheets/dialogs.
class AppShadows {
  static List<BoxShadow> get soft => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 18,
          spreadRadius: 0,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 6,
          spreadRadius: 0,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get xs => const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get none => const [];
}
