// lib/features/circulars/presentation/screens/circular_list_screen.dart
import 'dart:async';

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
import 'circular_detail_screen.dart';

/// Circular List Screen (Student / Parent)
///
/// ✅ Backend (authoritative):
/// - GET /api/circulars?type=TYPE  (paginated, but repo returns items list for now)
/// - POST /api/circulars/mark-seen  { type }  (called when opening this screen)
///
/// ✅ Prompt rules:
/// - View-only
/// - Category-wise list (EXAM/EVENT/PTM/HOLIDAY/TRANSPORT/GENERAL)
/// - Opening a category marks that category as seen (badge disappears; do not show 0)
class CircularListScreen extends ConsumerStatefulWidget {
  const CircularListScreen({
    super.key,
    required this.type,
    required this.title,
  });

  final String type; // EXAM / EVENT / PTM / HOLIDAY / TRANSPORT / GENERAL
  final String title;

  @override
  ConsumerState<CircularListScreen> createState() => _CircularListScreenState();
}

class _CircularListScreenState extends ConsumerState<CircularListScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _page = 1;
  static const int _limit = 20;

  String _search = '';

  List<Map<String, dynamic>> _items = [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text.trim();
      if (next == _search) return;
      _search = next;
      _debouncedReload();
    });

    _scroll.addListener(() {
      if (!_hasMore || _loadingMore || _initialLoading) return;
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });

    _initLoad();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    // Mark this type as seen (prompt rule + backend unseen logic)
    // Don't block list rendering for this side-effect.
    unawaited(Future<void>(() async {
      try {
        await ref.read(circularsRepositoryProvider).markTypeAsSeen(widget.type);
      } catch (_) {}
    }));

    setState(() {
      _initialLoading = true;
      _error = null;
      _items = [];
      _page = 1;
      _hasMore = true;
    });

    await _fetchPage(reset: true);
  }

  Future<void> _fetchPage({required bool reset}) async {
    try {
      final repo = ref.read(circularsRepositoryProvider);

      final list = await repo.getCircularsByType(
        widget.type,
        search: _search.isEmpty ? null : _search,
        page: _page,
        limit: _limit,
      );

      final normalized = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        if (reset) {
          _items = normalized;
        } else {
          _items.addAll(normalized);
        }
        _hasMore = normalized.length >= _limit;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() {
        _initialLoading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _reload() async {
    setState(() {
      _page = 1;
      _hasMore = true;
      _error = null;
      _initialLoading = true;
      _items = [];
    });
    await _fetchPage(reset: true);
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _page += 1;
    });
    await _fetchPage(reset: false);
  }

  // Simple debounce without timers package (keeps file self-contained)
  int _debounceTick = 0;
  void _debouncedReload() {
    _debounceTick++;
    final tick = _debounceTick;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (tick != _debounceTick) return;
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: widget.title),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: scheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search circulars...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchCtrl.clear();
                            FocusScope.of(context).unfocus();
                          },
                          icon: Icon(Icons.close_rounded,
                              color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: _buildBody(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return AppErrorView(
        message: 'Unable to load circulars.',
        onRetry: _reload,
      );
    }

    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppEmptyView(
            title: 'No Circulars',
            subtitle: 'No circulars found for the selected category.',
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _items.length + 1,
      itemBuilder: (context, index) {
        if (index == _items.length) {
          if (!_loadingMore) return const SizedBox(height: 8);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: CircularProgressIndicator(color: scheme.primary),
            ),
          );
        }

        final item = _items[index];

        final id = (item['id'] ?? '').toString();
        final title = (item['title'] ?? 'Circular').toString();
        final description = (item['description'] ?? '').toString();
        final publishDate =
            (item['publishDate'] ?? item['createdAt'] ?? '').toString();

        final images = (item['images'] is List)
            ? List<dynamic>.from(item['images'] as List)
            : const <dynamic>[];
        final thumb = images.isNotEmpty ? (images.first?.toString() ?? '') : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.rLg),
            onTap: () async {
              if (id.isEmpty) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CircularDetailScreen(circularId: id),
                ),
              );
              if (!mounted) return;
              await _reload();
            },
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thumb.trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.rMd),
                      child: CachedImage(
                        url: thumb,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSpacing.rMd),
                        border: Border.all(
                            color: scheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Icon(Icons.article_rounded,
                          color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        if (description.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                        if (publishDate.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.calendar_month_rounded,
                                  size: 16, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _prettyDate(publishDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _prettyDate(String raw) {
    // raw can be ISO; keep safe and readable without intl dependency.
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
    final m = months[dt.month - 1];
    return '$m ${dt.day}, ${dt.year}';
  }
}
