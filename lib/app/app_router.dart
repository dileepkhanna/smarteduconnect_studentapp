// lib/app/app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_providers.dart';
import 'app_routes.dart';

// Splash
import '../features/splash/presentation/screens/splash_screen.dart';

// Auth
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/verify_otp_screen.dart';
import '../features/auth/presentation/screens/first_time_setup_screen.dart';
import '../features/auth/presentation/screens/biometric_setup_screen.dart';

// App
import '../features/home/presentation/screens/home_shell.dart';
import '../features/profile/presentation/screens/my_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/cms_pages/presentation/screens/privacy_policy_screen.dart';
import '../features/cms_pages/presentation/screens/terms_screen.dart';
import '../features/cms_pages/presentation/screens/faq_screen.dart';
import '../features/cms_pages/presentation/screens/about_ase_screen.dart';
import '../features/cms_pages/presentation/screens/help_support_screen.dart';
import '../features/school/presentation/screens/about_school_screen.dart';
import '../features/timetable/presentation/screens/timetable_screen.dart';
import '../features/attendance/presentation/screens/attendance_screen.dart';
import '../features/recaps/presentation/screens/recaps_screen.dart';
import '../features/recaps/presentation/screens/recap_detail_screen.dart';
import '../features/homework/presentation/screens/homework_screen.dart';
import '../features/homework/presentation/screens/homework_detail_screen.dart';
import '../features/circulars/presentation/screens/circular_types_screen.dart';
import '../features/circulars/presentation/screens/circular_list_screen.dart';
import '../features/circulars/presentation/screens/circular_detail_screen.dart';
import '../features/notifications_feed/presentation/screens/general_notifications_screen.dart';
import '../features/exams/presentation/screens/exams_screen.dart';
import '../features/exams/presentation/screens/exam_schedule_screen.dart';
import '../features/exams/presentation/screens/exam_result_screen.dart';
import '../features/birthdays/presentation/screens/birthdays_today_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionManagerProvider);

  bool isPreAuthLocation(String loc) {
    return loc.startsWith(AppRoutes.login) ||
        loc.startsWith(AppRoutes.forgotPassword) ||
        loc.startsWith(AppRoutes.verifyOtp) ||
        loc.startsWith(AppRoutes.resetPassword);
  }

  bool isSetupLocation(String loc) {
    return loc.startsWith(AppRoutes.firstTimeSetup) ||
        loc.startsWith(AppRoutes.biometricSetup);
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.uri.toString();

      // ✅ Stay on splash until SessionManager hydrate() completes.
      // (SplashGate below triggers hydrate automatically)
      if (!session.isHydrated || session.isHydrating) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final loggedIn = session.isAuthenticated;
      final mustChangePassword = session.mustChangePassword;

      // ✅ Not logged in -> allow only pre-auth screens, otherwise go Login.
      if (!loggedIn) {
        if (isPreAuthLocation(location)) return null;
        return AppRoutes.login; // <-- fixes "stuck on splash" after hydrate
      }

      // ✅ Logged in but must complete first-time setup
      if (mustChangePassword) {
        if (isSetupLocation(location)) return null;
        return AppRoutes.firstTimeSetup;
      }

      // ✅ Logged in -> keep them out of splash/auth/setup
      if (location == AppRoutes.splash ||
          isPreAuthLocation(location) ||
          isSetupLocation(location)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash (this triggers session.hydrate() so it never gets stuck)
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const _SplashGate(),
        ),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),

      // Verify OTP (screen has NO constructor args in your codebase)
      GoRoute(
        path: AppRoutes.verifyOtp,
        pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          final schoolCode = qp['schoolCode'];
          final email = qp['email'];

          if (schoolCode == null ||
              schoolCode.isEmpty ||
              email == null ||
              email.isEmpty) {
            return _page(
              key: state.pageKey,
              child: const _MissingParamsScreen(
                title: 'Invalid link',
                message: 'Missing schoolCode or email.',
              ),
            );
          }

          return _page(
            key: state.pageKey,
            child: const VerifyOtpScreen(),
          );
        },
      ),

      // Reset password (requires params)
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          final schoolCode = qp['schoolCode'];
          final email = qp['email'];
          final otp = qp['otp'];

          if (schoolCode == null ||
              schoolCode.isEmpty ||
              email == null ||
              email.isEmpty ||
              otp == null ||
              otp.isEmpty) {
            return _page(
              key: state.pageKey,
              child: const _MissingParamsScreen(
                title: 'Invalid link',
                message: 'Missing schoolCode, email, or otp.',
              ),
            );
          }

          return _page(
            key: state.pageKey,
            child: _ResetPasswordRouteScreen(
              schoolCode: schoolCode,
              email: email,
              otp: otp,
            ),
          );
        },
      ),

      // Setup
      GoRoute(
        path: AppRoutes.firstTimeSetup,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const FirstTimeSetupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.biometricSetup,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const BiometricSetupScreen(),
        ),
      ),

      // Home
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const HomeShell(),
        ),
      ),

      // Profile
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const MyProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),

      // CMS
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.terms,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const TermsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.faq,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const FaqScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.aboutAse,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const AboutAseScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const HelpSupportScreen(),
        ),
      ),

      // School
      GoRoute(
        path: AppRoutes.aboutSchool,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const AboutSchoolScreen(),
        ),
      ),

      // Timetable
      GoRoute(
        path: AppRoutes.timetable,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const TimetableScreen(),
        ),
      ),

      // Attendance
      GoRoute(
        path: AppRoutes.attendance,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const AttendanceScreen(),
        ),
      ),

      // Recaps
      GoRoute(
        path: AppRoutes.recaps,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const RecapsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.recapDetail,
        pageBuilder: (context, state) {
          final recap = state.extra;
          if (recap is! Map<String, dynamic>) {
            return _page(
              key: state.pageKey,
              child: const _MissingParamsScreen(
                title: 'Invalid navigation',
                message: 'Missing recap data.',
              ),
            );
          }
          return _page(
            key: state.pageKey,
            child: RecapDetailScreen(recap: recap),
          );
        },
      ),

      // Homework
      GoRoute(
        path: AppRoutes.homework,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const HomeworkScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeworkDetail,
        pageBuilder: (context, state) {
          final homeworkId = state.uri.queryParameters['id'];
          if (homeworkId == null || homeworkId.isEmpty) {
            return _page(
              key: state.pageKey,
              child: const _MissingParamsScreen(
                title: 'Invalid link',
                message: 'Missing homework id.',
              ),
            );
          }
          return _page(
            key: state.pageKey,
            child: HomeworkDetailScreen(homeworkId: homeworkId),
          );
        },
      ),

      // Circulars
      GoRoute(
        path: AppRoutes.circularTypes,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const CircularTypesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.circularList,
        pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          final type = qp['type'];
          final title = qp['title'] ?? 'Circulars';

          if (type == null || type.isEmpty) {
            return _page(
              key: state.pageKey,
              child: const _MissingParamsScreen(
                title: 'Invalid link',
                message: 'Missing circular type.',
              ),
            );
          }

          return _page(
            key: state.pageKey,
            child: CircularListScreen(type: type, title: title),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.circularDetail,
        pageBuilder: (context, state) {
          final circularId = state.uri.queryParameters['id'];
          if (circularId == null || circularId.isEmpty) {
            return _page(
              key: state.pageKey,
              child: const _MissingParamsScreen(
                title: 'Invalid link',
                message: 'Missing circular id.',
              ),
            );
          }
          return _page(
            key: state.pageKey,
            child: CircularDetailScreen(circularId: circularId),
          );
        },
      ),

      // Notifications
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const GeneralNotificationsScreen(),
        ),
      ),

      // Exams
      GoRoute(
        path: AppRoutes.exams,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const ExamsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.examSchedule,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const ExamScheduleScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.examResult,
        pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          final examId = qp['examId'];
          final examName = qp['examName'];

          if (examId == null ||
              examId.isEmpty ||
              examName == null ||
              examName.isEmpty) {
            return _page(
              key: state.pageKey,
              child: const _MissingParamsScreen(
                title: 'Invalid link',
                message: 'Missing examId or examName.',
              ),
            );
          }

          return _page(
            key: state.pageKey,
            child: ExamResultScreen(examId: examId, examName: examName),
          );
        },
      ),

      // Birthdays
      GoRoute(
        path: AppRoutes.birthdaysToday,
        pageBuilder: (context, state) => _page(
          key: state.pageKey,
          child: const BirthdaysTodayScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => _page(
      key: state.pageKey,
      child: _MissingParamsScreen(
        title: 'Not found',
        message: state.error?.toString() ?? 'Page not found.',
      ),
    ),
  );
});

