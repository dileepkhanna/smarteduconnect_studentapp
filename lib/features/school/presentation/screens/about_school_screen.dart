// lib/features/school/presentation/screens/about_school_screen.dart
import 'dart:convert';

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

/// About School (Drawer)
///
/// ✅ REAL BACKEND:
/// - GET /schools/me  (name, logoUrl, schoolCode, geofence, grade scale, etc)
/// - GET /cms/school?key=ABOUT_SCHOOL  (title/content/updatedAt)
class AboutSchoolScreen extends ConsumerStatefulWidget {
  const AboutSchoolScreen({super.key});

  @override
  ConsumerState<AboutSchoolScreen> createState() => _AboutSchoolScreenState();
}

class _AboutSchoolScreenState extends ConsumerState<AboutSchoolScreen> {
  late Future<_AboutSchoolVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AboutSchoolVm> _load() async {
    final repo = ref.read(schoolRepositoryProvider);

    final school = await repo.getMySchool();
    final about = await repo.getSchoolAbout();

    return _AboutSchoolVm(school: school, about: about);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: 'About School'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: FutureBuilder<_AboutSchoolVm>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return AppErrorView(
                  message: 'Unable to load school information.',
                  onRetry: _reload,
                );
              }

              final vm = snap.data;
              if (vm == null) {
                return AppEmptyView(
                  title: 'No information available',
                  subtitle: 'School details are not configured yet.',
                );
              }

              final school = vm.school;
              final about = vm.about;

              final schoolName = (school['name'] ?? '').toString().trim();
              final schoolCode = (school['schoolCode'] ?? '').toString().trim();
              final logoUrl = (school['logoUrl'] ?? '').toString().trim();

              final aboutTitle = (about['title'] ?? '').toString().trim();
              final aboutContentRaw = (about['content'] ?? '').toString();
              final aboutUpdatedAt = (about['updatedAt'] ?? '').toString().trim();

              final aboutContent = _normalizeContent(aboutContentRaw).trim();

              if (schoolName.isEmpty && aboutContent.isEmpty && aboutTitle.isEmpty) {
                return AppEmptyView(
                  title: 'No information available',
                  subtitle: 'School details are not configured yet.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    // Header Card: logo + name + code
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _Logo(logoUrl: logoUrl, fallbackText: schoolName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schoolName.isEmpty ? 'School' : schoolName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                if (schoolCode.isNotEmpty)
                                  _MetaChip(
                                    icon: Icons.confirmation_number_rounded,
                                    text: 'School Code: $schoolCode',
                                  ),
                                if (aboutUpdatedAt.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Updated: $aboutUpdatedAt',
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

                    // About content card
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aboutTitle.isEmpty ? 'About School' : aboutTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            aboutContent.isEmpty ? '—' : aboutContent,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      '© ${DateTime.now().year} ASE Technologies',
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
      ),
    );
  }

  /// CMS content may be plain text / markdown / html.
  /// We keep dependency-free rendering:
  /// - If JSON string, try decode {content:"..."} (defensive)
  /// - If HTML-like, strip tags
  String _normalizeContent(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';

    // Defensive: some backends may store JSON string
    if ((s.startsWith('{') && s.endsWith('}')) || (s.startsWith('[') && s.endsWith(']'))) {
      try {
        final decoded = json.decode(s);
        if (decoded is Map && decoded['content'] != null) {
          return decoded['content'].toString();
        }
      } catch (_) {
        // ignore
      }
    }

    // If likely HTML, strip tags (simple safe approach)
    if (s.contains('<') && s.contains('>')) {
      final noTags = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
      return noTags.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return s;
  }
}

class _AboutSchoolVm {
  _AboutSchoolVm({required this.school, required this.about});
  final Map<String, dynamic> school;
  final Map<String, dynamic> about;
}

class _Logo extends StatelessWidget {
  const _Logo({
    required this.logoUrl,
    required this.fallbackText,
  });

  final String logoUrl;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final hasUrl = logoUrl.trim().isNotEmpty;

    if (hasUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        child: SizedBox(
          width: 64,
          height: 64,
          child: CachedImage(url: logoUrl, fit: BoxFit.cover),
        ),
      );
    }

    final initials = _initials(fallbackText);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        color: AppColors.brandTeal.withValues(alpha: 0.12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'S' : initials,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.brandTeal,
              ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.rXl),
        border: Border.all(color: scheme.outlineVariant),
        color: scheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.brandTeal),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
