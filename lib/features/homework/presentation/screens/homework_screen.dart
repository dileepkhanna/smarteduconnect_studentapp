// lib/features/homework/presentation/screens/homework_screen.dart
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
import 'homework_detail_screen.dart';

enum _HomeworkFilter { today, week, month, all }

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  _HomeworkFilter _filter = _HomeworkFilter.all;
  final TextEditingController _searchCtrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  static String _yyyyMmDd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime _startOfWeek(DateTime d) {
    // Monday as start (ISO)
    final delta = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: delta));
  }

  static DateTime _endOfWeek(DateTime d) {
    final start = _startOfWeek(d);
    return start.add(const Duration(days: 6));
  }

  static DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime _endOfMonth(DateTime d) {
    final next = (d.month == 12)
        ? DateTime(d.year + 1, 1, 1)
        : DateTime(d.year, d.month + 1, 1);
    return next.subtract(const Duration(days: 1));
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final repo = ref.read(homeworkRepositoryProvider);

    final search = _searchCtrl.text.trim();
    final now = DateTime.now();

    String? fromDate;
    String? toDate;

    switch (_filter) {
      case _HomeworkFilter.today:
        final t = _yyyyMmDd(now);
        fromDate = t;
        toDate = t;
        break;
      case _HomeworkFilter.week:
        fromDate = _yyyyMmDd(_startOfWeek(now));
        toDate = _yyyyMmDd(_endOfWeek(now));
        break;
      case _HomeworkFilter.month:
        fromDate = _yyyyMmDd(_startOfMonth(now));
        toDate = _yyyyMmDd(_endOfMonth(now));
        break;
      case _HomeworkFilter.all:
        fromDate = null;
        toDate = null;
        break;
    }

    final List<dynamic> raw = await repo.getMyHomework(
      fromDate: fromDate,
      toDate: toDate,
      search: search.isEmpty ? null : search,
      page: 1,
      limit: 100,
    );

    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  String _formatDate(BuildContext context, String? yyyyMmDd) {
    if (yyyyMmDd == null || yyyyMmDd.trim().isEmpty) return '—';
    final dt = DateTime.tryParse(yyyyMmDd.trim());
    if (dt == null) return yyyyMmDd.trim();
    return MaterialLocalizations.of(context).formatFullDate(dt);
  }

  String _classSectionLabel(Map<String, dynamic> h) {
    final c = h['classNumber'];
    final s = (h['section'] ?? '').toString().trim();
    final cls =
        (c is num) ? c.toInt().toString() : (c?.toString() ?? '').trim();
    if (cls.isEmpty) return '';
    return s.isEmpty ? 'Class $cls' : 'Class $cls$s';
  }

  List<String> _attachments(Map<String, dynamic> h) {
    final a = h['attachments'];
    if (a is List) {
      return a
          .map((e) => e.toString())
          .where((u) => u.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: active ? scheme.onPrimary : scheme.onSurface,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: 'Homework'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: Column(
            children: [
              // Filters + Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip('Today', _filter == _HomeworkFilter.today,
                                () {
                              setState(() => _filter = _HomeworkFilter.today);
                              _reload();
                            }),
                            const SizedBox(width: 8),
                            _chip('This Week', _filter == _HomeworkFilter.week,
                                () {
                              setState(() => _filter = _HomeworkFilter.week);
                              _reload();
                            }),
                            const SizedBox(width: 8),
                            _chip(
                                'This Month', _filter == _HomeworkFilter.month,
                                () {
                              setState(() => _filter = _HomeworkFilter.month);
                              _reload();
                            }),
                            const SizedBox(width: 8),
                            _chip('All', _filter == _HomeworkFilter.all, () {
                              setState(() => _filter = _HomeworkFilter.all);
                              _reload();
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _reload(),
                              decoration: InputDecoration(
                                hintText: 'Search homework (content)...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                filled: true,
                                fillColor: scheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.rLg),
                                  borderSide:
                                      BorderSide(color: scheme.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.rLg),
                                  borderSide:
                                      BorderSide(color: scheme.outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.rLg),
                                  borderSide: const BorderSide(
                                      color: AppColors.brandTeal, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
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

              // List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return AppErrorView(
                        message: 'Unable to load homework.',
                        onRetry: _reload,
                      );
                    }

                    final items = snap.data ?? const <Map<String, dynamic>>[];
                    if (items.isEmpty) {
                      return AppEmptyView(
                        title: _filter == _HomeworkFilter.today
                            ? 'No Homework Today'
                            : 'No Homework',
                        subtitle: _filter == _HomeworkFilter.today
                            ? 'No homework has been assigned today for your class.'
                            : 'No homework is available for your class in the selected filter.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final h = items[index];

                        final id = (h['id'] ?? '').toString();
                        final subject = (h['subject'] ?? '').toString().trim();
                        final date = (h['date'] ?? '').toString().trim();
                        final content = (h['content'] ?? '').toString().trim();
                        final classLabel = _classSectionLabel(h);
                        final attachments = _attachments(h);

                        return AppCard(
                          onTap: () {
                            if (id.isEmpty) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => HomeworkDetailScreen(
                                  homeworkId: id,
                                  initialData: h,
                                ),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subject.isEmpty ? 'Homework' : subject,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded,
                                      size: 16, color: AppColors.brandTeal),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _formatDate(context, date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  if (classLabel.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.brandTeal.withAlpha(28),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                            color: AppColors.brandTeal
                                                .withAlpha(60)),
                                      ),
                                      child: Text(
                                        classLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brandTeal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                content.isEmpty ? '—' : content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (attachments.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 88,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: attachments.length.clamp(0, 10),
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, i) {
                                      final url = attachments[i];
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.rLg),
                                        child: CachedImage(
                                          url: url,
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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
