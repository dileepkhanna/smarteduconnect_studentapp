import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/app_providers.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback_overlay.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  final _localAuth = LocalAuthentication();

  bool _supported = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final session = ref.read(sessionManagerProvider);

    bool supported;
    try {
      supported = await _localAuth.isDeviceSupported() && await _localAuth.canCheckBiometrics;
    } catch (_) {
      supported = false;
    }

    final enabled = await session.getBiometricsEnabled();

    if (!mounted) return;
    setState(() {
      _supported = supported;
      _enabled = enabled;
      _loading = false;
    });
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

  Future<void> _toggle(bool value) async {
    if (!_supported) {
      const msg = 'Biometrics not supported on this device.';
      await AppFeedbackOverlay.showFail(context, message: msg);
      if (!mounted) return;
      _toast(msg);
      return;
    }

    try {
      if (value) {
        final ok = await _localAuth.authenticate(
          localizedReason: 'Enable biometric login for quick secure access.',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (!ok) return;
      }

      final session = ref.read(sessionManagerProvider);
      await withGlobalLoader(ref, () => session.setBiometricsEnabled(value));

      if (!mounted) return;
      setState(() => _enabled = value);

      await AppFeedbackOverlay.showSuccess(
        context,
        message: value ? 'Biometrics enabled' : 'Biometrics disabled',
      );
    } catch (_) {
      if (!mounted) return;
      const msg = 'Biometric verification failed.';
      await AppFeedbackOverlay.showFail(context, message: msg);
      if (!mounted) return;
      _toast(msg);
    }
  }

  void _continue() {
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
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
                      'Biometric Setup',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enable fingerprint / face unlock for faster secure login.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: AppColors.brandGradient,
                                      ),
                                      child: const Icon(
                                        Icons.fingerprint_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Biometric Login',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontWeight: FontWeight.w800),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _supported
                                                ? 'Use device biometrics to unlock the app.'
                                                : 'Not available on this device.',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _enabled,
                                      onChanged: _supported ? _toggle : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                AppButton(
                                  label: 'Continue',
                                  onPressed: _continue,
                                  fullWidth: true,
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: _continue,
                                  child: const Text('Skip for now'),
                                ),
                              ],
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