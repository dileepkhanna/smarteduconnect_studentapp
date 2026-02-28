// lib/features/notifications_feed/presentation/screens/general_notifications_screen.dart
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

/// General Notifications Screen (Student / Parent)
///
/// ✅ Token-scoped notifications (backend returns only logged-in user's feed)
/// ✅ Unseen → Seen flow
/// ✅ Mark All as Read
/// ✅ Filter: All / Unread
/// ✅ Search
class GeneralNotificationsScreen extends ConsumerStatefulWidget {
  const GeneralNotificationsScreen({super.key});

  @override
  ConsumerState<GeneralNotificationsScreen> createState() =>
      _GeneralNotificationsScreenState();
}

class _GeneralNotificationsScreenState
    extends ConsumerState<GeneralNotificationsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _unreadOnly = false;

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

  Color _alpha(Color c, double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round();
    return c.withAlpha(a);
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final repo = ref.read(notificationsRepositoryProvider);
    final search = _searchCtrl.text.trim();

    final items = await repo.getMyNotifications(
      page: 1,
      limit: 100,
      isSeen: _unreadOnly ? false : null,
      search: search.isEmpty ? null : search,
    );

    return items;
  }

  void _reload() {
    setState(() => _future = _load());
  }

  String _formatCreatedAt(BuildContext context, String? createdAt) {
    if (createdAt == null || createdAt.trim().isEmpty) return '';
    final dt = DateTime.tryParse(createdAt.trim());
    if (dt == null) return createdAt.trim();

    final date = MaterialLocalizations.of(context).formatMediumDate(dt);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(dt),
      alwaysUse24HourFormat: false,
    );
    return '$date • $time';
  }

  Future<void> _openNotification(
    BuildContext context,
    Map<String, dynamic> n,
  ) async {
    final id = (n['id'] ?? '').toString();
    final title = (n['title'] ?? '').toString();
    final body = (n['body'] ?? '').toString();
    final image = (n['image'] ?? '').toString();
    final createdAt = (n['createdAt'] ?? '').toString();
    final seen = n['isSeen'] == true;

    // Mark as read before showing details (unseen -> seen)
    if (!seen && id.isNotEmpty) {
      try {
        await ref
            .read(notificationsRepositoryProvider)
            .markNotificationSeen(id);
      } catch (_) {
        // ignore (still show the dialog)
      } finally {
        _reload();
      }
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.rXl),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Notification' : title,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCreatedAt(ctx, createdAt),
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (image.trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.rLg),
                      child: CachedImage(
                        url: image,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    body.isEmpty ? '—' : body,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Close'),
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

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
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
      appBar: AppAppBar(
        title: 'Notifications',
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () async {
              try {
                await ref.read(notificationsRepositoryProvider).markAllSeen();
              } catch (_) {
                // ignore
              }
              _reload();
            },
          ),
        ],
      ),
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
                      Row(
                        children: [
                          _filterChip(
                            label: 'All',
                            active: !_unreadOnly,
                            onTap: () {
                              setState(() => _unreadOnly = false);
                              _reload();
                            },
                          ),
                          const SizedBox(width: 8),
                          _filterChip(
                            label: 'Unread',
                            active: _unreadOnly,
                            onTap: () {
                              setState(() => _unreadOnly = true);
                              _reload();
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Refresh',
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _reload(),
                        decoration: InputDecoration(
                          hintText: 'Search notifications...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: scheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.rLg),
                            borderSide:
                                BorderSide(color: scheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.rLg),
                            borderSide:
                                BorderSide(color: scheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.rLg),
                            borderSide: const BorderSide(
                              color: AppColors.brandTeal,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return AppErrorView(
                          message: 'Unable to load notifications.',
                          onRetry: _reload,
                        );
                      }

                      final items =
                          snapshot.data ?? const <Map<String, dynamic>>[];
                      if (items.isEmpty) {
                        return AppEmptyView(
                          title: _unreadOnly
                              ? 'No Unread Notifications'
                              : 'No Notifications',
                          subtitle: _unreadOnly
                              ? 'You have read all notifications.'
                              : 'You have no notifications at the moment.',
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = items[index];

                          final title = (n['title'] ?? '').toString();
                          final body = (n['body'] ?? '').toString();
                          final image = (n['image'] ?? '').toString();
                          final seen = n['isSeen'] == true;
                          final createdAt = (n['createdAt'] ?? '').toString();

                          return InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.rLg),
                            onTap: () => _openNotification(context, n),
                            child: AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image or icon
                                  if (image.trim().isNotEmpty)
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(AppSpacing.rLg),
                                      child: CachedImage(
                                        url: image,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: seen
                                            ? _alpha(
                                                scheme.onSurfaceVariant, 0.10)
                                            : _alpha(AppColors.brandTeal, 0.15),
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.rLg),
                                        border: Border.all(
                                          color: seen
                                              ? _alpha(
                                                  scheme.onSurfaceVariant, 0.18)
                                              : _alpha(
                                                  AppColors.brandTeal, 0.35),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.notifications_rounded,
                                        color: seen
                                            ? scheme.onSurfaceVariant
                                            : AppColors.brandTeal,
                                      ),
                                    ),

                                  const SizedBox(width: 12),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title.isEmpty
                                                    ? 'Notification'
                                                    : title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight: seen
                                                          ? FontWeight.w800
                                                          : FontWeight.w900,
                                                    ),
                                              ),
                                            ),
                                            if (!seen) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _alpha(
                                                      AppColors.brandOrange,
                                                      0.14),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                  border: Border.all(
                                                    color: _alpha(
                                                        AppColors.brandOrange,
                                                        0.28),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'NEW',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.brandOrange,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          body.isEmpty ? '—' : body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                height: 1.3,
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatCreatedAt(context, createdAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
