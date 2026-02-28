// lib/features/homework/presentation/screens/homework_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/cached_image.dart';

class HomeworkDetailScreen extends ConsumerStatefulWidget {
  const HomeworkDetailScreen({
    super.key,
    required this.homeworkId,
    this.initialData,
  });

  final String homeworkId;
  final Map<String, dynamic>? initialData;

  @override
  ConsumerState<HomeworkDetailScreen> createState() => _HomeworkDetailScreenState();
}

class _HomeworkDetailScreenState extends ConsumerState<HomeworkDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final repo = ref.read(homeworkRepositoryProvider);
    return repo.getHomeworkDetail(widget.homeworkId);
  }

  void _reload() {
    setState(() => _future = _load());
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
    final cls = (c is num) ? c.toInt().toString() : (c?.toString() ?? '').trim();
    if (cls.isEmpty) return '';
    return s.isEmpty ? 'Class $cls' : 'Class $cls$s';
  }

  List<String> _attachments(Map<String, dynamic> h) {
    final a = h['attachments'];
    if (a is List) {
      return a.map((e) => e.toString()).where((u) => u.trim().isNotEmpty).toList(growable: false);
    }
    return const <String>[];
  }

  Future<void> _showImage(BuildContext context, String url) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.rXl)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.rXl),
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(
                        child: CachedImage(
                          url: url,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: 'Homework Details'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            initialData: widget.initialData,
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return AppErrorView(
                  message: 'Unable to load homework details.',
                  onRetry: _reload,
                );
              }

              final h = (snap.data ?? const <String, dynamic>{}).cast<String, dynamic>();
              if (h.isEmpty) {
                return AppErrorView(
                  message: 'Homework not found.',
                  onRetry: _reload,
                );
              }

              final subject = (h['subject'] ?? '').toString().trim();
              final date = (h['date'] ?? '').toString().trim();
              final content = (h['content'] ?? '').toString().trim();
              final classLabel = _classSectionLabel(h);
              final attachments = _attachments(h);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.isEmpty ? 'Homework' : subject,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.brandTeal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatDate(context, date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            if (classLabel.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.brandTeal.withAlpha(28),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.brandTeal.withAlpha(60)),
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
                        const SizedBox(height: 14),
                        Text(
                          'Details',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content.isEmpty ? '—' : content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachments',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: attachments.take(10).map((url) {
                              return InkWell(
                                onTap: () => _showImage(context, url),
                                borderRadius: BorderRadius.circular(AppSpacing.rLg),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppSpacing.rLg),
                                  child: CachedImage(
                                    url: url,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
