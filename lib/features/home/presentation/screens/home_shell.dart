// lib/features/home/presentation/screens/home_shell.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/config/endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/app_appbar.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_loader_overlay.dart';
import '../../../../core/widgets/logout_confirm_dialog.dart';
import 'dashboard_screen.dart';

final schoolNameProvider = FutureProvider<String>((ref) async {
  final api = ref.read(apiClientProvider);

  try {
    final res = await api.get<dynamic>(Endpoints.schoolMe);
    final raw = res.data;

    Map<String, dynamic> root = <String, dynamic>{};
    if (raw is Map) root = Map<String, dynamic>.from(raw);

    final data =
        (root['data'] is Map) ? Map<String, dynamic>.from(root['data']) : root;

    final name = (data['name'] ?? data['schoolName'] ?? data['title'])
        ?.toString()
        .trim();
    if (name != null && name.isNotEmpty) return name;

    // fallback
    final session = ref.read(sessionManagerProvider);
    return session.schoolCode == null || session.schoolCode!.isEmpty
        ? 'ASE School'
        : 'ASE School (${session.schoolCode})';
  } catch (_) {
    final session = ref.read(sessionManagerProvider);
    return session.schoolCode == null || session.schoolCode!.isEmpty
        ? 'ASE School'
        : 'ASE School (${session.schoolCode})';
  }
});

/// Parent/Student Home Shell:
/// - Scaffold + Drawer + AppBar (menu left, school name center) + Logout
/// - Wrapped with AppLoaderOverlay to show Lottie loader globally
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    unawaited(_verifyStudentSession());
  }

  Future<void> _verifyStudentSession() async {
    final session = ref.read(sessionManagerProvider);
    if (!session.isAuthenticated) return;

    try {
      final res =
          await ref.read(apiClientProvider).get<dynamic>(Endpoints.userMe);
      final raw = res.data;
      Map<String, dynamic> root = <String, dynamic>{};
      if (raw is Map<String, dynamic>) {
        root = raw;
      } else if (raw is Map) {
        root = Map<String, dynamic>.from(raw);
      }

      final data = (root['data'] is Map<String, dynamic>)
          ? root['data'] as Map<String, dynamic>
          : (root['data'] is Map)
              ? Map<String, dynamic>.from(root['data'] as Map)
              : root;

      final role = (data['role'] ?? '').toString().trim().toUpperCase();
      if (role != 'STUDENT') {
        await session.clearSession();
        return;
      }

      final mustChangePassword = data['mustChangePassword'] == true;
      if (mustChangePassword && !session.mustChangePassword) {
        await session.markMustChangePasswordRequired();
      } else if (!mustChangePassword && session.mustChangePassword) {
        await session.clearMustChangePassword();
      }
    } on DioException catch (e) {
      String code = '';
      if (e.error is ApiError) {
        code = (e.error as ApiError).code.toUpperCase();
      } else {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          code = (data['code'] ?? '').toString().trim().toUpperCase();
        } else if (data is Map) {
          code = (data['code'] ?? '').toString().trim().toUpperCase();
        }
      }

      final status = e.response?.statusCode;
      final isUnauthorized = status == 401 ||
          code == 'AUTH_UNAUTHORIZED' ||
          code == 'AUTH_INVALID_TOKEN' ||
          code == 'AUTH_TOKEN_EXPIRED';

      if (isUnauthorized) {
        await session.clearSession();
        return;
      }

      if (status == 403 && code == 'MUST_CHANGE_PASSWORD') {
        await session.markMustChangePasswordRequired();
      }
    } catch (_) {
      // Keep current session for transient/network failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final schoolNameAsync = ref.watch(schoolNameProvider);

    return AppLoaderOverlay(
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppAppBar(
          centerTitle: true,
          showBack: false,
          hasDrawer: true,
          titleWidget: schoolNameAsync.when(
            data: (v) => Text(
              v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            loading: () => const Text('ASE School'),
            error: (_, __) => const Text('ASE School'),
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: () async {
                final ok = await showLogoutConfirmDialog(context);

                if (!ok) return;

                await withGlobalLoader(ref, () async {
                  try {
                    await ref.read(authControllerProvider.notifier).logout();
                  } catch (_) {
                    // even if API fails, controller clears local session
                  }
                  if (context.mounted) context.go(AppRoutes.login);
                });
              },
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: const DashboardScreen(),
      ),
    );
  }
}
