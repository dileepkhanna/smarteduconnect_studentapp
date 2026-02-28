// lib/features/attendance/presentation/widgets/attendance_calendar.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Attendance Calendar Widget (Student / Parent)
///
/// ✅ Read-only calendar-style view
/// ✅ Shows P / A / H (Present / Absent / Half-day)
/// ✅ Works for month-range and also for longer ranges (groups by month)
///
/// Expected record item:
/// { date: "YYYY-MM-DD", morning: "P/A/...", afternoon: "P/A/...", final: "P/A/H" }
class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.records,
  });

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.rLg),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
        ),
        child: Text(
          'No attendance records found for the selected period.',
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final grouped = _groupByYearMonth(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LegendRow(scheme: scheme),
        const SizedBox(height: 12),
        for (final entry in grouped.entries) ...[
          _MonthHeader(year: entry.key.year, month: entry.key.month),
          const SizedBox(height: 10),
          _MonthGrid(
            year: entry.key.year,
            month: entry.key.month,
            records: entry.value,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Map<_YearMonth, List<_AttendanceDay>> _groupByYearMonth(List<Map<String, dynamic>> raw) {
    final map = <_YearMonth, List<_AttendanceDay>>{};

    for (final r in raw) {
      final dateStr = (r['date'] ?? '').toString();
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) continue;

      final finalStatus = ((r['final'] ?? '').toString()).trim().toUpperCase();
      final morning = ((r['morning'] ?? '').toString()).trim().toUpperCase();
      final afternoon = ((r['afternoon'] ?? '').toString()).trim().toUpperCase();

      final key = _YearMonth(dt.year, dt.month);
      final list = map.putIfAbsent(key, () => <_AttendanceDay>[]);
      list.add(
        _AttendanceDay(
          date: DateTime(dt.year, dt.month, dt.day),
          morning: morning,
          afternoon: afternoon,
          finalStatus: finalStatus,
        ),
      );
    }

    // Sort months and days for stable UI
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => a.year != b.year ? a.year.compareTo(b.year) : a.month.compareTo(b.month));

    final out = <_YearMonth, List<_AttendanceDay>>{};
    for (final k in sortedKeys) {
      final days = map[k]!..sort((a, b) => a.date.day.compareTo(b.date.day));
      out[k] = days;
    }
    return out;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, Color bg, Color fg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: fg,
              ),
        ),
      );
    }

    final p = _StatusStyle.present(scheme);
    final a = _StatusStyle.absent(scheme);
    final h = _StatusStyle.halfDay(scheme);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('P • Present', p.bgColor, p.textColor),
        chip('A • Absent', a.bgColor, a.textColor),
        chip('H • Half Day', h.bgColor, h.textColor),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime(year, month, 1);
    final title = '${_monthName(dt.month)} ${dt.year}';
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }

  String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.year,
    required this.month,
    required this.records,
  });

  final int year;
  final int month;
  final List<_AttendanceDay> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Map by day-of-month for fast lookup
    final byDay = <int, _AttendanceDay>{};
    for (final r in records) {
      byDay[r.date.day] = r;
    }

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Monday-first grid (Mon=1..Sun=7)
    final leadingBlanks = firstDay.weekday - DateTime.monday;
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - (totalCells % 7)) % 7;
    final gridCount = totalCells + trailingBlanks;

    final weekLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          // Weekday header row
          Row(
            children: [
              for (final w in weekLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gridCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks || index >= leadingBlanks + daysInMonth) {
                return const SizedBox.shrink();
              }

              final dayNumber = (index - leadingBlanks) + 1;
              final record = byDay[dayNumber];

              final bool hasStatus = record != null && record.finalStatus.isNotEmpty;
              final status = (record?.finalStatus ?? '').trim().toUpperCase();

              final style = _StatusStyle.from(status, scheme);

              return InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.rMd),
                onTap: hasStatus
                    ? () => _showDayDetails(context, year, month, dayNumber, record!)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: hasStatus ? style.bgColor : scheme.surfaceContainerHighest.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(AppSpacing.rMd),
                    border: Border.all(
                      color: hasStatus ? style.borderColor : scheme.outlineVariant.withOpacity(0.25),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$dayNumber',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasStatus ? style.label : '—',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: hasStatus ? style.textColor : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDayDetails(BuildContext context, int year, int month, int day, _AttendanceDay record) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dt = DateTime(year, month, day);
    final title = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';

    final finalStyle = _StatusStyle.from(record.finalStatus, scheme);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),

              _kv('Morning', record.morning.isEmpty ? '—' : record.morning),
              const SizedBox(height: 8),
              _kv('Afternoon', record.afternoon.isEmpty ? '—' : record.afternoon),
              const SizedBox(height: 10),
              Divider(color: scheme.outlineVariant.withOpacity(0.5)),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: finalStyle.bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: finalStyle.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Final Status',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      finalStyle.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: finalStyle.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800))),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _AttendanceDay {
  final DateTime date;
  final String morning;
  final String afternoon;
  final String finalStatus;

  const _AttendanceDay({
    required this.date,
    required this.morning,
    required this.afternoon,
    required this.finalStatus,
  });
}

class _YearMonth {
  final int year;
  final int month;
  const _YearMonth(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _YearMonth && other.year == year && other.month == month);

  @override
  int get hashCode => Object.hash(year, month);
}

class _StatusStyle {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _StatusStyle({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  static _StatusStyle from(String status, ColorScheme scheme) {
    switch (status.trim().toUpperCase()) {
      case 'P':
        return present(scheme);
      case 'A':
        return absent(scheme);
      case 'H':
        return halfDay(scheme);
      default:
        return _StatusStyle(
          label: '—',
          bgColor: scheme.surfaceContainerHighest.withOpacity(0.35),
          borderColor: scheme.outlineVariant.withOpacity(0.25),
          textColor: scheme.onSurfaceVariant,
        );
    }
  }

  static _StatusStyle present(ColorScheme scheme) {
    // Green for Present (as per requirement)
    final fg = Colors.green.shade700;
    return _StatusStyle(
      label: 'P',
      bgColor: fg.withOpacity(0.12),
      borderColor: fg.withOpacity(0.25),
      textColor: fg,
    );
  }

  static _StatusStyle absent(ColorScheme scheme) {
    // Red for Absent (as per requirement)
    final fg = Colors.red.shade700;
    return _StatusStyle(
      label: 'A',
      bgColor: fg.withOpacity(0.12),
      borderColor: fg.withOpacity(0.25),
      textColor: fg,
    );
  }

  static _StatusStyle halfDay(ColorScheme scheme) {
    // Orange for Half-day (as per requirement)
    final fg = Colors.orange.shade800;
    return _StatusStyle(
      label: 'H',
      bgColor: fg.withOpacity(0.14),
      borderColor: fg.withOpacity(0.28),
      textColor: fg,
    );
  }
}
