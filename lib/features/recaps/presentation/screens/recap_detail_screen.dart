// lib/features/recaps/presentation/screens/recap_detail_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/cached_image.dart';

/// Recap Detail Screen (Student / Parent)
///
/// ✅ Read-only
/// ✅ Uses Recap object from list (already scoped by backend)
/// ✅ Supports attachments[] (R2 URLs)
class RecapDetailScreen extends StatelessWidget {
  const RecapDetailScreen({
    super.key,
    required this.recap,
  });

  final Map<String, dynamic> recap;

  String _classLabel() {
    final c = recap['classNumber']?.toString().trim() ?? '';
    final s = recap['section']?.toString().trim() ?? '';
    if (c.isEmpty && s.isEmpty) return '';
    if (c.isNotEmpty && s.isNotEmpty) return 'Class $c$s';
    if (c.isNotEmpty) return 'Class $c';
    return 'Section $s';
  }

  List<String> _attachments() {
    final raw = recap['attachments'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return <String>[];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final date = recap['date']?.toString() ?? '';
    final subject = recap['subject']?.toString() ?? '';
    final content = recap['content']?.toString() ?? '';
    final classLabel = _classLabel();
    final attachments = _attachments();

    return Scaffold(
      appBar: AppAppBar(title: 'Recap Details'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      subject.isEmpty ? 'Daily Recap' : subject,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.calendar_month_rounded,
                          text: date.isEmpty ? '—' : date,
                        ),
                        if (classLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _MetaChip(
                            icon: Icons.school_rounded,
                            text: classLabel,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              AppCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  content.trim().isEmpty ? '—' : content.trim(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Attachments',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: attachments.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, i) {
                          final url = attachments[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.rLg),
                            onTap: () => _openImage(context, url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppSpacing.rLg),
                              child: Container(
                                color: scheme.surfaceContainerHighest,
                                child: CachedImage(
                                  url: url,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap an image to view.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),
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
        ),
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rLg),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.rLg),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: CachedImage(url: url, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
