// lib/features/attendance/presentation/screens/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../widgets/attendance_calendar.dart';
import '../widgets/attendance_filters.dart';

/// Attendance Screen (Student / Parent)
///
/// ✅ Shows ONLY logged-in student's attendance (backend-scoped)
/// ✅ Filters: Day / Week / Month / Year / Custom (mapped to backend month/year/fromDate/toDate)
/// ✅ Calendar view with P/A/H
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  late AttendanceFilter _filter;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = AttendanceFilter(
      mode: AttendanceFilterMode.month,
      month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
      year: '${now.year}',
    );
    _future = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() {
    final repo = ref.read(attendanceRepositoryProvider);
    return repo.getMyAttendance(
      month: _filter.month,
      year: _filter.year,
      fromDate: _filter.fromDate,
      toDate: _filter.toDate,
    );
  }

  void _reload() {
    setState(() => _future = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Attendance'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Your global Lottie overlay can be triggered in ApiClient/interceptors.
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return AppErrorView(
                    message: 'Unable to load attendance.',
                    onRetry: _reload,
                  );
                }

                final data = snapshot.data ?? <String, dynamic>{};

                final summary = (data['summary'] is Map)
                    ? Map<String, dynamic>.from(data['summary'] as Map)
                    : <String, dynamic>{};

                final rawRecords = data['records'];
                final records = (rawRecords is List)
                    ? rawRecords
                        .whereType<Map>()
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList()
                    : <Map<String, dynamic>>[];

                if (records.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AttendanceFilters(
                        value: _filter,
                        onChanged: (f) {
                          setState(() {
                            _filter = f;
                            _future = _fetch();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const AppEmptyView(
                        title: 'No Attendance Data',
                        subtitle:
                            'Attendance has not been marked for the selected period.',
                      ),
                    ],
                  );
                }

                final present = _toInt(summary['present']);
                final absent = _toInt(summary['absent']);
                final halfDay = _toInt(summary['halfDay']);
                final totalDays = _toInt(summary['totalDays']);
                final percentage = _toNum(summary['percentage']);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AttendanceFilters(
                      value: _filter,
                      onChanged: (f) {
                        setState(() {
                          _filter = f;
                          _future = _fetch();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // SUMMARY
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Attendance Summary',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryItem(
                                  label: 'Present',
                                  value: '$present',
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SummaryItem(
                                  label: 'Absent',
                                  value: '$absent',
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SummaryItem(
                                  label: 'Half Day',
                                  value: '$halfDay',
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withOpacity(0.6)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total Days: $totalDays',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: totalDays <= 0
                                  ? 0
                                  : (percentage / 100.0).clamp(0, 1).toDouble(),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CALENDAR
                    AttendanceCalendar(records: records),

                    const SizedBox(height: 16),

                    // OPTIONAL: compact list for quick scan
                    Text(
                      'Recent Records',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    _RecordsList(records: records),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
  num _toNum(dynamic v) => num.tryParse(v?.toString() ?? '') ?? 0;
}

class _RecordsList extends StatelessWidget {
  const _RecordsList({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    // Sort latest first
    final sorted = [...records];
    sorted.sort((a, b) {
      final ad = DateTime.tryParse((a['date'] ?? '').toString());
      final bd = DateTime.tryParse((b['date'] ?? '').toString());
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    // Show only recent 10
    final visible = sorted.take(10).toList();

    return Column(
      children: [
        for (final r in visible) ...[
          _RecordTile(record: r, scheme: scheme),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.scheme});

  final Map<String, dynamic> record;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final date = (record['date'] ?? '').toString();
    final morning = (record['morning'] ?? '').toString().trim().toUpperCase();
    final afternoon =
        (record['afternoon'] ?? '').toString().trim().toUpperCase();
    final finalStatus = (record['final'] ?? '').toString().trim().toUpperCase();

    Color statusColor;
    String statusLabel;
    switch (finalStatus) {
      case 'P':
        statusColor = Colors.green.shade700;
        statusLabel = 'Present';
        break;
      case 'A':
        statusColor = Colors.red.shade700;
        statusLabel = 'Absent';
        break;
      case 'H':
        statusColor = Colors.orange.shade800;
        statusLabel = 'Half Day';
        break;
      default:
        statusColor = scheme.outline;
        statusLabel = '-';
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.rMd),
              border: Border.all(color: statusColor.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(
                finalStatus.isEmpty ? '—' : finalStatus,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Morning: ${morning.isEmpty ? '—' : morning}   •   Afternoon: ${afternoon.isEmpty ? '—' : afternoon}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
