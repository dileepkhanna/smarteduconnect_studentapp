// lib/features/birthdays/presentation/screens/birthdays_today_screen.dart
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

/// Birthdays Today Screen (Student / Parent)
///
/// ✅ Prompt rule:
/// - Student/Parent sees ONLY same-class birthdays
/// - ONLY on the birthday day (T-0)
///
/// ✅ Backend (authoritative):
/// - GET /api/birthdays/students/today
class BirthdaysTodayScreen extends ConsumerStatefulWidget {
  const BirthdaysTodayScreen({super.key});

  @override
  ConsumerState<BirthdaysTodayScreen> createState() =>
      _BirthdaysTodayScreenState();
}

class _BirthdaysTodayScreenState extends ConsumerState<BirthdaysTodayScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<dynamic>> _fetch() {
    final repo = ref.read(birthdaysRepositoryProvider);
    return repo.getTodayClassmateBirthdays();
  }

  void _reload() {
    setState(() => _future = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Birthdays'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Your global Lottie overlay can be handled via ApiClient interceptors.
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return AppErrorView(
                    message: 'Unable to load birthdays.',
                    onRetry: _reload,
                  );
                }

                final list = (snapshot.data ?? <dynamic>[])
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();

                if (list.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      AppEmptyView(
                        title: 'No Birthdays Today',
                        subtitle: 'No classmates have a birthday today.',
                      ),
                    ],
                  );
                }

                final today = DateTime.now();
                final dateText = _formatDate(today);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.rMd),
                              border: Border.all(
                                  color: scheme.primary.withOpacity(0.25)),
                            ),
                            child:
                                Icon(Icons.cake_rounded, color: scheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Birthdays",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateText,
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
                              '${list.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: scheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final b in list) ...[
                      _BirthdayCard(data: b),
                      const SizedBox(height: 12),
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
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final name = _pickString(data, ['fullName', 'name']) ?? 'Student';
    final photo = _pickString(
        data, ['profilePhoto', 'profilePhotoUrl', 'photoUrl', 'photo']);
    final classNum = _pickString(data, ['classNumber', 'class', 'className']);
    final section = _pickString(data, ['section', 'sec']);
    final classText = _classSectionText(classNum, section);

    final quote = _pickQuote(name);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROFILE PHOTO
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.rXl),
            child: (photo != null && photo.trim().isNotEmpty)
                ? CachedImage(
                    url: photo,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 52,
                    height: 52,
                    color: scheme.surfaceVariant,
                    child: Icon(Icons.person_rounded,
                        color: scheme.onSurfaceVariant, size: 28),
                  ),
          ),
          const SizedBox(width: 14),

          // NAME + DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (classText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    classText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.rLg),
                    border: Border.all(color: scheme.primary.withOpacity(0.20)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎉  '),
                      Expanded(
                        child: Text(
                          quote,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Text(
              'Today',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onTertiaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _pickString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static String? _classSectionText(String? classNum, String? section) {
    final c = classNum?.trim();
    final s = section?.trim();
    if ((c == null || c.isEmpty) && (s == null || s.isEmpty)) return null;
    if (c != null && c.isNotEmpty && s != null && s.isNotEmpty)
      return 'Class $c • Section $s';
    if (c != null && c.isNotEmpty) return 'Class $c';
    return 'Section $s';
  }

  static String _pickQuote(String name) {
    // Short, safe, school-friendly quotes
    final quotes = <String>[
      'Happy Birthday, $name! Have an amazing day!',
      'Wishing you lots of smiles today, $name!',
      'Have a wonderful birthday, $name! 🎂',
      'Enjoy your special day, $name! 🎉',
      'Many happy returns, $name!',
    ];
    final idx = DateTime.now().millisecond % quotes.length;
    return quotes[idx];
  }
}

String _formatDate(DateTime dt) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final m = months[dt.month - 1];
  return '$m ${dt.day}, ${dt.year}';
}
