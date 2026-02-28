// // lib/features/home/presentation/screens/dashboard_screen.dart
// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';

// import '../../../../app/app_providers.dart';
// import '../../../../app/app_routes.dart';
// import '../../../../core/config/endpoints.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/app_badge.dart';
// import '../../../../core/widgets/app_card.dart';
// import '../../../../core/widgets/cached_image.dart';
// import '../../../circulars/presentation/screens/circular_list_screen.dart';

// class _DashboardCounts {
//   final Map<String, int> unseenByType;
//   final int circularTotalUnseen;
//   final int birthdaysTodayCount;

//   const _DashboardCounts({
//     required this.unseenByType,
//     required this.circularTotalUnseen,
//     required this.birthdaysTodayCount,
//   });

//   static const empty = _DashboardCounts(
//     unseenByType: <String, int>{},
//     circularTotalUnseen: 0,
//     birthdaysTodayCount: 0,
//   );
// }

// class _StudentSummary {
//   final String name;
//   final String classLabel; // "Class 10 • A"
//   final String rollLabel; // "Roll 12" or ""
//   final String? photoUrl;
//   final String? schoolCode;

//   const _StudentSummary({
//     required this.name,
//     required this.classLabel,
//     required this.rollLabel,
//     required this.photoUrl,
//     required this.schoolCode,
//   });
// }

// class _CircType {
//   final String key; // EXAM, EVENT...
//   final String title;
//   final String asset; // ✅ PNG asset
//   final Color color;

//   const _CircType(this.key, this.title, this.asset, this.color);
// }

// class DashboardScreen extends ConsumerStatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends ConsumerState<DashboardScreen> {
//   late Future<_DashboardCounts> _countsFuture;
//   late Future<_StudentSummary> _studentFuture;

//   static const String _ic = 'assets/icons';

//   static const List<_CircType> _circTypes = [
//     _CircType('EXAM', 'Exam', '$_ic/exam.png', AppColors.brandBlue),
//     _CircType('EVENT', 'Event', '$_ic/event.png', AppColors.brandPurple),
//     _CircType('PTM', 'PTM', '$_ic/ptm.png', AppColors.brandTeal),
//     _CircType('HOLIDAY', 'Holiday', '$_ic/holiday.png', AppColors.brandOrange),
//     _CircType('TRANSPORT', 'Transport', '$_ic/transport.png', AppColors.brandGreen),
//     _CircType('GENERAL', 'General', '$_ic/generalnotification.png', AppColors.brandRed),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _countsFuture = _loadCounts();
//     _studentFuture = _loadStudent();
//   }

//   Color _alpha(Color c, double opacity) {
//     final a = (opacity.clamp(0.0, 1.0) * 255).round();
//     return c.withAlpha(a);
//   }

//   int _toInt(dynamic v) {
//     if (v is int) return v;
//     if (v is num) return v.toInt();
//     return int.tryParse(v?.toString() ?? '') ?? 0;
//   }

//   Future<_StudentSummary> _loadStudent() async {
//     final api = ref.read(apiClientProvider);
//     final session = ref.read(sessionManagerProvider);

//     try {
//       final res = await api.get<dynamic>(Endpoints.userMe);
//       final raw = res.data;

//       Map<String, dynamic> root = <String, dynamic>{};
//       if (raw is Map) root = Map<String, dynamic>.from(raw);

//       final data = (root['data'] is Map) ? Map<String, dynamic>.from(root['data']) : root;

//       final student = (data['student'] is Map) ? Map<String, dynamic>.from(data['student']) : <String, dynamic>{};
//       final profile = (data['profile'] is Map) ? Map<String, dynamic>.from(data['profile']) : <String, dynamic>{};

//       String pickString(List<Map<String, dynamic>> maps, List<String> keys, {String fallback = ''}) {
//         for (final m in maps) {
//           for (final k in keys) {
//             final v = m[k];
//             if (v is String && v.trim().isNotEmpty) return v.trim();
//           }
//         }
//         return fallback;
//       }

//       int? pickInt(List<Map<String, dynamic>> maps, List<String> keys) {
//         for (final m in maps) {
//           for (final k in keys) {
//             final v = m[k];
//             if (v is int) return v;
//             if (v is num) return v.toInt();
//             final n = int.tryParse(v?.toString() ?? '');
//             if (n != null) return n;
//           }
//         }
//         return null;
//       }

