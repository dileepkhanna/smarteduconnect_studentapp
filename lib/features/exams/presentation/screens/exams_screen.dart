// lib/features/exams/presentation/screens/exams_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import 'exam_result_screen.dart';
import 'exam_schedule_screen.dart';

/// Exams Home Screen (Student / Parent)
///
/// Tabs:
/// 1) Schedule -> uses ExamScheduleScreen (GET /api/exams/student/my-schedule)
/// 2) Results  -> uses repo.getMyExamResults()
///              (published results only; not published are skipped by repo)
class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Results tab data
  late Future<List<Map<String, dynamic>>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _resultsFuture = _fetchResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchResults() async {
    final repo = ref.read(examsRepositoryProvider);
    final raw = await repo.getMyExamResults();
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  void _reloadResults() {
    setState(() => _resultsFuture = _fetchResults());
  }

  Color _alpha(Color c, double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round();
    return c.withAlpha(a);
  }

  String _prettyDate(String raw) {
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

  num _toNum(dynamic v) =>
      v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Exams',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              decoration: BoxDecoration(
                color: _alpha(scheme.surface, 0.65),
                borderRadius: BorderRadius.circular(AppSpacing.rXl),
                border: Border.all(color: _alpha(scheme.outlineVariant, 0.55)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.rXl),
                  color: _alpha(scheme.primary, 0.14),
                ),
                labelColor: scheme.primary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w800),
                tabs: const [
                  Tab(text: 'Schedule'),
                  Tab(text: 'Results'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Schedule tab is its own screen (already wired)
              const ExamScheduleScreen(),

              // Results tab (published results only)
              _ResultsTab(
                resultsFuture: _resultsFuture,
                onReload: _reloadResults,
                alpha: _alpha,
                prettyDate: _prettyDate,
                toNum: _toNum,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsTab extends StatelessWidget {
  const _ResultsTab({
    required this.resultsFuture,
    required this.onReload,
    required this.alpha,
    required this.prettyDate,
    required this.toNum,
  });

  final Future<List<Map<String, dynamic>>> resultsFuture;
  final VoidCallback onReload;
  final Color Function(Color, double) alpha;
  final String Function(String) prettyDate;
  final num Function(dynamic) toNum;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        onReload();
        await resultsFuture;
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: 'Unable to load exam results.',
              onRetry: onReload,
            );
          }

          final rows = snapshot.data ?? <Map<String, dynamic>>[];

          if (rows.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppEmptyView(
                  title: 'No Published Results',
                  subtitle:
                      'Results will appear here only after your teacher publishes them.',
                ),
              ],
            );
          }

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
                        color: alpha(scheme.primary, 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.rMd),
                        border: Border.all(color: alpha(scheme.primary, 0.25)),
                      ),
                      child:
                          Icon(Icons.assessment_rounded, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Published Results',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap any exam to see subject-wise marks.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: alpha(scheme.primary, 0.10),
                        borderRadius: BorderRadius.circular(AppSpacing.rXl),
                        border: Border.all(color: alpha(scheme.primary, 0.22)),
                      ),
                      child: Text(
                        '${rows.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final r in rows) ...[
                _ResultCard(
                  row: r,
                  alpha: alpha,
                  prettyDate: prettyDate,
                  toNum: toNum,
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.row,
    required this.alpha,
    required this.prettyDate,
    required this.toNum,
  });

  final Map<String, dynamic> row;
  final Color Function(Color, double) alpha;
  final String Function(String) prettyDate;
  final num Function(dynamic) toNum;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final examId = (row['examId'] ?? '').toString();
    final examName = (row['examName'] ?? 'Exam').toString();
    final percentage = toNum(row['percentage']);
    final grade = (row['overallGrade'] ?? row['grade'] ?? '').toString();
    final publishedAt = (row['publishedAt'] ?? '').toString();

    Color scoreColor;
    if (percentage >= 90) {
      scoreColor = scheme.primary;
    } else if (percentage >= 60) {
      scoreColor = scheme.tertiary;
    } else {
      scoreColor = scheme.error;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.rLg),
      onTap: examId.trim().isEmpty
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExamResultScreen(
                    examId: examId,
                    examName: examName,
                  ),
                ),
              );
            },
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: alpha(scoreColor, 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.rMd),
                border: Border.all(color: alpha(scoreColor, 0.25)),
              ),
              child: Center(
                child: Text(
                  '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w900,
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
                    examName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: alpha(scheme.primary, 0.10),
                          borderRadius: BorderRadius.circular(AppSpacing.rXl),
                          border:
                              Border.all(color: alpha(scheme.primary, 0.20)),
                        ),
                        child: Text(
                          grade.isEmpty ? 'Grade —' : 'Grade $grade',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: scheme.primary,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (publishedAt.trim().isNotEmpty)
                        Expanded(
                          child: Text(
                            'Published: ${prettyDate(publishedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
