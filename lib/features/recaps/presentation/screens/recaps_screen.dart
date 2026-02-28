// lib/features/recaps/presentation/screens/recaps_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/cached_image.dart';
import 'recap_detail_screen.dart';

/// Daily Recaps Screen (Student / Parent)
///
/// ✅ Uses REAL backend:
/// - GET /recaps  (role scoped; for Student returns only their class/section recaps)
///
/// Filters implemented:
/// - Today / Week (last 7 days) / Month (current month) / All
/// - Subject (text filter)
/// - Search (text filter on content)
class RecapsScreen extends ConsumerStatefulWidget {
  const RecapsScreen({super.key});

  @override
  ConsumerState<RecapsScreen> createState() => _RecapsScreenState();
}

class _RecapsScreenState extends ConsumerState<RecapsScreen> {
  int _range = 3; // 0=Today, 1=Week, 2=Month, 3=All

  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _subject = '';
  String _search = '';

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _fetch());

  Future<List<Map<String, dynamic>>> _fetch() async {
    final repo = ref.read(recapsRepositoryProvider);

    final subject = _subject.trim();
    final search = _search.trim();

    final range = _computeRange(_range);

    // Fast path for "Today" with no extra filters
    if (_range == 0 && subject.isEmpty && search.isEmpty) {
      final raw = await repo.getTodayRecaps();
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }

    final raw = await repo.getMyRecaps(
      fromDate: range.fromDate,
      toDate: range.toDate,
      subject: subject.isEmpty ? null : subject,
      search: search.isEmpty ? null : search,
    );

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  _DateRange _computeRange(int range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    if (range == 0) {
      final t = fmt(today);
      return _DateRange(fromDate: t, toDate: t);
    }

    if (range == 1) {
      // last 7 days (inclusive)
      final from = fmt(today.subtract(const Duration(days: 6)));
      final to = fmt(today);
      return _DateRange(fromDate: from, toDate: to);
    }

    if (range == 2) {
      // current month start -> today
      final from = fmt(DateTime(today.year, today.month, 1));
      final to = fmt(today);
      return _DateRange(fromDate: from, toDate: to);
    }

    // All
    return const _DateRange(fromDate: null, toDate: null);
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    setState(() {
      _subject = _subjectCtrl.text;
      _search = _searchCtrl.text;
      _future = _fetch();
    });
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    setState(() {
      _subjectCtrl.clear();
      _searchCtrl.clear();
      _subject = '';
      _search = '';
      _future = _fetch();
    });
  }

  String _classLabel(Map<String, dynamic> r) {
    final c = r['classNumber']?.toString().trim() ?? '';
    final s = r['section']?.toString().trim() ?? '';
    if (c.isEmpty && s.isEmpty) return '';
    if (c.isNotEmpty && s.isNotEmpty) return 'Class $c$s';
    if (c.isNotEmpty) return 'Class $c';
    return 'Section $s';
  }

  String _preview(String content) {
    final t = content.trim().replaceAll('\n', ' ');
    if (t.length <= 140) return t;
    return '${t.substring(0, 140)}…';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: 'Daily Recaps'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: Column(
            children: [
              // FILTERS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _RangePill(
                              label: 'Today',
                              active: _range == 0,
                              onTap: () => setState(() {
                                _range = 0;
                                _future = _fetch();
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RangePill(
                              label: 'Week',
                              active: _range == 1,
                              onTap: () => setState(() {
                                _range = 1;
                                _future = _fetch();
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RangePill(
                              label: 'Month',
                              active: _range == 2,
                              onTap: () => setState(() {
                                _range = 2;
                                _future = _fetch();
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RangePill(
                              label: 'All',
                              active: _range == 3,
                              onTap: () => setState(() {
                                _range = 3;
                                _future = _fetch();
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _applyFilters(),
                        decoration: InputDecoration(
                          labelText: 'Search in recaps',
                          hintText: 'e.g., fractions, chapter 3...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: _searchCtrl.text.trim().isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _applyFilters();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _subjectCtrl,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _applyFilters(),
                        decoration: InputDecoration(
                          labelText: 'Subject (optional)',
                          hintText: 'e.g., Mathematics',
                          prefixIcon: const Icon(Icons.menu_book_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: _subjectCtrl.text.trim().isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  onPressed: () {
                                    _subjectCtrl.clear();
                                    _applyFilters();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _applyFilters,
                              icon: const Icon(Icons.filter_alt_rounded),
                              label: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Recaps are shown only for your class & section (as per backend).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // CONTENT
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return AppErrorView(
                        message: 'Unable to load recaps.',
                        onRetry: _reload,
                      );
                    }

                    final items =
                        snapshot.data ?? const <Map<String, dynamic>>[];

                    if (items.isEmpty) {
                      final title =
                          _range == 0 ? 'No Recaps Today' : 'No Recaps Found';
                      final subtitle = _range == 0
                          ? 'No recap has been posted today.'
                          : 'Try changing the date range or clearing filters.';
                      return AppEmptyView(title: title, subtitle: subtitle);
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final r = items[index];

                          final date = r['date']?.toString() ?? '';
                          final subject = r['subject']?.toString() ?? '';
                          final content = r['content']?.toString() ?? '';
                          final classLabel = _classLabel(r);

                          final attachmentsRaw = r['attachments'];
                          final attachments = attachmentsRaw is List
                              ? attachmentsRaw.map((e) => e.toString()).toList()
                              : <String>[];

                          final thumbUrl =
                              attachments.isNotEmpty ? attachments.first : null;

                          return InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.rLg),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => RecapDetailScreen(recap: r),
                                ),
                              );
                            },
                            child: AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (thumbUrl != null &&
                                      thumbUrl.trim().isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(AppSpacing.rMd),
                                      child: SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: CachedImage(
                                          url: thumbUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ] else ...[
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.rMd),
                                        color:
                                            AppColors.brandTeal.withAlpha(18),
                                      ),
                                      child: const Icon(
                                        Icons.notes_rounded,
                                        color: AppColors.brandTeal,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                subject.isEmpty
                                                    ? 'Recap'
                                                    : subject,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              date,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        if (classLabel.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            classLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          _preview(content),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (attachments.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.attachment_rounded,
                                                  size: 16),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          );
                        },
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

class _RangePill extends StatelessWidget {
  const _RangePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.rXl),
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.rXl),
          color: active ? scheme.primary : Colors.transparent,
          border: Border.all(
            color: active ? Colors.transparent : scheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: active ? scheme.onPrimary : scheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }
}

class _DateRange {
  const _DateRange({required this.fromDate, required this.toDate});
  final String? fromDate;
  final String? toDate;
}
