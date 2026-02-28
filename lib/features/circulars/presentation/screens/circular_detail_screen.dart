// lib/features/circulars/presentation/screens/circular_detail_screen.dart
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

/// Circular Detail Screen (Student / Parent)
///
/// ✅ Backend (authoritative):
/// - GET /api/circulars/:id
///
/// ✅ Prompt rules:
/// - View-only
/// - Show full title, full description, publish date
/// - Show all images (zoomable)
class CircularDetailScreen extends ConsumerStatefulWidget {
  const CircularDetailScreen({
    super.key,
    required this.circularId,
  });

  final String circularId;

  @override
  ConsumerState<CircularDetailScreen> createState() =>
      _CircularDetailScreenState();
}

class _CircularDetailScreenState extends ConsumerState<CircularDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final repo = ref.read(circularsRepositoryProvider);
    return repo.getCircularDetail(widget.circularId);
  }

  void _reload() {
    setState(() => _future = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Circular',
        actions: const [],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Your global Lottie overlay can be handled via ApiClient interceptors.
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  message: 'Unable to load circular details.',
                  onRetry: _reload,
                );
              }

              final data = snapshot.data ?? <String, dynamic>{};
              if (data.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: AppEmptyView(
                    title: 'Not Found',
                    subtitle: 'This circular is not available.',
                  ),
                );
              }

              final title = (data['title'] ?? 'Circular').toString();
              final description = (data['description'] ?? '').toString();
              final publishDate =
                  (data['publishDate'] ?? data['createdAt'] ?? '').toString();
              final type = (data['type'] ?? '').toString();

              final images = (data['images'] is List)
                  ? List<dynamic>.from(data['images'] as List)
                  : const <dynamic>[];
              final imageUrls = images
                  .map((e) => e?.toString() ?? '')
                  .where((e) => e.trim().isNotEmpty)
                  .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _future;
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    if (imageUrls.isNotEmpty) ...[
                      _ImageCarousel(
                        urls: imageUrls,
                        onOpen: (index) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _FullScreenGallery(
                                urls: imageUrls,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (type.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                    color:
                                        scheme.outlineVariant.withOpacity(0.4)),
                              ),
                              child: Text(
                                type.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: scheme.onSecondaryContainer,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          if (publishDate.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.calendar_month_rounded,
                                    size: 16, color: scheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  _prettyDate(publishDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ],
                          if (description.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Divider(
                                color: scheme.outlineVariant.withOpacity(0.6)),
                            const SizedBox(height: 14),
                            Text(
                              description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            Text(
                              'No description provided.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Attachments',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      _AttachmentGrid(urls: imageUrls),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({
    required this.urls,
    required this.onOpen,
  });

  final List<String> urls;
  final ValueChanged<int> onOpen;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = widget.urls[i];
                return InkWell(
                  onTap: () => widget.onOpen(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.rLg),
                    child: CachedImage(
                      url: url,
                      width: double.infinity,
                      height: 210,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.urls.length > 1) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.urls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i == _index ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AttachmentGrid extends StatelessWidget {
  const _AttachmentGrid({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.builder(
      itemCount: urls.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final url = urls[i];
        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _FullScreenGallery(urls: urls, initialIndex: i),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.rMd),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceVariant,
                border:
                    Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
              ),
              child: CachedImage(
                url: url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1}/${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final url = widget.urls[i];
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: CachedImage(
                url: url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: [
              Icon(Icons.swipe_rounded,
                  color: Colors.white.withOpacity(0.8), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pinch to zoom • Swipe to navigate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
