import 'dart:async';

import 'package:ase_parent_app/app/app_providers.dart';
import 'package:ase_parent_app/app/app_routes.dart';
import 'package:ase_parent_app/core/widgets/app_button.dart';
import 'package:ase_parent_app/core/widgets/app_card.dart';
import 'package:ase_parent_app/core/widgets/app_feedback_overlay.dart';
import 'package:ase_parent_app/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _form = GlobalKey<FormState>();
  final _otp = TextEditingController();

  Timer? _timer;
  int _resendSeconds = 0;

  String get _schoolCode =>
      GoRouterState.of(context).uri.queryParameters['schoolCode']?.trim() ?? '';
  String get _email =>
      GoRouterState.of(context).uri.queryParameters['email']?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 30]) {
    _timer?.cancel();
    setState(() => _resendSeconds = seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
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

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();

    if (_schoolCode.isEmpty || _email.isEmpty) {
      const msg = 'Missing School Code or Email. Please start again.';
      await AppFeedbackOverlay.showFail(context, message: msg);
      if (!mounted) return;
      _showError(msg);
      return;
    }

    final valid = _form.currentState?.validate() ?? false;
    if (!valid) return;

    final auth = ref.read(authControllerProvider.notifier);

    try {
      final ok = await withGlobalLoader(
        ref,
        () => auth.verifyOtp(
          schoolCode: _schoolCode,
          email: _email,
          otp: _otp.text.trim(),
        ),
      );

      if (!mounted) return;

      if (!ok) {
        const msg = 'Invalid OTP. Please try again.';
        await AppFeedbackOverlay.showFail(context, message: msg);
        if (!mounted) return;
        _showError(msg);
        return;
      }

      await AppFeedbackOverlay.showSuccess(
        context,
        message: 'OTP verified',
      );
      if (!mounted) return;

      await context.push(
        AppRoutes.withQuery(
          AppRoutes.resetPassword,
          {
            'schoolCode': _schoolCode,
            'email': _email,
            'otp': _otp.text.trim(),
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = auth.mapError(e);
      await AppFeedbackOverlay.showFail(context, message: msg);
      if (!mounted) return;
      _showError(msg);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    if (_schoolCode.isEmpty || _email.isEmpty) {
      const msg = 'Missing School Code or Email. Please start again.';
      await AppFeedbackOverlay.showFail(context, message: msg);
      if (!mounted) return;
      _showError(msg);
      return;
    }

    final auth = ref.read(authControllerProvider.notifier);

    try {
      await withGlobalLoader(
        ref,
        () => auth.forgotPassword(
          schoolCode: _schoolCode,
          email: _email,
        ),
      );

      if (!mounted) return;

      await AppFeedbackOverlay.showSuccess(
        context,
        message: 'OTP sent successfully',
      );
      if (!mounted) return;

      _startResendCooldown();
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
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
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
                        'Enter OTP',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We sent an OTP to $_email',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'OTP',
                        hint: '6-digit OTP',
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.password_rounded,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'OTP is required';
                          if (value.length < 4) return 'Enter valid OTP';
                          return null;
                        },
                        onSubmitted: (_) => _verify(),
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Verify OTP',
                        onPressed: state.isLoading ? null : _verify,
                        isLoading: state.isLoading,
                        leading: const Icon(Icons.verified_rounded, size: 18),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: (state.isLoading || _resendSeconds > 0)
                            ? null
                            : _resendOtp,
                        child: Text(
                          _resendSeconds > 0
                              ? 'Resend OTP in $_resendSeconds s'
                              : 'Resend OTP',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: state.isLoading ? null : () => context.pop(),
                        child: const Text('Back'),
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