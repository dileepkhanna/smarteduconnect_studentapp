// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback_overlay.dart';
import '../../../../core/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _schoolCodeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _schoolCodeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final auth = ref.read(authControllerProvider.notifier);
    final lastSchool = await auth.getLastSchoolCode();
    final lastEmail = await auth.getLastEmail();

    if (!mounted) return;

    if ((_schoolCodeCtrl.text.trim().isEmpty) &&
        (lastSchool?.trim().isNotEmpty == true)) {
      _schoolCodeCtrl.text = lastSchool!.trim().toUpperCase();
    }
    if ((_emailCtrl.text.trim().isEmpty) &&
        (lastEmail?.trim().isNotEmpty == true)) {
      _emailCtrl.text = lastEmail!.trim().toLowerCase();
    }
  }

  void _showError(String msg) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = ref.read(authControllerProvider.notifier);

    try {
      final res = await withGlobalLoader(
        ref,
        () => auth.login(
          schoolCode: _schoolCodeCtrl.text.trim().toUpperCase(),
          email: _emailCtrl.text.trim().toLowerCase(),
          password: _passwordCtrl.text,
        ),
      );

      if (!mounted) return;

      await AppFeedbackOverlay.showSuccess(
        context,
        message: 'Login successful',
      );
      if (!mounted) return;

      if (res.mustChangePassword) {
        context.go(AppRoutes.firstTimeSetup);
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = auth.mapError(e);
      await AppFeedbackOverlay.showFail(context, message: msg);
      if (!mounted) return;
      _showError(msg);
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(),
                    const SizedBox(height: 14),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Login',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use School Code + Email + Password',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            AppTextField(
                              label: 'School Code',
                              hint: 'e.g. ASE123',
                              controller: _schoolCodeCtrl,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              validator: Validators.schoolCode,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                UpperCaseTextFormatter(),
                              ],
                              prefixIcon: Icons.school_rounded,
                            ),
                            const SizedBox(height: 12),

                            AppTextField(
                              label: 'Email',
                              hint: 'your@email.com',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              prefixIcon: Icons.alternate_email_rounded,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                            ),
                            const SizedBox(height: 12),

                            AppTextField(
                              label: 'Password',
                              hint: '••••••••',
                              controller: _passwordCtrl,
                              keyboardType: TextInputType.visiblePassword,
                              textInputAction: TextInputAction.done,
                              validator: Validators.password,
                              obscureText: _obscure,
                              prefixIcon: Icons.lock_rounded,
                              autofillHints: const [AutofillHints.password],
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                ),
                                tooltip: _obscure ? 'Show password' : 'Hide password',
                              ),
                              onSubmitted: (_) => _onLogin(),
                            ),
                            const SizedBox(height: 14),

                            AppButton(
                              label: 'Login',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _onLogin,
                              fullWidth: true,
                            ),
                            const SizedBox(height: 10),

                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.push(AppRoutes.forgotPassword),
                              child: const Text('Forgot Password?'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Footer(),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha((0.92 * 255).round()),
        borderRadius: BorderRadius.circular(AppSpacing.rXl),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.rLg),
              gradient: AppColors.brandGradient,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASE School',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Parent / Student App',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '© ${DateTime.now().year} ASE Technologies',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

/// Forces uppercase on School Code input.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
