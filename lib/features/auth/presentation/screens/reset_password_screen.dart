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
import '../widgets/password_strength_hint.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.schoolCode,
    required this.email,
    required this.otp,
  });

  final String schoolCode;
  final String email;
  final String otp;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
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

  Future<void> _onSubmit() async {
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

      await AppFeedbackOverlay.showSuccess(
        context,
        message: 'Password reset successful',
      );
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
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;

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
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: isLoading ? null : () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reset Password',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create a new strong password for your account.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 14),
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
                            const SizedBox(height: 10),
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
                              onSubmitted: (_) => _onSubmit(),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Reset Password',
                              fullWidth: true,
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _onSubmit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'School: ${widget.schoolCode.toUpperCase()} • ${widget.email}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
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