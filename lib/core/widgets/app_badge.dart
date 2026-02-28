import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Small badge for counts / unseen.
/// ✅ Fixes your error: `label:` now exists (and count works too).
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    this.count,
    this.label,
    this.showZero = true,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.minSize = 18,
  });

  /// Used by places like Dashboard: `AppBadge(count: 0)`
  final int? count;

  /// Used by places like CircularTypes: `AppBadge(label: count.toString())`
  final String? label;

  /// If false and count==0, hides badge
  final bool showZero;

  final Color? backgroundColor;
  final Color? foregroundColor;

  final EdgeInsets padding;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    final String? text = label ?? (count != null ? count.toString() : null);

    if (text == null) return const SizedBox.shrink();

    // hide zero if requested
    if (!showZero && (count ?? int.tryParse(text) ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    final bg = backgroundColor ?? AppColors.brandPrimary;
    final fg = foregroundColor ?? Colors.white;

    return Container(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