MaterialPage<void> _page({required LocalKey key, required Widget child}) {
  return MaterialPage<void>(key: key, child: child);
}

/// ✅ Calls session.hydrate() so redirect logic can move away from splash.
class _SplashGate extends ConsumerStatefulWidget {
  const _SplashGate();

  @override
  ConsumerState<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<_SplashGate> {
  @override
  void initState() {
    super.initState();
    // Trigger hydrate once after first frame/microtask
    scheduleMicrotask(() {
      ref.read(sessionManagerProvider).hydrate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class _ResetPasswordRouteScreen extends ConsumerStatefulWidget {
  const _ResetPasswordRouteScreen({
    required this.schoolCode,
    required this.email,
    required this.otp,
  });

  final String schoolCode;
  final String email;
  final String otp;

  @override
  ConsumerState<_ResetPasswordRouteScreen> createState() =>
      _ResetPasswordRouteScreenState();
}

class _ResetPasswordRouteScreenState
    extends ConsumerState<_ResetPasswordRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'New password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';

    final hasLower = RegExp(r'[a-z]').hasMatch(v);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(v);
    if (!hasLower || !hasUpper || !hasDigit || !hasSymbol) {
      return 'Use lowercase, uppercase, number and symbol';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Confirm password is required';
    if (v != _newCtrl.text.trim()) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = ref.read(authControllerProvider.notifier);

    try {
      await withGlobalLoader(ref, () async {
        await auth.resetPassword(
          schoolCode: widget.schoolCode,
          email: widget.email,
          otp: widget.otp,
          newPassword: _newCtrl.text,
          confirmNewPassword: _confirmCtrl.text,
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Password reset successful'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      final msg = auth.mapError(e);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'School: ${widget.schoolCode.toUpperCase()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Email: ${widget.email}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newCtrl,
                obscureText: true,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                validator: _validateConfirm,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: Text(isLoading ? 'Please wait...' : 'Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingParamsScreen extends StatelessWidget {
  const _MissingParamsScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message),
      ),
    );
  }
}
