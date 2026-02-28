// lib/features/circulars/presentation/widgets/unseen_badge_chip.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Unseen Badge Chip
///
/// ✅ Prompt rules:
/// - Category-wise unseen count
/// - If count is 0 → hide completely (do NOT show 0)
class UnseenBadgeChip extends StatelessWidget {
  const UnseenBadgeChip({
    super.key,
    required this.count,
    this.maxToShow = 99,
  });

  final int count;

  /// If count > maxToShow → show "99+"
  final int maxToShow;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.error;
    final textColor = scheme.onError;

    final label = count > maxToShow ? '$maxToShow+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: bg.withOpacity(0.35),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
