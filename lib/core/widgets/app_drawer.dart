// lib/core/widgets/app_drawer.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_providers.dart';
import '../../app/app_routes.dart';
import '../config/endpoints.dart';
import '../review/app_review.dart';
import 'cached_image.dart';
import 'logout_confirm_dialog.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  late Future<_StudentHeader> _headerFuture;

  @override
  void initState() {
    super.initState();
    _headerFuture = _loadHeader();
  }

  Future<_StudentHeader> _loadHeader() async {
    final session = ref.read(sessionManagerProvider);
    final api = ref.read(apiClientProvider);

    try {
      final res = await api.get<dynamic>(Endpoints.userMe);
      final raw = res.data;

      Map<String, dynamic> root = <String, dynamic>{};
      if (raw is Map) root = Map<String, dynamic>.from(raw);

      // backend usually returns { success, data: {...} }
      final data = (root['data'] is Map)
          ? Map<String, dynamic>.from(root['data'])
          : root;

      // try nested blocks too
      final student = (data['student'] is Map)
          ? Map<String, dynamic>.from(data['student'])
          : <String, dynamic>{};
      final profile = (data['profile'] is Map)
          ? Map<String, dynamic>.from(data['profile'])
          : <String, dynamic>{};

      String pickString(List<Map<String, dynamic>> maps, List<String> keys,
          {String fallback = ''}) {
        for (final m in maps) {
          for (final k in keys) {
            final v = m[k];
            if (v is String && v.trim().isNotEmpty) return v.trim();
          }
        }
        return fallback;
      }

      int? pickInt(List<Map<String, dynamic>> maps, List<String> keys) {
        for (final m in maps) {
          for (final k in keys) {
            final v = m[k];
            if (v is int) return v;
            if (v is num) return v.toInt();
            final n = int.tryParse(v?.toString() ?? '');
            if (n != null) return n;
          }
        }
        return null;
      }

      final name = pickString(
        [student, profile, data],
        ['name', 'fullName', 'displayName', 'studentName', 'userName'],
        fallback: session.userName ?? 'Student',
      );

      final classNumber = pickInt([student, profile, data],
          ['classNumber', 'class', 'standard', 'grade']);
      final section = pickString([student, profile, data], ['section', 'sec'],
          fallback: '');
      final roll = pickString(
          [student, profile, data], ['rollNumber', 'rollNo', 'roll'],
          fallback: '');

      final photoUrl = pickString(
        [student, profile, data],
        ['photoUrl', 'avatarUrl', 'imageUrl', 'photo'],
        fallback: '',
      );

      final classLabel = [
        if (classNumber != null) 'Class $classNumber',
        if (section.isNotEmpty) section,
      ].join(' • ').trim();

      final rollLabel = roll.isNotEmpty ? 'Roll $roll' : '';

      return _StudentHeader(
        name: name,
        subtitle: [
          if (classLabel.isNotEmpty) classLabel,
          if (rollLabel.isNotEmpty) rollLabel,
          if ((session.schoolCode ?? '').trim().isNotEmpty)
            'School ${session.schoolCode}',
        ].join(' • ').trim(),
        photoUrl: photoUrl.isEmpty ? null : photoUrl,
      );
    } catch (_) {
      return _StudentHeader(
        name: session.userName ?? 'Student',
        subtitle: (session.schoolCode ?? '').trim().isEmpty
            ? 'Student'
            : 'Student • ${session.schoolCode}',
        photoUrl: null,
      );
    }
  }

  Future<void> _go(String route, {bool replace = false}) async {
    Navigator.of(context).pop(); // close drawer
    await withGlobalLoader(ref, () async {
      if (!mounted) return;
      if (replace) {
        context.go(route);
      } else {
        // Do not await push; awaiting completes only when popped and keeps
        // global loader stuck on top of the new page.
        unawaited(context.push(route));
      }
      // Keep loader visible just for transition; auto-hide immediately after.
      await Future<void>.delayed(const Duration(milliseconds: 220));
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionManagerProvider);
    final pkgAsync = ref.watch(packageInfoProvider);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final drawerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primaryContainer.withValues(alpha: 0.40),
        scheme.surfaceContainer.withValues(alpha: 0.96),
        scheme.surface,
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(gradient: drawerGradient),
        child: SafeArea(
          child: Column(
            children: [
              FutureBuilder<_StudentHeader>(
                future: _headerFuture,
                builder: (context, snap) {
                  final h = snap.data ??
                      _StudentHeader(
                        name: session.userName ?? 'Student',
                        subtitle: (session.schoolCode ?? '').trim().isEmpty
                            ? 'Student'
                            : 'Student • ${session.schoolCode}',
                        photoUrl: null,
                      );

                  return _Header(
                    name: h.name,
                    subtitle: h.subtitle,
                    photoUrl: h.photoUrl,
                    onTap: () => _go(AppRoutes.profile),
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  children: [
                    _SectionLabel('Quick Links'),
                    _DrawerTile(
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      subtitle: 'Home',
                      onTap: () => _go(AppRoutes.home, replace: true),
                    ),
                    _DrawerTile(
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      subtitle: 'Account details',
                      onTap: () => _go(AppRoutes.profile),
                    ),
                    _DrawerTile(
                      icon: Icons.school_outlined,
                      title: 'About School',
                      subtitle: 'School details',
                      onTap: () => _go(AppRoutes.aboutSchool),
                    ),

                    const _SectionDivider(),

                    _SectionLabel('Parent Modules'),
                    _DrawerTile(
                      icon: Icons.table_chart_outlined,
                      title: 'Time Table',
                      subtitle: 'Class schedule',
                      onTap: () => _go(AppRoutes.timetable),
                    ),
                    _DrawerTile(
                      icon: Icons.event_available_outlined,
                      title: 'Attendance',
                      subtitle: 'Calendar and percentage',
                      onTap: () => _go(AppRoutes.attendance),
                    ),
                    _DrawerTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Daily Recap',
                      subtitle: 'Class updates',
                      onTap: () => _go(AppRoutes.recaps),
                    ),
                    _DrawerTile(
                      icon: Icons.assignment_outlined,
                      title: 'Homework',
                      subtitle: 'Daily assignments',
                      onTap: () => _go(AppRoutes.homework),
                    ),
                    _DrawerTile(
                      icon: Icons.campaign_outlined,
                      title: 'Circulars',
                      subtitle: 'School announcements',
                      onTap: () => _go(AppRoutes.circularTypes),
                    ),
                    _DrawerTile(
                      icon: Icons.fact_check_outlined,
                      title: 'Exams',
                      subtitle: 'Schedule and results',
                      onTap: () => _go(AppRoutes.exams),
                    ),
                    _DrawerTile(
                      icon: Icons.cake_outlined,
                      title: 'Birthdays',
                      subtitle: 'Today classmates birthday',
                      onTap: () => _go(AppRoutes.birthdaysToday),
                    ),
                    _DrawerTile(
                      icon: Icons.notifications_outlined,
                      title: 'General Notifications',
                      subtitle: 'Alerts and updates',
                      onTap: () => _go(AppRoutes.notifications),
                    ),

                    const _SectionDivider(),

                    _SectionLabel('Common Menu'),
                    _DrawerTile(
                      icon: Icons.support_agent_outlined,
                      title: 'Help & Support',
                      subtitle: 'Get help',
                      onTap: () => _go(AppRoutes.helpSupport),
                    ),
                    _DrawerTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Read policy',
                      onTap: () => _go(AppRoutes.privacyPolicy),
                    ),
                    _DrawerTile(
                      icon: Icons.help_outline,
                      title: 'FAQ',
                      subtitle: 'Frequently asked',
                      onTap: () => _go(AppRoutes.faq),
                    ),
                    _DrawerTile(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      subtitle: 'Read terms',
                      onTap: () => _go(AppRoutes.terms),
                    ),
                    _DrawerTile(
                      icon: Icons.info_outline,
                      title: 'About ASE Technologies',
                      subtitle: 'Company info',
                      onTap: () => _go(AppRoutes.aboutAse),
                    ),
                    _DrawerTile(
                      icon: Icons.star_rate_outlined,
                      title: 'Rate this App',
                      subtitle: 'Share your feedback',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _handleRateApp(context);
                      },
                    ),

                    // Version (display-only)
                    pkgAsync.when(
                      data: (pkg) => _DrawerTile(
                        icon: Icons.verified_outlined,
                        title: 'Version',
                        subtitle: 'Current build',
                        trailingText: 'v${pkg.version}+${pkg.buildNumber}',
                        enabled: false,
                        onTap: null,
                      ),
                      loading: () => const _DrawerTile(
                        icon: Icons.verified_outlined,
                        title: 'Version',
                        subtitle: 'Current build',
                        trailingText: '…',
                        enabled: false,
                        onTap: null,
                      ),
                      error: (_, __) => const _DrawerTile(
                        icon: Icons.verified_outlined,
                        title: 'Version',
                        subtitle: 'Current build',
                        trailingText: 'v1.0.0',
                        enabled: false,
                        onTap: null,
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.errorContainer,
                      foregroundColor: scheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _confirmLogout(context);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(
                  '(c) ${DateTime.now().year} ASE Technologies',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRateApp(BuildContext context) async {
    final ok = await AppReview.requestReview();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Thanks for rating the app.'
              : 'Store link is not configured. Add --dart-define=STORE_URL=...',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final session = ref.read(sessionManagerProvider);
    final ok = await showLogoutConfirmDialog(context);
    if (!ok) return;

    await session.clearSession();
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}

class _StudentHeader {
  final String name;
  final String subtitle;
  final String? photoUrl;

  _StudentHeader({
    required this.name,
    required this.subtitle,
    required this.photoUrl,
  });
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.subtitle,
    required this.photoUrl,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heroGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary,
        Color.lerp(scheme.primary, scheme.secondary, 0.32) ?? scheme.primary,
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(gradient: heroGradient),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -28,
                  left: -10,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: ClipOval(
                            child: CachedImage(
                              url: photoUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Text(
                                    'STUDENT',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.7,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.6),
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? trailingText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color iconColor = enabled ? scheme.primary : scheme.onSurfaceVariant;
    final Color textColor =
        enabled ? scheme.onSurface : scheme.onSurfaceVariant;
    final tileGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withValues(alpha: 0.20),
        scheme.secondary.withValues(alpha: 0.15),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainer.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: tileGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
