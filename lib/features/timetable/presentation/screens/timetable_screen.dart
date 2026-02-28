// lib/features/timetable/presentation/screens/timetable_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/notifications/timetable_progress_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../widgets/timetable_card.dart';

/// Timetable Screen (Student/Parent + Teacher)
///
/// ✅ Uses REAL backend via TimetableApi:
/// - STUDENT: GET /timetables/student/me (fallback: /timetables/student/my)
/// - TEACHER: GET /timetables/teacher/my
///
/// ✅ Shows current/next class with moving progress bar (Uber/Ola style).
class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  late DateTime _selectedDate;
  late Future<Map<String, dynamic>> _future;

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _future = _load();

    // refresh progress bar for ongoing class
    _ticker = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(TimetableProgressNotificationService.instance.clear());
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final repo = ref.read(timetableRepositoryProvider);
    try {
      return await repo.getTimetableByDate(_yyyyMmDd(_selectedDate));
    } catch (_) {
      return <String, dynamic>{
        'date': _yyyyMmDd(_selectedDate),
        'dayOfWeek': _selectedDate.weekday,
        'dayLabel': _dowShort(_selectedDate.weekday).toUpperCase(),
        'type': 'STUDENT',
        'meta': const <String, dynamic>{},
        'slots': const <Map<String, dynamic>>[],
      };
    }
  }

  void _reload() => setState(() => _future = _load());

  String _yyyyMmDd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _weekStart(DateTime date) {
    // Monday as start
    final wd = date.weekday; // Mon=1
    final start = DateTime(date.year, date.month, date.day).subtract(Duration(days: wd - 1));
    return start;
  }

  String _dowShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return 'Mon';
    }
  }

  String _monthShort(int month) {
    const months = <String>[
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  int _minutesFromClock(String v) {
    // Accept "09:00", "9:00 AM", "09:00 AM"
    final s = v.trim();
    if (s.isEmpty) return -1;

    final parts = s.split(RegExp(r'\s+'));
    final timePart = parts.first;
    final ampm = parts.length > 1 ? parts[1].toUpperCase() : '';

    final hm = timePart.split(':');
    if (hm.length < 2) return -1;

    int h = int.tryParse(hm[0]) ?? -1;
    final m = int.tryParse(hm[1]) ?? -1;
    if (h < 0 || m < 0) return -1;

    if (ampm == 'AM') {
      if (h == 12) h = 0;
    } else if (ampm == 'PM') {
      if (h != 12) h += 12;
    }
    return h * 60 + m;
  }

  int _nowMinutes() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final weekStart = _weekStart(_selectedDate);
    final weekDays = List<DateTime>.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Scaffold(
      appBar: AppAppBar(title: 'My Time Table'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: Column(
            children: [
              // Week strip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_monthShort(_selectedDate.month)} ${_selectedDate.year}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: weekDays.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final d = weekDays[i];
                            final selected = d.year == _selectedDate.year &&
                                d.month == _selectedDate.month &&
                                d.day == _selectedDate.day;
                            final today = _isToday(d);

                            final bg = selected
                                ? scheme.primary
                                : scheme.surfaceContainerHighest;
                            final fg = selected ? scheme.onPrimary : scheme.onSurface;

                            return InkWell(
                              borderRadius: BorderRadius.circular(AppSpacing.rLg),
                              onTap: () {
                                setState(() {
                                  _selectedDate = DateTime(d.year, d.month, d.day);
                                  _future = _load();
                                });
                              },
                              child: Container(
                                width: 68,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppSpacing.rLg),
                                  color: bg,
                                  border: Border.all(
                                    color: selected
                                        ? Colors.transparent
                                        : (today
                                            ? scheme.primary.withValues(alpha: 0.35)
                                            : scheme.outlineVariant),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _dowShort(d.weekday),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: fg,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      d.day.toString(),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: fg,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Selected: ${_yyyyMmDd(_selectedDate)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh',
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Day slots
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return AppErrorView(
                        message: 'Unable to load timetable.',
                        onRetry: _reload,
                      );
                    }

                    final data = snap.data ?? <String, dynamic>{};
                    final type = (data['type'] ?? '').toString().toUpperCase();
                    final isTeacherView = type == 'TEACHER';

                    final meta = (data['meta'] is Map)
                        ? Map<String, dynamic>.from(data['meta'] as Map)
                        : <String, dynamic>{};

                    final classNumber = meta['classNumber'];
                    final section = meta['section'];

                    final slotsRaw = data['slots'];
                    final slots = (slotsRaw is List)
                        ? slotsRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e as Map)).toList()
                        : <Map<String, dynamic>>[];

                    if (slots.isEmpty) {
                      return AppEmptyView(
                        title: 'No Classes',
                        subtitle: 'No classes scheduled for this day.',
                      );
                    }

                    // Determine current/next slot based on start/end times (only for today)
                    final bool today = _isToday(_selectedDate);
                    final nowMin = today ? _nowMinutes() : -1;

                    int nextIdx = -1;
                    int ongoingIdx = -1;

                    if (today) {
                      for (int i = 0; i < slots.length; i++) {
                        final st = _minutesFromClock((slots[i]['startTime'] ?? '').toString());
                        final en = _minutesFromClock((slots[i]['endTime'] ?? '').toString());
                        if (st >= 0 && en >= 0 && nowMin >= st && nowMin < en) {
                          ongoingIdx = i;
                          break;
                        }
                      }
                      if (ongoingIdx == -1) {
                        for (int i = 0; i < slots.length; i++) {
                          final st = _minutesFromClock((slots[i]['startTime'] ?? '').toString());
                          if (st >= 0 && nowMin < st) {
                            nextIdx = i;
                            break;
                          }
                        }
                      } else {
                        // next is first slot after ongoing
                        for (int i = ongoingIdx + 1; i < slots.length; i++) {
                          final st = _minutesFromClock((slots[i]['startTime'] ?? '').toString());
                          if (st >= 0 && nowMin < st) {
                            nextIdx = i;
                            break;
                          }
                        }
                      }
                    }

                    final activeNotification = (() {
                      if (!today || ongoingIdx < 0 || ongoingIdx >= slots.length) return null;
                      final current = slots[ongoingIdx];
                      final st = _minutesFromClock((current['startTime'] ?? '').toString());
                      final en = _minutesFromClock((current['endTime'] ?? '').toString());
                      if (st < 0 || en <= st) return null;
                      final pct = (((nowMin - st) / (en - st)) * 100).round().clamp(0, 100);
                      final subject = (current['subject'] ?? 'Class').toString();
                      final timing = (current['timing'] ?? '').toString().trim();
                      return (
                        title: 'Now: $subject',
                        body: timing.isEmpty ? 'Class in progress... $pct%' : '$timing - $pct%',
                        progress: pct,
                      );
                    })();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (activeNotification != null) {
                        unawaited(
                          TimetableProgressNotificationService.instance.showLiveProgress(
                            title: activeNotification.title,
                            body: activeNotification.body,
                            progressPercent: activeNotification.progress,
                          ),
                        );
                      } else {
                        unawaited(TimetableProgressNotificationService.instance.clear());
                      }
                    });

                    return RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          if (!isTeacherView && classNumber != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.school_rounded, color: scheme.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                      child: Text(
                                        'Your Class: $classNumber${(section ?? '').toString()}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          ...List<Widget>.generate(slots.length, (i) {
                            final slot = slots[i];

                            TimetableSlotStatus status = TimetableSlotStatus.upcoming;
                            double progress = 0;

                            if (today) {
                              final st = _minutesFromClock((slot['startTime'] ?? '').toString());
                              final en = _minutesFromClock((slot['endTime'] ?? '').toString());

                              if (st >= 0 && en >= 0) {
                                if (nowMin >= en) {
                                  status = TimetableSlotStatus.completed;
                                } else if (nowMin >= st && nowMin < en) {
                                  status = TimetableSlotStatus.ongoing;
                                  final denom = (en - st).toDouble();
                                  progress = denom <= 0 ? 0 : ((nowMin - st) / denom);
                                } else {
                                  status = TimetableSlotStatus.upcoming;
                                }
                              }

                              if (i == nextIdx) status = TimetableSlotStatus.next;
                              if (i == ongoingIdx) status = TimetableSlotStatus.ongoing;
                            } else {
                              status = TimetableSlotStatus.upcoming;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: TimetableSlotCard(
                                slot: slot,
                                status: status,
                                progress01: progress,
                                isTeacherView: isTeacherView,
                              ),
                            );
                          }),

                          const SizedBox(height: 16),
                          Text(
                            'Tip: Ongoing & Next class updates automatically on today’s date.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
