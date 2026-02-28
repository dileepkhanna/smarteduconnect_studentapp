// lib/features/exams/presentation/screens/exam_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';

/// Exam Schedule Screen (Student / Parent)
///
/// ✅ Backend (authoritative):
/// GET /api/exams/student/my-schedule?examId=... (optional)
///
/// Rules:
/// • Shows ONLY logged-in student's class & section exams (backend enforced)
/// • Read-only
class ExamScheduleScreen extends ConsumerStatefulWidget {
  const ExamScheduleScreen({super.key});

  @override
  ConsumerState<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends ConsumerState<ExamScheduleScreen> {
  late Future<_ExamScheduleData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<_ExamScheduleData> _fetch() async {
    final repo = ref.read(examsRepositoryProvider);
    Object? hardError;

    List<Map<String, dynamic>> exams = const <Map<String, dynamic>>[];
    List<Map<String, dynamic>> schedules = const <Map<String, dynamic>>[];

    // Primary dataset for this page: student schedule.
    // If this fails, we keep the error unless exams can still provide something.
    try {
      final scheduleRaw = await repo.getMyExamSchedule();
      schedules = scheduleRaw
          .whereType<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false);
    } catch (e) {
      hardError = e;
    }

    // Secondary dataset: exams list.
    // On older backend deployments this may return 403/404; treat as soft failure.
    try {
      final examsRaw = await repo.getMyClassExams();
      exams = examsRaw
          .whereType<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false);
    } catch (_) {
      // ignore soft failure
    }

    if (schedules.isEmpty && exams.isEmpty && hardError != null) {
      throw hardError;
    }

    return _ExamScheduleData(
      exams: exams,
      schedules: schedules,
    );
  }

  void _reload() {
    setState(() => _future = _fetch());
  }

  Color _alpha(Color c, double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round();
    return c.withAlpha(a);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: 'Exam Schedule'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: FutureBuilder<_ExamScheduleData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return AppErrorView(
                    message: 'Unable to load exam schedule.',
                    onRetry: _reload,
                  );
                }

                final vm = snapshot.data ??
                    const _ExamScheduleData(
                        exams: <Map<String, dynamic>>[],
                        schedules: <Map<String, dynamic>>[]);
                final exams = vm.exams;
                final rows = vm.schedules;
                if (exams.isEmpty && rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppEmptyView(
                        title: 'No Exams Found',
                        subtitle: 'No exams are available for your class yet.',
                      ),
                    ],
                  );
                }

                // Group by examId
                final groups = <String, _ExamGroup>{};
                for (final r in rows) {
                  final examId = (r['examId'] ?? '').toString();
                  final examName = (r['examName'] ?? 'Exam').toString();

                  final item = _ScheduleItem(
                    examId: examId,
                    examName: examName,
                    subject: (r['subject'] ?? '').toString(),
                    date: (r['date'] ?? '').toString(),
                    time: (r['time'] ?? '').toString(),
                  );

                  (groups[examId] ??=
                          _ExamGroup(examId: examId, examName: examName))
                      .items
                      .add(item);
                }

                final groupList = groups.values.toList(growable: false)
                  ..sort((a, b) => a.startDate.compareTo(b.startDate));

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _alpha(scheme.primary, 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.rMd),
                              border: Border.all(
                                  color: _alpha(scheme.primary, 0.25)),
                            ),
                            child: Icon(Icons.event_note_rounded,
                                color: scheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Exam Schedule',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Only your class and section exams are shown.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (exams.isNotEmpty) ...[
                      for (final exam in exams) ...[
                        _ClassExamCard(exam: exam, alpha: _alpha),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 6),
                    ],
                    if (rows.isNotEmpty)
                      for (final g in groupList) ...[
                        _ExamGroupCard(
                          group: g,
                          alpha: _alpha,
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamScheduleData {
  const _ExamScheduleData({
    required this.exams,
    required this.schedules,
  });

  final List<Map<String, dynamic>> exams;
  final List<Map<String, dynamic>> schedules;
}

class _ClassExamCard extends StatelessWidget {
  const _ClassExamCard({
    required this.exam,
    required this.alpha,
  });

  final Map<String, dynamic> exam;
  final Color Function(Color, double) alpha;

  String _fmtDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[(dt.month - 1).clamp(0, 11)]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final examName = (exam['examName'] ?? 'Exam').toString();
    final startDate = (exam['startDate'] ?? '').toString();
    final endDate = (exam['endDate'] ?? '').toString();
    final year = (exam['academicYear'] ?? '').toString();

    String dateText = 'Dates will be updated';
    if (startDate.isNotEmpty && endDate.isNotEmpty) {
      dateText = startDate == endDate
          ? _fmtDate(startDate)
          : '${_fmtDate(startDate)} -> ${_fmtDate(endDate)}';
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: alpha(scheme.primary, 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.rMd),
              border: Border.all(color: alpha(scheme.primary, 0.25)),
            ),
            child:
                Icon(Icons.assignment_turned_in_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (year.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Academic Year: $year',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleItem {
  _ScheduleItem({
    required this.examId,
    required this.examName,
    required this.subject,
    required this.date,
    required this.time,
  });

  final String examId;
  final String examName;
  final String subject;
  final String date; // YYYY-MM-DD
  final String time;

  DateTime get parsedDate => DateTime.tryParse(date) ?? DateTime(2100);
}

class _ExamGroup {
  _ExamGroup({required this.examId, required this.examName});

  final String examId;
  final String examName;
  final List<_ScheduleItem> items = [];

  DateTime get startDate {
    if (items.isEmpty) return DateTime(2100);
    final sorted = [...items]
      ..sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
    return sorted.first.parsedDate;
  }

  DateTime get endDate {
    if (items.isEmpty) return DateTime(2100);
    final sorted = [...items]
      ..sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
    return sorted.last.parsedDate;
  }
}

class _ExamGroupCard extends StatelessWidget {
  const _ExamGroupCard({
    required this.group,
    required this.alpha,
  });

  final _ExamGroup group;
  final Color Function(Color, double) alpha;

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[(dt.month - 1).clamp(0, 11)]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final items = [...group.items]
      ..sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
    final rangeText = items.isEmpty
        ? ''
        : (group.startDate == group.endDate)
            ? _fmtDate(group.startDate)
            : '${_fmtDate(group.startDate)}  —  ${_fmtDate(group.endDate)}';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.examName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: alpha(scheme.primary, 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.rXl),
                  border: Border.all(color: alpha(scheme.primary, 0.22)),
                ),
                child: Text(
                  '${items.length} paper${items.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                ),
              ),
            ],
          ),
          if (rangeText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rangeText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          for (final s in items) ...[
            _ScheduleRow(item: s, alpha: alpha),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item, required this.alpha});

  final _ScheduleItem item;
  final Color Function(Color, double) alpha;

  String _fmtShortDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[(dt.month - 1).clamp(0, 11)]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alpha(scheme.surface, 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        border: Border.all(color: alpha(scheme.outlineVariant, 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: alpha(scheme.primary, 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.rMd),
              border: Border.all(color: alpha(scheme.primary, 0.22)),
            ),
            child: Column(
              children: [
                Text(
                  _fmtShortDate(item.date),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.schedule_rounded, size: 16, color: scheme.primary),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject.isEmpty ? 'Subject' : item.subject,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time.isEmpty ? 'Timing will be updated' : item.time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
