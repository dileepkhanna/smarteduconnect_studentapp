// lib/features/cms_pages/presentation/screens/faq_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';

/// FAQ Screen (Drawer -> FAQ)
///
/// ✅ Backend (authoritative):
/// GET /api/cms/static?key=FAQ
///
/// Response:
/// { key, title, content, updatedAt }
class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    return ref.read(cmsRepositoryProvider).getStaticPageByKey('FAQ');
  }

  void _reload() {
    setState(() => _future = _fetch());
  }

  // ✅ Replacement for deprecated withOpacity
  Color _alpha(Color c, double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round();
    return c.withAlpha(a);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // ❌ DO NOT use const here (your AppAppBar is not const)
      appBar: AppAppBar(title: 'FAQ'),
      body: Container(
        // ❌ keep non-const if AppColors.brandGradientSoft is not const in your project
        decoration: BoxDecoration(gradient: AppColors.brandGradientSoft),
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // ❌ remove const (AppErrorView likely not const)
                  return AppErrorView(
                    message: 'Unable to load FAQ.',
                    onRetry: _reload,
                  );
                }

                final data = snapshot.data ?? <String, dynamic>{};
                if (data.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ❌ remove const (AppEmptyView likely not const)
                      AppEmptyView(
                        title: 'No FAQ Available',
                        subtitle: 'FAQ content is not available right now.',
                      ),
                    ],
                  );
                }

                final title = (data['title'] ?? 'FAQ').toString();
                final updatedAtRaw = (data['updatedAt'] ?? '').toString();
                final contentRaw = (data['content'] ?? '').toString();
                final content = _normalizeContent(contentRaw);

                final blocks = _parseFaqBlocks(content);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    // ❌ remove const (AppCard likely not const)
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _alpha(scheme.primary, 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.rMd),
                              border: Border.all(color: _alpha(scheme.primary, 0.25)),
                            ),
                            child: Icon(Icons.quiz_rounded, color: scheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                if (updatedAtRaw.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Updated: ${_prettyDate(updatedAtRaw)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (blocks.isEmpty) ...[
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: content.trim().isEmpty
                            ? Text(
                                'No FAQ details available.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              )
                            : SelectableText(
                                content,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                    ] else ...[
                      for (final b in blocks) ...[
                        _FaqTile(question: b.question, answer: b.answer),
                        const SizedBox(height: 10),
                      ],
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _normalizeContent(String input) {
    var out = input.trim();
    if (out.isEmpty) return out;

    // If HTML is stored, show readable text without dependencies.
    if (out.contains('<') && out.contains('>')) {
      out = out.replaceAll(RegExp(r'<[^>]*>'), ' ');
      out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    // Decode common HTML entities.
    out = out
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return out;
  }

  List<_FaqBlock> _parseFaqBlocks(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return <_FaqBlock>[];

    final blocks = <_FaqBlock>[];
    String? currentQ;
    final currentA = <String>[];

    void flush() {
      if (currentQ != null) {
        blocks.add(_FaqBlock(
          question: currentQ!.trim(),
          answer: currentA.join('\n').trim(),
        ));
      }
      currentQ = null;
      currentA.clear();
    }

    for (final line in lines) {
      final lower = line.toLowerCase();
      final isQ = lower.startsWith('q:') || lower.startsWith('q.');
      final isA = lower.startsWith('a:') || lower.startsWith('a.');

      if (isQ) {
        flush();
        currentQ = line.substring(2).trim();
        continue;
      }

      if (isA) {
        currentA.add(line.substring(2).trim());
        continue;
      }

      if (currentQ != null) currentA.add(line);
    }

    flush();

    // If parsing is useless, return empty to show plain content.
    final usable = blocks.where((b) => b.question.isNotEmpty).toList();
    if (usable.isEmpty) return <_FaqBlock>[];
    return usable;
  }
}

class _FaqBlock {
  _FaqBlock({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.rLg),
            onTap: () => setState(() => _open = !_open),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: SizedBox.shrink(),
            ),
          ),
          // We rebuild header row here to keep const-safe pieces separate
          Builder(
            builder: (context) {
              return InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.rLg),
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.question.trim().isEmpty ? 'Question' : widget.question,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 180),
                        turns: _open ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                widget.answer.trim().isEmpty ? '—' : widget.answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
              ),
            ),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}