//       final name = pickString(
//         [student, profile, data],
//         ['fullName', 'name', 'displayName', 'studentName', 'userName'],
//         fallback: session.userName ?? 'Student',
//       );

//       final classNumber = pickInt([student, profile, data], ['classNumber', 'class', 'standard', 'grade']);
//       final section = pickString([student, profile, data], ['section', 'sec'], fallback: '');
//       final roll = pickString([student, profile, data], ['rollNumber', 'rollNo', 'roll'], fallback: '');

//       final photoUrl = pickString(
//         [student, profile, data],
//         ['profilePhotoUrl', 'photoUrl', 'avatarUrl', 'imageUrl', 'photo'],
//         fallback: '',
//       );

//       final schoolCode = pickString(
//         [data, profile, student],
//         ['schoolName', 'school_name', 'schoolCode', 'school_code'],
//         fallback: session.schoolCode ?? '',
//       );

//       final classLabel = [
//         if (classNumber != null) 'Class $classNumber',
//         if (section.isNotEmpty) section,
//       ].join(' • ').trim();

//       final rollLabel = roll.isNotEmpty ? 'Roll $roll' : '';

//       return _StudentSummary(
//         name: name.isEmpty ? (session.userName ?? 'Student') : name,
//         classLabel: classLabel.isEmpty ? 'Student' : classLabel,
//         rollLabel: rollLabel,
//         photoUrl: photoUrl.isEmpty ? null : photoUrl,
//         schoolCode: schoolCode.isEmpty ? null : schoolCode,
//       );
//     } catch (_) {
//       return _StudentSummary(
//         name: session.userName ?? 'Student',
//         classLabel: 'Student',
//         rollLabel: '',
//         photoUrl: null,
//         schoolCode: session.schoolCode,
//       );
//     }
//   }

//   Future<_DashboardCounts> _loadCounts() async {
//     final unseenFuture =
//         ref.read(circularsRepositoryProvider).getUnseenCounts().catchError((_) => <String, dynamic>{});

//     final birthdaysFuture =
//         ref.read(birthdaysRepositoryProvider).getTodayClassmateBirthdays().catchError((_) => <dynamic>[]);

//     final results = await Future.wait<dynamic>([unseenFuture, birthdaysFuture]);

//     final unseenRaw = (results[0] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
//     final bdays = (results[1] as List?) ?? <dynamic>[];

//     final unseenByType = <String, int>{};
//     for (final e in unseenRaw.entries) {
//       unseenByType[e.key.toString().toUpperCase()] = _toInt(e.value);
//     }

//     final circularTotal = unseenByType.values.fold<int>(0, (a, b) => a + b);

//     return _DashboardCounts(
//       unseenByType: unseenByType,
//       circularTotalUnseen: circularTotal,
//       birthdaysTodayCount: bdays.length,
//     );
//   }

//   void _reloadAll() {
//     setState(() {
//       _countsFuture = _loadCounts();
//       _studentFuture = _loadStudent();
//     });
//   }

//   /// ✅ Loader shows immediately and stops quickly (won’t stay until back)
//   Future<void> _nav(String route) async {
//     await withGlobalLoader(ref, () async {
//       if (!mounted) return;
//       unawaited(context.push(route));
//       await Future<void>.delayed(const Duration(milliseconds: 220));
//     });
//   }

//   /// ✅ Same for circular list (do not await push)
//   Future<void> _openCircularType(_CircType t) async {
//     await withGlobalLoader(ref, () async {
//       if (!mounted) return;

//       unawaited(
//         Navigator.of(context)
//             .push(
//               MaterialPageRoute<void>(
//                 builder: (_) => CircularListScreen(
//                   type: t.key,
//                   title: '${t.title} Circulars',
//                 ),
//               ),
//             )
//             .then((_) {
//           if (mounted) _reloadAll();
//         }),
//       );

