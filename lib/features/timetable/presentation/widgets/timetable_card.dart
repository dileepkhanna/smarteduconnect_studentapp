// lib/features/timetable/presentation/widgets/timetable_card.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';

enum TimetableSlotStatus { completed, ongoing, next, upcoming }

class TimetableSlotCard extends StatelessWidget {
  const TimetableSlotCard({
    super.key,
    required this.slot,
    required this.status,
    required this.progress01,
    required this.isTeacherView,
  });

  final Map<String, dynamic> slot;
  final TimetableSlotStatus status;
  final double progress01; // only used for ongoing; 0..1
  final bool isTeacherView;

  String _s(dynamic v) => (v ?? '').toString().trim();
  int _i(dynamic v) => int.tryParse((v ?? '').toString()) ?? 0;

  String _classLabel() {
    final c = _i(slot['classNumber']);
    final sec = _s(slot['section']);
    if (c <= 0) return '';
    if (sec.isEmpty) return 'Class $c';
    return 'Class $c$sec';
  }

  Color _statusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case TimetableSlotStatus.ongoing:
        return AppColors.brandTeal;
      case TimetableSlotStatus.next:
        return scheme.secondary;
      case TimetableSlotStatus.completed:
        return AppColors.success;
      case TimetableSlotStatus.upcoming:
        return scheme.onSurfaceVariant;
    }
  }

  String _statusLabel() {
    switch (status) {
      case TimetableSlotStatus.ongoing:
        return 'ONGOING';
      case TimetableSlotStatus.next:
        return 'NEXT';
      case TimetableSlotStatus.completed:
        return 'COMPLETED';
      case TimetableSlotStatus.upcoming:
        return 'UPCOMING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final timing = _s(slot['timing']);
    final subject = _s(slot['subject']);
    final classLabel = _classLabel();

    final statusColor = _statusColor(context);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: time + status
          Row(
            children: [
              Expanded(
                child: Text(
                  timing.isEmpty ? '—' : timing,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.rXl),
                  color: statusColor.withValues(alpha: 0.12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  _statusLabel(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.6,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Subject + (optional class label for teacher)
          Text(
            subject.isEmpty ? 'Subject' : subject,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (isTeacherView && classLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.school_rounded, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  classLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],

          if (status == TimetableSlotStatus.ongoing) ...[
            const SizedBox(height: 14),

            // Uber/Ola style moving progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.rXl),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress01.clamp(0.0, 1.0),
                backgroundColor: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Class in progress… ${(progress01 * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],

          if (status == TimetableSlotStatus.next) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.rLg),
                color: scheme.secondary.withValues(alpha: 0.10),
                border: Border.all(color: scheme.secondary.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: scheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next class is ready. Be prepared!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
