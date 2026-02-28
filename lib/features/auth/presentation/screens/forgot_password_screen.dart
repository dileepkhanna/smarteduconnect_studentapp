import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback_overlay.dart';
import '../../../../core/widgets/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();

  final _schoolCode = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _schoolCode.dispose();
    _email.dispose();
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final valid = _form.currentState?.validate() ?? false;
    if (!valid) return;

    final auth = ref.read(authControllerProvider.notifier);

    try {
      await withGlobalLoader(ref, () async {
        await auth.forgotPassword(
          schoolCode: _schoolCode.text,
          email: _email.text,
        );
      });

      if (!mounted) return;

      await AppFeedbackOverlay.showSuccess(
        context,
        message: 'OTP sent successfully',
      );
      if (!mounted) return;

      await context.push(
        AppRoutes.withQuery(
          AppRoutes.verifyOtp,
          {
            'schoolCode': _schoolCode.text.trim(),
            'email': _email.text.trim(),
          },
        ),
      );
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

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppCard(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Reset your password',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your School Code and Email. We will send an OTP to your email.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'School Code',
                        hint: 'e.g., ASE123',
                        controller: _schoolCode,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.school_rounded,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          UpperCaseTextFormatter(),
                        ],
                        validator: Validators.schoolCode,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Email',
                        hint: 'your@email.com',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.alternate_email_rounded,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Send OTP',
                        onPressed: state.isLoading ? null : _submit,
                        isLoading: state.isLoading,
                        leading: const Icon(Icons.send_rounded, size: 18),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: state.isLoading ? null : () => context.pop(),
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final upper = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}