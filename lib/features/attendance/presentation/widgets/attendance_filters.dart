// lib/features/attendance/presentation/widgets/attendance_filters.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';

enum AttendanceFilterMode { day, week, month, year, custom }

class AttendanceFilter {
  final AttendanceFilterMode mode;

  /// Month can be "YYYY-MM" (recommended) or "1..12".
  final String? month; // "YYYY-MM"
  final String? year; // "YYYY"

  /// Custom range / Day / Week
  final String? fromDate; // "YYYY-MM-DD"
  final String? toDate; // "YYYY-MM-DD"

  const AttendanceFilter({
    required this.mode,
    this.month,
    this.year,
    this.fromDate,
    this.toDate,
  });

  AttendanceFilter copyWith({
    AttendanceFilterMode? mode,
    String? month,
    String? year,
    String? fromDate,
    String? toDate,
    bool clearMonth = false,
    bool clearYear = false,
    bool clearRange = false,
  }) {
    return AttendanceFilter(
      mode: mode ?? this.mode,
      month: clearMonth ? null : (month ?? this.month),
      year: clearYear ? null : (year ?? this.year),
      fromDate: clearRange ? null : (fromDate ?? this.fromDate),
      toDate: clearRange ? null : (toDate ?? this.toDate),
    );
  }

  bool get hasValidRange =>
      (fromDate?.isNotEmpty ?? false) && (toDate?.isNotEmpty ?? false);
}

class AttendanceFilters extends StatelessWidget {
  const AttendanceFilters({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AttendanceFilter value;
  final ValueChanged<AttendanceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeChips(
            mode: value.mode,
            onModeChanged: (m) {
              final now = DateTime.now();
              switch (m) {
                case AttendanceFilterMode.month:
                  onChanged(
                    AttendanceFilter(
                      mode: AttendanceFilterMode.month,
                      month: _ym(DateTime(now.year, now.month, 1)),
                      year: '${now.year}',
                    ),
                  );
                  break;
                case AttendanceFilterMode.year:
                  onChanged(
                    AttendanceFilter(
                      mode: AttendanceFilterMode.year,
                      year: '${now.year}',
                    ),
                  );
                  break;
                case AttendanceFilterMode.day:
                  final d = _ymd(now);
                  onChanged(
                    AttendanceFilter(
                      mode: AttendanceFilterMode.day,
                      fromDate: d,
                      toDate: d,
                    ),
                  );
                  break;
                case AttendanceFilterMode.week:
                  final range = _weekRange(now);
                  onChanged(
                    AttendanceFilter(
                      mode: AttendanceFilterMode.week,
                      fromDate: range.$1,
                      toDate: range.$2,
                    ),
                  );
                  break;
                case AttendanceFilterMode.custom:
                  // Keep old range if any, else default to last 7 days.
                  if (value.hasValidRange) {
                    onChanged(value.copyWith(
                        mode: AttendanceFilterMode.custom,
                        clearMonth: true,
                        clearYear: true));
                  } else {
                    final to = now;
                    final from = now.subtract(const Duration(days: 6));
                    onChanged(
                      AttendanceFilter(
                        mode: AttendanceFilterMode.custom,
                        fromDate: _ymd(from),
                        toDate: _ymd(to),
                      ),
                    );
                  }
                  break;
              }
            },
          ),
          const SizedBox(height: 14),
          _ModeControls(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ModeChips extends StatelessWidget {
  const _ModeChips({
    required this.mode,
    required this.onModeChanged,
  });

  final AttendanceFilterMode mode;
  final ValueChanged<AttendanceFilterMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(AttendanceFilterMode m, String label) {
      final selected = m == mode;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onModeChanged(m),
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(AttendanceFilterMode.day, 'Day'),
        chip(AttendanceFilterMode.week, 'Week'),
        chip(AttendanceFilterMode.month, 'Month'),
        chip(AttendanceFilterMode.year, 'Year'),
        chip(AttendanceFilterMode.custom, 'Custom'),
      ],
    );
  }
}

class _ModeControls extends StatelessWidget {
  const _ModeControls({
    required this.value,
    required this.onChanged,
  });

  final AttendanceFilter value;
  final ValueChanged<AttendanceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    switch (value.mode) {
      case AttendanceFilterMode.month:
        return _MonthControls(value: value, onChanged: onChanged);
      case AttendanceFilterMode.year:
        return _YearControls(value: value, onChanged: onChanged);
      case AttendanceFilterMode.day:
        return _SingleDateControls(
          title: 'Select Day',
          selectedDate: value.fromDate,
          onPick: (d) {
            onChanged(
              AttendanceFilter(
                  mode: AttendanceFilterMode.day, fromDate: d, toDate: d),
            );
          },
        );
      case AttendanceFilterMode.week:
        return _SingleDateControls(
          title: 'Select Week (pick any day)',
          selectedDate: value.fromDate,
          onPick: (pickedYmd) {
            final dt = DateTime.tryParse(pickedYmd);
            if (dt == null) return;
            final range = _weekRange(dt);
            onChanged(
              AttendanceFilter(
                mode: AttendanceFilterMode.week,
                fromDate: range.$1,
                toDate: range.$2,
              ),
            );
          },
        );
      case AttendanceFilterMode.custom:
        return _RangeControls(value: value, onChanged: onChanged);
    }
  }
}

class _MonthControls extends StatelessWidget {
  const _MonthControls({required this.value, required this.onChanged});

  final AttendanceFilter value;
  final ValueChanged<AttendanceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selectedYM = value.month ?? _ym(DateTime(now.year, now.month, 1));
    final selected = _parseYM(selectedYM) ?? DateTime(now.year, now.month, 1);

