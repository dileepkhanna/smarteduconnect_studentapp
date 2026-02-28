// lib/core/widgets/app_card.dart
import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fillGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.surfaceContainerHigh.withValues(alpha: 0.96),
        scheme.surfaceContainer.withValues(alpha: 0.92),
      ],
    );

    final card = Container(
      decoration: BoxDecoration(
        gradient: fillGradient,
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        border: Border.all(
          color: border?.color ?? scheme.outlineVariant,
          width: border?.width ?? 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        child: card,
      ),
    );
  }
}
