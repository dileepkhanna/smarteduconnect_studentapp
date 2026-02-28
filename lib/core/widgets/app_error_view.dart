// lib/core/widgets/app_error_view.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Retry',
    this.icon = Icons.error_outline_rounded,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final iconSize = compact ? 44.0 : 56.0;
    final pad = compact ? AppSpacing.lg : AppSpacing.xl;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize + 18,
                height: iconSize + 18,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.brandBlue.withOpacity(0.20),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: AppColors.brandBlue,
                ),
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(color: scheme.onSurface),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (onRetry != null) ...[
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                SizedBox(
                  width: compact ? 220 : 260,
                  child: AppButton(
                    label: retryLabel,
                    onPressed: onRetry,
                    variant: AppButtonVariant.outline,
                    fullWidth: true,
                    leading: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
