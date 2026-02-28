// lib/features/exams/presentation/screens/exam_result_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';

/// Exam Result Detail Screen (Student / Parent)
///
/// ✅ Backend (authoritative):
/// GET /api/exams/student/my-result?examId=...
///
/// Rules:
/// • Visible ONLY after teacher publishes result (backend enforces)
class ExamResultScreen extends ConsumerStatefulWidget {
  const ExamResultScreen({
    super.key,
    required this.examId,
    required this.examName,
  });

  final String examId;
  final String examName;

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  late Future<_ResultLoad> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<_ResultLoad> _fetch() async {
    final repo = ref.read(examsRepositoryProvider);
    try {
      final data = await repo.getMyExamResultDetail(widget.examId);
      return _ResultLoad.data(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 404 || status == 403) {
        // Backend: "Result not published"
        return const _ResultLoad.notPublished();
      }
      // Fail-soft to avoid blocking the result screen on transient backend issues.
      return _ResultLoad.data(const <String, dynamic>{});
    } catch (_) {
      return _ResultLoad.data(const <String, dynamic>{});
    }
  }

  void _reload() {
    setState(() => _future = _fetch());
  }

  Color _alpha(Color c, double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round();
    return c.withAlpha(a);
  }

  num _toNum(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  String _fmtDateTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = months[(dt.month - 1).clamp(0, 11)];
    return '$m ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: widget.examName),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: FutureBuilder<_ResultLoad>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return AppErrorView(
                    message: 'Unable to load exam result.',
                    onRetry: _reload,
                  );
                }

                final state = snapshot.data;
                if (state == null || state.notPublished) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppEmptyView(
                        title: 'Result Not Published Yet',
                        subtitle: 'Your teacher has not published the result for this exam.',
                      ),
                    ],
                  );
                }

                final data = state.data ?? <String, dynamic>{};
                if (data.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppEmptyView(
                        title: 'No Result Data',
                        subtitle: 'Result details are not available right now.',
                      ),
                    ],
                  );
                }

                final totalObt = _toNum(data['totalObtained']);
                final totalMax = _toNum(data['totalMax']);
                final percent = _toNum(data['percentage']);
                final grade = (data['grade'] ?? '').toString();
                final status = (data['resultStatus'] ?? '').toString();
                final publishedAt = (data['publishedAt'] ?? '').toString();

                final subjectsRaw = (data['subjects'] is List) ? data['subjects'] as List : const [];
                final subjects = subjectsRaw
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(growable: false);

                final statusColor = status.toUpperCase() == 'PASS'
                    ? scheme.primary
                    : scheme.error;

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
                              color: _alpha(statusColor, 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.rMd),
                              border: Border.all(color: _alpha(statusColor, 0.25)),
                            ),
                            child: Icon(Icons.assessment_rounded, color: statusColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Result Summary',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                if (publishedAt.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Published: ${_fmtDateTime(publishedAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _Pill(
                            label: status.isEmpty ? '—' : status,
                            color: statusColor,
                            alpha: _alpha,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              label: 'Percentage',
                              value: '${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}%',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            color: _alpha(scheme.outlineVariant, 0.65),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'Grade',
                              value: grade.isEmpty ? '—' : grade,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            color: _alpha(scheme.outlineVariant, 0.65),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'Total',
                              value: '${totalObt.toStringAsFixed(0)}/${totalMax.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Subject-wise Marks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),

                    if (subjects.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'No subject breakdown available.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    else
                      for (final s in subjects) ...[
                        _SubjectRow(
                          subject: (s['subject'] ?? '').toString(),
                          obtained: _toNum(s['obtained']),
                          max: _toNum(s['max']),
                          alpha: _alpha,
                        ),
                        const SizedBox(height: 10),
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

class _ResultLoad {
  const _ResultLoad.data(this.data) : notPublished = false;
  const _ResultLoad.notPublished()
      : data = null,
        notPublished = true;

  final Map<String, dynamic>? data;
  final bool notPublished;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.alpha,
  });

  final String label;
  final Color color;
  final Color Function(Color, double) alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: alpha(color, 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.rXl),
        border: Border.all(color: alpha(color, 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.obtained,
    required this.max,
    required this.alpha,
  });

  final String subject;
  final num obtained;
  final num max;
  final Color Function(Color, double) alpha;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (max <= 0) ? 0 : (obtained / max) * 100;

    final Color barColor;
    if (pct >= 90) {
      barColor = scheme.primary;
    } else if (pct >= 60) {
      barColor = scheme.tertiary;
    } else {
      barColor = scheme.error;
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.isEmpty ? 'Subject' : subject,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${obtained.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              _Pill(
                label: '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%',
                color: barColor,
                alpha: alpha,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.rMd),
            child: LinearProgressIndicator(
              value: max <= 0 ? 0 : (obtained / max).clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: alpha(scheme.outlineVariant, 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
