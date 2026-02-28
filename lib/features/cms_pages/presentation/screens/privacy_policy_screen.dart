// lib/features/cms_pages/presentation/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';

/// Privacy Policy Screen (Drawer -> Privacy Policy)
///
/// ✅ Backend (authoritative):
/// GET /api/cms/static?key=PRIVACY_POLICY
///
/// Response:
/// { key, title, content, updatedAt }
class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    return ref.read(cmsRepositoryProvider).getStaticPageByKey('PRIVACY_POLICY');
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
      // ❌ DO NOT use const (your AppAppBar is not const)
      appBar: AppAppBar(title: 'Privacy Policy'),
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
                    message: 'Unable to load Privacy Policy.',
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
                        title: 'No Content Available',
                        subtitle: 'Privacy Policy is not available right now.',
                      ),
                    ],
                  );
                }

                final title = (data['title'] ?? 'Privacy Policy').toString();
                final updatedAtRaw = (data['updatedAt'] ?? '').toString();
                final contentRaw = (data['content'] ?? '').toString();
                final content = _normalizeContent(contentRaw);

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
                            child: Icon(Icons.privacy_tip_rounded, color: scheme.primary),
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
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: content.trim().isEmpty
                          ? Text(
                              'No details available.',
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _normalizeContent(String input) {
    var out = input.trim();
    if (out.isEmpty) return out;

    // Strip HTML tags if any.
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
}
