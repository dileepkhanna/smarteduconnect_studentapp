import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback_overlay.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/logout_confirm_dialog.dart';
import '../widgets/password_strength_hint.dart';

class FirstTimeSetupScreen extends ConsumerStatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  ConsumerState<FirstTimeSetupScreen> createState() =>
      _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends ConsumerState<FirstTimeSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String? _validateStrongPassword(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'New password is required';
    if (s.length < 8) return 'Password must be at least 8 characters';

    final hasLower = RegExp(r'[a-z]').hasMatch(s);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(s);
    final hasDigit = RegExp(r'\d').hasMatch(s);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(s);

    if (!hasLower || !hasUpper || !hasDigit || !hasSymbol) {
      return 'Use lowercase, uppercase, number, and symbol';
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Confirm password is required';
    if (s != _newCtrl.text.trim()) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = ref.read(authControllerProvider.notifier);

    try {
      await withGlobalLoader(ref, () async {
        await auth.changePassword(
          oldPassword: _oldCtrl.text,
          newPassword: _newCtrl.text,
          confirmNewPassword: _confirmCtrl.text,
        );
      });

      if (!mounted) return;

      await AppFeedbackOverlay.showSuccess(
        context,
        message: 'Password changed successfully',
      );
      if (!mounted) return;

      context.go(AppRoutes.biometricSetup);
    } catch (e) {
      if (!mounted) return;
      final msg = auth.mapError(e);
      await AppFeedbackOverlay.showFail(context, message: msg);
      if (!mounted) return;
      _toast(msg);
    }
  }

  Future<void> _logout() async {
    final ok = await showLogoutConfirmDialog(context);
    if (!ok) return;

    final auth = ref.read(authControllerProvider.notifier);

    try {
      await withGlobalLoader(ref, () => auth.logout());
      if (!mounted) return;
      await AppFeedbackOverlay.showSuccess(context, message: 'Logged out');
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      final msg = auth.mapError(e);
      await AppFeedbackOverlay.showFail(context, message: msg);
      if (!mounted) return;
      _toast(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradientSoft,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'First-Time Setup',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'For security, you must change your temporary password before continuing.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Temporary / Old Password',
                              hint: 'Enter old password',
                              controller: _oldCtrl,
                              enabled: !isLoading,
                              obscureText: true,
                              enableObscureToggle: true,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty)
                                  return 'Old password is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'New Password',
                              hint: 'Enter new password',
                              controller: _newCtrl,
                              enabled: !isLoading,
                              obscureText: true,
                              enableObscureToggle: true,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.lock_reset_rounded,
                              validator: _validateStrongPassword,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                            PasswordStrengthHint(password: _newCtrl.text),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Confirm New Password',
                              hint: 'Re-enter new password',
                              controller: _confirmCtrl,
                              enabled: !isLoading,
                              obscureText: true,
                              enableObscureToggle: true,
                              textInputAction: TextInputAction.done,
                              prefixIcon: Icons.lock_rounded,
                              validator: _validateConfirmPassword,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Continue',
                              fullWidth: true,
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _submit,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tip: Enable biometrics on next step for faster secure login.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: isLoading ? null : _logout,
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
