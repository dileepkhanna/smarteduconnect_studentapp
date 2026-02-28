// lib/features/circulars/presentation/screens/circular_types_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_card.dart';
import '../widgets/unseen_badge_chip.dart';
import 'circular_list_screen.dart';

/// Circular Types Screen (Student / Parent)
///
/// ✅ Backend (authoritative):
/// - GET /api/circulars/unseen/all -> { "EXAM": 2, "EVENT": 0, ... }
///
/// ✅ Prompt rules:
/// - Badge per type
/// - Opening a category marks all of that type as seen (badge clears; do not show 0)
class CircularTypesScreen extends ConsumerStatefulWidget {
  const CircularTypesScreen({super.key});

  @override
  ConsumerState<CircularTypesScreen> createState() =>
      _CircularTypesScreenState();
}

class _CircularTypesScreenState extends ConsumerState<CircularTypesScreen> {
  late Future<Map<String, dynamic>> _future;

  final List<_CircularType> _types = const [
    _CircularType(
        'EXAM', 'Exam Circulars', Icons.assignment_rounded, Colors.indigo),
    _CircularType(
        'EVENT', 'Event Circulars', Icons.celebration_rounded, Colors.purple),
    _CircularType('PTM', 'PTM Circulars', Icons.groups_rounded, Colors.teal),
    _CircularType('HOLIDAY', 'Holiday Circulars', Icons.beach_access_rounded,
        Colors.orange),
    _CircularType('TRANSPORT', 'Transport Circulars',
        Icons.directions_bus_rounded, Colors.blue),
    _CircularType('GENERAL', 'General Circulars', Icons.campaign_rounded,
        Colors.redAccent),
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadUnseen();
  }

  Future<Map<String, dynamic>> _loadUnseen() {
    return ref.read(circularsRepositoryProvider).getUnseenCounts();
  }

  void _reload() {
    setState(() => _future = _loadUnseen());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Circulars'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
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
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unable to load circular categories',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your connection and try again.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: _reload,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                final unseen = snapshot.data ?? <String, dynamic>{};

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.rMd),
                              border: Border.all(
                                  color: scheme.primary.withOpacity(0.25)),
                            ),
                            child: Icon(Icons.notifications_rounded,
                                color: scheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose a category to view circulars.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final t in _types) ...[
                      _TypeTile(
                        type: t,
                        unseenCount: _toInt(unseen[t.key]),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CircularListScreen(
                                type: t.key,
                                title: t.title,
                              ),
                            ),
                          );
                          // When returning, refresh unseen counts (because list screen marks seen)
                          _reload();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Badges clear automatically when you open a category.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
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

  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.unseenCount,
    required this.onTap,
  });

  final _CircularType type;
  final int unseenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.rLg),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: type.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.rMd),
                border: Border.all(color: type.color.withOpacity(0.25)),
              ),
              child: Icon(type.icon, color: type.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            UnseenBadgeChip(count: unseenCount),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _CircularType {
  final String key;
  final String title;
  final IconData icon;
  final Color color;

  const _CircularType(this.key, this.title, this.icon, this.color);
}