//       await Future<void>.delayed(const Duration(milliseconds: 240));
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return Container(
//       decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
//       child: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: () async {
//             _reloadAll();
//             await Future.wait([_countsFuture, _studentFuture]);
//           },
//           child: FutureBuilder<List<dynamic>>(
//             future: Future.wait<dynamic>([_studentFuture, _countsFuture]),
//             builder: (context, snap) {
//               final student = (snap.data != null && snap.data!.isNotEmpty)
//                   ? snap.data![0] as _StudentSummary
//                   : const _StudentSummary(
//                       name: 'Student',
//                       classLabel: 'Student',
//                       rollLabel: '',
//                       photoUrl: null,
//                       schoolCode: null,
//                     );

//               final counts = (snap.data != null && snap.data!.length > 1)
//                   ? snap.data![1] as _DashboardCounts
//                   : _DashboardCounts.empty;

//               final subtitleParts = <String>[
//                 student.classLabel,
//                 if (student.rollLabel.isNotEmpty) student.rollLabel,
//               ];

//               return ListView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
//                 children: [
//                   // =========================
//                   // HERO STUDENT CARD
//                   // =========================
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [AppColors.brandTeal, AppColors.brandBlue],
//                       ),
//                       borderRadius: BorderRadius.circular(AppSpacing.rXl),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Color(0x22000000),
//                           blurRadius: 26,
//                           offset: Offset(0, 14),
//                         ),
//                       ],
//                     ),
//                     child: Stack(
//                       children: [
//                         Positioned(
//                           right: -30,
//                           top: -30,
//                           child: Container(
//                             width: 140,
//                             height: 140,
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.12),
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           left: -40,
//                           bottom: -40,
//                           child: Container(
//                             width: 170,
//                             height: 170,
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.10),
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(3),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white.withOpacity(0.28),
//                                   borderRadius: BorderRadius.circular(22),
//                                   border: Border.all(color: Colors.white.withOpacity(0.35)),
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(20),
//                                   child: CachedImage(
//                                     url: student.photoUrl,
//                                     width: 70,
//                                     height: 70,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       student.name,
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.w900,
//                                           ),
//                                     ),
//                                     const SizedBox(height: 6),
//                                     Text(
//                                       subtitleParts.join(' • '),
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                                             color: Colors.white.withOpacity(0.92),
//                                             fontWeight: FontWeight.w700,
//                                             height: 1.25,
//                                           ),
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Wrap(
//                                       spacing: 10,
//                                       runSpacing: 10,
//                                       children: [
//                                         _Pill(
//                                           icon: Icons.school_rounded,
//                                           label: student.schoolCode == null ? 'School' : '${student.schoolCode}',
//                                         ),
//                                         const _Pill(
//                                           icon: Icons.verified_user_rounded,
//                                           label: 'Student',
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Column(
//                                 children: [
//                                   IconButton(
//                                     onPressed: () => _nav(AppRoutes.profile),
//                                     icon: const Icon(Icons.person_rounded),
//                                     color: Colors.white,
//                                     tooltip: 'Profile',
//                                   ),
//                                   IconButton(
//                                     onPressed: _reloadAll,
//                                     icon: const Icon(Icons.refresh_rounded),
//                                     color: Colors.white,
//                                     tooltip: 'Refresh',
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 14),

//                   // =========================
//                   // INSIGHTS STRIP (PNG ICONS)
//                   // =========================
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _InsightCard(
//                           title: 'Circulars',
//                           value: counts.circularTotalUnseen,
//                           subtitle: 'Unseen updates',
//                           asset: 'assets/icons/generalnotification.png',
//                           tint: AppColors.brandOrange,
//                           onTap: () => _nav(AppRoutes.circularTypes),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _InsightCard(
//                           title: 'Birthdays',
//                           value: counts.birthdaysTodayCount,
//                           subtitle: 'Today in class',
//                           asset: 'assets/icons/birthday.png',
//                           tint: AppColors.brandPurple,
//                           onTap: () => _nav(AppRoutes.birthdaysToday),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // =========================
//                   // SHORTCUTS (PNG ICONS)
//                   // =========================
//                   _SectionHeader(
//                     title: 'Shortcuts',
//                     subtitle: 'Everything on home screen',
//                     actionLabel: 'Profile',
//                     onAction: () => _nav(AppRoutes.profile),
//                   ),
//                   const SizedBox(height: 10),

//                   GridView.count(
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 12,
//                     mainAxisSpacing: 12,
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     childAspectRatio: 1.18,
//                     children: [
//                       _ActionTile(
//                         title: 'Timetable',
//                         subtitle: 'Today periods',
//                         asset: 'assets/icons/timetable.png',
//                         badgeCount: 0,
//                         tint: AppColors.brandTeal,
//                         alpha: _alpha,
//                         onTap: () => _nav(AppRoutes.timetable),
//                       ),
//                       _ActionTile(
//                         title: 'Attendance',
//                         subtitle: 'Daily status',
//                         asset: 'assets/icons/attendance.png',
//                         badgeCount: 0,
//                         tint: AppColors.brandGreen,
//                         alpha: _alpha,
//                         onTap: () => _nav(AppRoutes.attendance),
//                       ),
//                       _ActionTile(
//                         title: 'Recaps',
//                         subtitle: 'Daily recap',
//                         asset: 'assets/icons/recap.png',
//                         badgeCount: 0,
//                         tint: AppColors.brandBlue,
//                         alpha: _alpha,
//                         onTap: () => _nav(AppRoutes.recaps),
//                       ),
//                       _ActionTile(
//                         title: 'Homework',
//                         subtitle: 'Assignments',
//                         asset: 'assets/icons/homework.png',
//                         badgeCount: 0,
//                         tint: AppColors.brandRed,
//                         alpha: _alpha,
//                         onTap: () => _nav(AppRoutes.homework),
//                       ),
//                       _ActionTile(
//                         title: 'Exams',
//                         subtitle: 'Schedule & results',
//                         asset: 'assets/icons/exam.png',
//                         badgeCount: 0,
//                         tint: AppColors.brandPurple,
//                         alpha: _alpha,
//                         onTap: () => _nav(AppRoutes.exams),
//                       ),
//                       _ActionTile(
//                         title: 'Notifications',
//                         subtitle: 'All updates',
//                         asset: 'assets/icons/generalnotification.png',
//                         badgeCount: 0,
//                         tint: AppColors.brandTeal,
//                         alpha: _alpha,
//                         onTap: () => _nav(AppRoutes.notifications),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // =========================
//                   // CIRCULAR CATEGORIES (PNG ICONS)
//                   // =========================
//                   _SectionHeader(
//                     title: 'Circular Categories',
//                     subtitle: 'Open directly from here',
//                     actionLabel: 'All',
//                     onAction: () => _nav(AppRoutes.circularTypes),
//                   ),
//                   const SizedBox(height: 10),

//                   GridView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: _circTypes.length,
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       crossAxisSpacing: 12,
//                       mainAxisSpacing: 12,
//                       childAspectRatio: 1.40,
//                     ),
//                     itemBuilder: (context, i) {
//                       final t = _circTypes[i];
//                       final unseen = counts.unseenByType[t.key] ?? 0;

//                       return InkWell(
//                         borderRadius: BorderRadius.circular(AppSpacing.rLg),
//                         onTap: () => _openCircularType(t),
//                         child: AppCard(
//                           padding: const EdgeInsets.all(14),
//                           child: Stack(
//                             children: [
//                               if (unseen > 0)
//                                 Positioned(
//                                   top: 0,
//                                   right: 0,
//                                   child: AppBadge(count: unseen),
//                                 ),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Container(
//                                     width: 46,
//                                     height: 46,
//                                     decoration: BoxDecoration(
//                                       color: _alpha(t.color, 0.14),
//                                       borderRadius: BorderRadius.circular(AppSpacing.rLg),
//                                       border: Border.all(color: _alpha(t.color, 0.26)),
//                                     ),
//                                     child: _AssetIcon(
//                                       asset: t.asset,
//                                       size: 26,
//                                     ),
//                                   ),
//                                   const Spacer(),
//                                   Text(
//                                     t.title,
//                                     style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                                           fontWeight: FontWeight.w900,
//                                         ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     unseen > 0 ? '$unseen unseen' : 'No new',
//                                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                           color: scheme.onSurfaceVariant,
//                                           fontWeight: FontWeight.w700,
//                                         ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),

//                   const SizedBox(height: 16),

//                   // =========================
//                   // HELP STRIP
//                   // =========================
//                   AppCard(
//                     padding: const EdgeInsets.all(14),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 44,
//                           height: 44,
//                           decoration: BoxDecoration(
//                             color: _alpha(AppColors.brandTeal, 0.14),
//                             borderRadius: BorderRadius.circular(AppSpacing.rLg),
//                             border: Border.all(color: _alpha(AppColors.brandTeal, 0.26)),
//                           ),
//                           child: const Icon(Icons.support_agent_rounded, color: AppColors.brandTeal),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Help & Support',
//                                 style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                                       fontWeight: FontWeight.w900,
//                                     ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'If something is not loading, pull to refresh or open Help & Support.',
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                       color: scheme.onSurfaceVariant,
//                                       fontWeight: FontWeight.w700,
//                                       height: 1.25,
//                                     ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: () => _nav(AppRoutes.helpSupport),
//                           icon: const Icon(Icons.chevron_right_rounded),
//                         ),
//                       ],
//                     ),
//                   ),

//                   if (snap.hasError) ...[
//                     const SizedBox(height: 10),
//                     Text(
//                       'Some dashboard data failed to load. Pull down to retry.',
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                             color: scheme.error,
//                             fontWeight: FontWeight.w800,
//                           ),
//                     ),
//                   ],
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AssetIcon extends StatelessWidget {
//   const _AssetIcon({
//     required this.asset,
//     this.size = 24,
//   });

//   final String asset;
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Image.asset(
//         asset,
//         width: size,
//         height: size,
//         fit: BoxFit.contain,
//         errorBuilder: (_, __, ___) {
//           return Icon(Icons.image_not_supported_rounded, size: size);
//         },
//       ),
//     );
//   }
// }

// class _SectionHeader extends StatelessWidget {
//   const _SectionHeader({
//     required this.title,
//     required this.subtitle,
//     required this.actionLabel,
//     required this.onAction,
//   });

//   final String title;
//   final String subtitle;
//   final String actionLabel;
//   final VoidCallback onAction;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w900,
//                     ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: scheme.onSurfaceVariant,
//                       fontWeight: FontWeight.w700,
//                     ),
//               ),
//             ],
//           ),
//         ),
//         TextButton.icon(
//           onPressed: onAction,
//           icon: const Icon(Icons.chevron_right_rounded, size: 18),
//           label: Text(actionLabel),
//         ),
//       ],
//     );
//   }
// }

// class _Pill extends StatelessWidget {
//   const _Pill({required this.icon, required this.label});

//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.16),
//         borderRadius: BorderRadius.circular(AppSpacing.rLg),
//         border: Border.all(color: Colors.white.withOpacity(0.22)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: Colors.white),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: Colors.white.withOpacity(0.95),
//                   fontWeight: FontWeight.w800,
//                 ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _InsightCard extends StatelessWidget {
//   const _InsightCard({
//     required this.title,
//     required this.value,
//     required this.subtitle,
//     required this.asset,
//     required this.tint,
//     required this.onTap,
//   });

//   final String title;
//   final int value;
//   final String subtitle;
//   final String asset;
//   final Color tint;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return InkWell(
//       borderRadius: BorderRadius.circular(AppSpacing.rLg),
//       onTap: onTap,
//       child: AppCard(
//         padding: const EdgeInsets.all(14),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: tint.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(AppSpacing.rLg),
//                 border: Border.all(color: tint.withOpacity(0.25)),
//               ),
//               child: _AssetIcon(asset: asset, size: 26),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                           fontWeight: FontWeight.w900,
//                         ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: scheme.onSurfaceVariant,
//                           fontWeight: FontWeight.w700,
//                         ),
//                   ),
//                 ],
//               ),
//             ),
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 180),
//               child: Container(
//                 key: ValueKey(value),
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: scheme.surface,
//                   borderRadius: BorderRadius.circular(AppSpacing.rLg),
//                   border: Border.all(color: scheme.outlineVariant),
//                 ),
//                 child: Text(
//                   value.toString(),
//                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                         fontWeight: FontWeight.w900,
//                       ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ActionTile extends StatelessWidget {
//   const _ActionTile({
//     required this.title,
//     required this.subtitle,
//     required this.asset,
//     required this.badgeCount,
//     required this.onTap,
//     required this.tint,
//     required this.alpha,
//   });

//   final String title;
//   final String subtitle;
//   final String asset;
//   final int badgeCount;
//   final VoidCallback onTap;
//   final Color tint;
//   final Color Function(Color, double) alpha;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return InkWell(
//       borderRadius: BorderRadius.circular(AppSpacing.rLg),
//       onTap: onTap,
//       child: AppCard(
//         padding: const EdgeInsets.all(14),
//         child: Stack(
//           children: [
//             if (badgeCount > 0)
//               Positioned(
//                 top: 0,
//                 right: 0,
//                 child: AppBadge(count: badgeCount),
//               ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 46,
//                   height: 46,
//                   decoration: BoxDecoration(
//                     color: alpha(tint, 0.14),
//                     borderRadius: BorderRadius.circular(AppSpacing.rLg),
//                     border: Border.all(color: alpha(tint, 0.26)),
//                   ),
//                   child: _AssetIcon(asset: asset, size: 26),
//                 ),
//                 const Spacer(),
//                 Text(
//                   title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                         fontWeight: FontWeight.w900,
//                       ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   subtitle,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: scheme.onSurfaceVariant,
//                         fontWeight: FontWeight.w700,
//                         height: 1.25,
//                       ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
























// lib/features/home/presentation/screens/dashboard_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/config/endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../circulars/presentation/screens/circular_list_screen.dart';

class _DashboardCounts {
  final Map<String, int> unseenByType;
  final int circularTotalUnseen;
  final int birthdaysTodayCount;

  const _DashboardCounts({
    required this.unseenByType,
    required this.circularTotalUnseen,
    required this.birthdaysTodayCount,
  });

  static const empty = _DashboardCounts(
    unseenByType: <String, int>{},
    circularTotalUnseen: 0,
    birthdaysTodayCount: 0,
  );
}

class _StudentSummary {
  final String name;
  final String classLabel; // "Class 10 • A"
  final String rollLabel; // "Roll 12" or ""
  final String? photoUrl;
  final String? schoolCode;

  const _StudentSummary({
    required this.name,
    required this.classLabel,
    required this.rollLabel,
    required this.photoUrl,
    required this.schoolCode,
  });
}

class _CircType {
  final String key; // EXAM, EVENT...
  final String title;
  final String asset; // PNG asset
  final Color color;

  const _CircType(this.key, this.title, this.asset, this.color);
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late Future<_DashboardCounts> _countsFuture;
  late Future<_StudentSummary> _studentFuture;

  static const String _ic = 'assets/icons';

  static const List<_CircType> _circTypes = [
    _CircType('EXAM', 'Exam', '$_ic/examnotification.png', AppColors.brandBlue),
    _CircType('EVENT', 'Event', '$_ic/event.png', AppColors.brandPurple),
    _CircType('PTM', 'PTM', '$_ic/ptm.png', AppColors.brandTeal),
    _CircType('HOLIDAY', 'Holiday', '$_ic/holiday.png', AppColors.brandOrange),
    _CircType('TRANSPORT', 'Transport', '$_ic/transport.png', AppColors.brandGreen),
    _CircType('GENERAL', 'General', '$_ic/generalnotification.png', AppColors.brandRed),
  ];

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
    _studentFuture = _loadStudent();
  }

  Color _alpha(Color c, double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round();
    return c.withAlpha(a);
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<_StudentSummary> _loadStudent() async {
    final api = ref.read(apiClientProvider);
    final session = ref.read(sessionManagerProvider);

    try {
      final res = await api.get<dynamic>(Endpoints.userMe);
      final raw = res.data;

      Map<String, dynamic> root = <String, dynamic>{};
      if (raw is Map) root = Map<String, dynamic>.from(raw);

      final data = (root['data'] is Map) ? Map<String, dynamic>.from(root['data']) : root;

      final student = (data['student'] is Map) ? Map<String, dynamic>.from(data['student']) : <String, dynamic>{};
      final profile = (data['profile'] is Map) ? Map<String, dynamic>.from(data['profile']) : <String, dynamic>{};

      String pickString(List<Map<String, dynamic>> maps, List<String> keys, {String fallback = ''}) {
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
        ['fullName', 'name', 'displayName', 'studentName', 'userName'],
        fallback: session.userName ?? 'Student',
      );

      final classNumber = pickInt([student, profile, data], ['classNumber', 'class', 'standard', 'grade']);
      final section = pickString([student, profile, data], ['section', 'sec'], fallback: '');
      final roll = pickString([student, profile, data], ['rollNumber', 'rollNo', 'roll'], fallback: '');

      final photoUrl = pickString(
        [student, profile, data],
        ['profilePhotoUrl', 'photoUrl', 'avatarUrl', 'imageUrl', 'photo'],
        fallback: '',
      );

      final schoolCode = pickString(
        [data, profile, student],
        ['schoolName', 'school_name', 'schoolCode', 'school_code'],
        fallback: session.schoolCode ?? '',
      );


      final classLabel = [
        if (classNumber != null) 'Class $classNumber',
        if (section.isNotEmpty) section,
      ].join(' • ').trim();

      final rollLabel = roll.isNotEmpty ? 'Roll $roll' : '';

      return _StudentSummary(
        name: name.isEmpty ? (session.userName ?? 'Student') : name,
        classLabel: classLabel.isEmpty ? 'Student' : classLabel,
        rollLabel: rollLabel,
        photoUrl: photoUrl.isEmpty ? null : photoUrl,
        schoolCode: schoolCode.isEmpty ? null : schoolCode,
      );
    } catch (_) {
      return _StudentSummary(
        name: session.userName ?? 'Student',
        classLabel: 'Student',
        rollLabel: '',
        photoUrl: null,
        schoolCode: session.schoolCode,
      );
    }
  }

  Future<_DashboardCounts> _loadCounts() async {
    final unseenFuture =
        ref.read(circularsRepositoryProvider).getUnseenCounts().catchError((_) => <String, dynamic>{});
    final birthdaysFuture =
        ref.read(birthdaysRepositoryProvider).getTodayClassmateBirthdays().catchError((_) => <dynamic>[]);

    final results = await Future.wait<dynamic>([unseenFuture, birthdaysFuture]);

    final unseenRaw = <String, dynamic>{};
    final unseenInput = results.isNotEmpty ? results[0] : null;
    if (unseenInput is Map) {
      unseenInput.forEach((k, v) {
        unseenRaw[k.toString()] = v;
      });
    }
    final bdays = (results[1] as List?) ?? <dynamic>[];

    final unseenByType = <String, int>{};
    for (final e in unseenRaw.entries) {
      unseenByType[e.key.toString().toUpperCase()] = _toInt(e.value);
    }

    final circularTotal = unseenByType.values.fold<int>(0, (a, b) => a + b);

    return _DashboardCounts(
      unseenByType: unseenByType,
      circularTotalUnseen: circularTotal,
      birthdaysTodayCount: bdays.length,
    );
  }

  void _reloadAll() {
    setState(() {
      _countsFuture = _loadCounts();
      _studentFuture = _loadStudent();
    });
  }

  Future<void> _nav(String route) async {
    await withGlobalLoader(ref, () async {
      if (!mounted) return;
      unawaited(context.push(route));
      await Future<void>.delayed(const Duration(milliseconds: 220));
    });
  }

  Future<void> _openCircularType(_CircType t) async {
    await withGlobalLoader(ref, () async {
      if (!mounted) return;

      unawaited(
        Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => CircularListScreen(type: t.key, title: '${t.title} Circulars'),
              ),
            )
            .then((_) {
          if (mounted) _reloadAll();
        }),
      );

      await Future<void>.delayed(const Duration(milliseconds: 240));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradientSoft),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _reloadAll();
            await Future.wait([_countsFuture, _studentFuture]);
          },
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait<dynamic>([_studentFuture, _countsFuture]),
            builder: (context, snap) {
              final student = (snap.data != null && snap.data!.isNotEmpty)
                  ? snap.data![0] as _StudentSummary
                  : const _StudentSummary(
                      name: 'Student',
                      classLabel: 'Student',
                      rollLabel: '',
                      photoUrl: null,
                      schoolCode: null,
                    );

              final counts = (snap.data != null && snap.data!.length > 1)
                  ? snap.data![1] as _DashboardCounts
                  : _DashboardCounts.empty;

              final subtitleParts = <String>[
                student.classLabel,
                if (student.rollLabel.isNotEmpty) student.rollLabel,
              ];

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  // =========================
                  // HERO STUDENT CARD
                  // =========================
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.brandTeal, AppColors.brandBlue],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.rXl),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 26,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -40,
                          bottom: -40,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.28),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CachedImage(
                                    url: student.photoUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitleParts.join(' • '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withOpacity(0.92),
                                            fontWeight: FontWeight.w700,
                                            height: 1.25,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _Pill(
                                          icon: Icons.school_rounded,
                                          label: student.schoolCode == null ? 'School' : '${student.schoolCode}',
                                        ),
                                        const _Pill(
                                          icon: Icons.verified_user_rounded,
                                          label: 'Student',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () => _nav(AppRoutes.profile),
                                    icon: const Icon(Icons.person_rounded),
                                    color: Colors.white,
                                    tooltip: 'Profile',
                                  ),
                                  IconButton(
                                    onPressed: _reloadAll,
                                    icon: const Icon(Icons.refresh_rounded),
                                    color: Colors.white,
                                    tooltip: 'Refresh',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // SHORTCUTS (BIG IMAGE + NAME)
                  // =========================
                  _SectionHeader(
                    title: 'Shortcuts',
                    subtitle: 'Everything on home screen',
                    actionLabel: 'Refresh',
                    onAction: _reloadAll,
                  ),
                  const SizedBox(height: 10),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.05,
                    children: [
                      _BigImageTile(
                        title: 'Timetable',
                        subtitle: 'Today periods',
                        asset: 'assets/icons/timetable.png',
                        accent: AppColors.brandTeal,
                        onTap: () => _nav(AppRoutes.timetable),
                      ),
                      _BigImageTile(
                        title: 'Attendance',
                        subtitle: 'Daily status',
                        asset: 'assets/icons/attendance.png',
                        accent: AppColors.brandGreen,
                        onTap: () => _nav(AppRoutes.attendance),
                      ),
                      _BigImageTile(
                        title: 'Recaps',
                        subtitle: 'Daily recap',
                        asset: 'assets/icons/recap.png',
                        accent: AppColors.brandBlue,
                        onTap: () => _nav(AppRoutes.recaps),
                      ),
                      _BigImageTile(
                        title: 'Homework',
                        subtitle: 'Assignments',
                        asset: 'assets/icons/homework.png',
                        accent: AppColors.brandRed,
                        onTap: () => _nav(AppRoutes.homework),
                      ),
                      _BigImageTile(
                        title: 'Exams',
                        subtitle: 'Schedule & results',
                        asset: 'assets/icons/exam.png',
                        accent: AppColors.brandPurple,
                        onTap: () => _nav(AppRoutes.exams),
                      ),
                      _BigImageTile(
                        title: 'Notifications',
                        subtitle: 'All updates',
                        asset: 'assets/icons/generalnotification.png',
                        accent: AppColors.brandOrange,
                        onTap: () => _nav(AppRoutes.notifications),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // CIRCULAR CATEGORIES (BIG IMAGE + NAME)
                  // =========================
                  _SectionHeader(
                    title: 'Circular Categories',
                    subtitle: 'Open directly from home',
                    actionLabel: 'All',
                    onAction: () => _nav(AppRoutes.circularTypes),
                  ),
                  const SizedBox(height: 10),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _circTypes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, i) {
                      final t = _circTypes[i];
                      final unseen = counts.unseenByType[t.key] ?? 0;

                      return _BigImageTile(
                        title: t.title,
                        subtitle: unseen > 0 ? '$unseen unseen' : 'No new',
                        asset: t.asset,
                        accent: t.color,
                        badgeCount: unseen,
                        onTap: () => _openCircularType(t),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // HELP STRIP
                  // =========================
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _alpha(AppColors.brandTeal, 0.14),
                            borderRadius: BorderRadius.circular(AppSpacing.rLg),
                            border: Border.all(color: _alpha(AppColors.brandTeal, 0.26)),
                          ),
                          child: const Icon(Icons.support_agent_rounded, color: AppColors.brandTeal),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Help & Support',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'If something is not loading, pull to refresh or open Help & Support.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _nav(AppRoutes.helpSupport),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BigImageTile extends StatelessWidget {
  const _BigImageTile({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.accent,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String title;
  final String subtitle;
  final String asset;
  final Color accent;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.rXl),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: AppBadge(count: badgeCount),
              ),

            // soft gradient glow
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.10),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ BIG IMAGE (no box)
                Expanded(
                  child: Center(
                    child: Image.asset(
                      asset,
                      height: 78,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.image, size: 54, color: accent),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.chevron_right_rounded, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