    final year = (value.year?.isNotEmpty ?? false)
        ? int.tryParse(value.year!) ?? selected.year
        : selected.year;

    final months = List.generate(12, (i) {
      final m = i + 1;
      final label = _monthName(m);
      return DropdownMenuItem<int>(
        value: m,
        child: Text(label),
      );
    });

    final years = _yearOptions(now.year).map((y) {
      return DropdownMenuItem<int>(
        value: y,
        child: Text('$y'),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: _DropField<int>(
            label: 'Month',
            value: selected.month,
            items: months,
            onChanged: (m) {
              if (m == null) return;
              final ym = _ym(DateTime(year, m, 1));
              onChanged(
                AttendanceFilter(
                  mode: AttendanceFilterMode.month,
                  month: ym,
                  year: '$year',
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DropField<int>(
            label: 'Year',
            value: year,
            items: years,
            onChanged: (y) {
              if (y == null) return;
              final ym = _ym(DateTime(y, selected.month, 1));
              onChanged(
                AttendanceFilter(
                  mode: AttendanceFilterMode.month,
                  month: ym,
                  year: '$y',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _YearControls extends StatelessWidget {
  const _YearControls({required this.value, required this.onChanged});

  final AttendanceFilter value;
  final ValueChanged<AttendanceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = int.tryParse(value.year ?? '') ?? now.year;

    final years = _yearOptions(now.year).map((y) {
      return DropdownMenuItem<int>(
        value: y,
        child: Text('$y'),
      );
    }).toList();

    return _DropField<int>(
      label: 'Year',
      value: current,
      items: years,
      onChanged: (y) {
        if (y == null) return;
        onChanged(
          AttendanceFilter(
            mode: AttendanceFilterMode.year,
            year: '$y',
          ),
        );
      },
    );
  }
}

class _SingleDateControls extends StatelessWidget {
  const _SingleDateControls({
    required this.title,
    required this.selectedDate,
    required this.onPick,
  });

  final String title;
  final String? selectedDate; // YMD
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.rLg),
      onTap: () async {
        final initial = DateTime.tryParse(selectedDate ?? '') ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime(2100, 12, 31),
          initialDate: initial,
        );
        if (picked == null) return;
        onPick(_ymd(picked));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.rLg),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    (selectedDate?.isNotEmpty ?? false)
                        ? selectedDate!
                        : 'Tap to pick date',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_month_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _RangeControls extends StatelessWidget {
  const _RangeControls({required this.value, required this.onChanged});

  final AttendanceFilter value;
  final ValueChanged<AttendanceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final from = value.fromDate;
    final to = value.toDate;

    return Column(
      children: [
        _SingleDateControls(
          title: 'From Date',
          selectedDate: from,
          onPick: (d) {
            final next = value.copyWith(
              mode: AttendanceFilterMode.custom,
              fromDate: d,
              clearMonth: true,
              clearYear: true,
            );
            // If toDate exists but is before fromDate, align it.
            final fdt = DateTime.tryParse(d);
            final tdt = DateTime.tryParse(next.toDate ?? '');
            if (fdt != null && tdt != null && tdt.isBefore(fdt)) {
              onChanged(next.copyWith(toDate: d));
            } else {
              onChanged(next);
            }
          },
        ),
        const SizedBox(height: 10),
        _SingleDateControls(
          title: 'To Date',
          selectedDate: to,
          onPick: (d) {
            final next = value.copyWith(
              mode: AttendanceFilterMode.custom,
              toDate: d,
              clearMonth: true,
              clearYear: true,
            );
            final fdt = DateTime.tryParse(next.fromDate ?? '');
            final tdt = DateTime.tryParse(d);
            if (fdt != null && tdt != null && tdt.isBefore(fdt)) {
              onChanged(next.copyWith(fromDate: d));
            } else {
              onChanged(next);
            }
          },
        ),
      ],
    );
  }
}

class _DropField<T> extends StatelessWidget {
  const _DropField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        );
    final themedItems = items
        .map(
          (item) => DropdownMenuItem<T>(
            value: item.value,
            enabled: item.enabled,
            onTap: item.onTap,
            child: DefaultTextStyle.merge(
              style: textStyle,
              child: IconTheme.merge(
                data: IconThemeData(color: scheme.onSurface),
                child: item.child,
              ),
            ),
          ),
        )
        .toList(growable: false);

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: themedItems,
      onChanged: onChanged,
      style: textStyle,
      dropdownColor: scheme.surface,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rLg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rLg),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rLg),
          borderSide: BorderSide(color: scheme.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------- helpers ----------

String _ymd(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _ym(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$y-$m';
}

DateTime? _parseYM(String ym) {
  // Accept "YYYY-MM"
  final parts = ym.split('-');
  if (parts.length < 2) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (y == null || m == null) return null;
  return DateTime(y, m, 1);
}

/// Returns (fromYmd, toYmd) for Monday..Sunday.
(String, String) _weekRange(DateTime anyDay) {
  final monday =
      anyDay.subtract(Duration(days: anyDay.weekday - DateTime.monday));
  final sunday = monday.add(const Duration(days: 6));
  return (_ymd(monday), _ymd(sunday));
}

List<int> _yearOptions(int currentYear) {
  // Last 5 years + current + next 1 (can adjust as needed)
  final start = currentYear - 5;
  final end = currentYear + 1;
  return [for (int y = start; y <= end; y++) y];
}

String _monthName(int month) {
  const labels = [
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
  return labels[month - 1];
}
