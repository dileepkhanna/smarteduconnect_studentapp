// lib/features/splash/presentation/screens/splash_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/app_providers.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  late final ProviderSubscription _sessionSub;

  bool _minDelayPassed = false;
  bool _navigated = false;
  bool _showRetry = false;

  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
    );
    _c.forward();

    // Minimum splash visibility (looks premium + avoids instant flash)
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _minDelayPassed = true;
      _maybeNavigate(ref.read(sessionManagerProvider));
    });

    // Safety: show retry if hydration takes too long
    _retryTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() => _showRetry = true);
    });

    // Ensure hydration starts
    final session = ref.read(sessionManagerProvider);
    if (!session.isHydrated && !session.isHydrating) {
      unawaited(session.hydrate());
    }

    // Listen to session changes and navigate when ready
    _sessionSub = ref.listenManual(sessionManagerProvider, (prev, next) {
      _maybeNavigate(next);
    });

    // Also check once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeNavigate(ref.read(sessionManagerProvider));
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _sessionSub.close();
    _c.dispose();
    super.dispose();
  }

  void _maybeNavigate(dynamic session) {
    if (!mounted || _navigated) return;
    if (!_minDelayPassed) return;

    // Wait until hydration completes
    if (session.isHydrating == true || session.isHydrated != true) return;

    final bool loggedIn = session.isAuthenticated == true;
    final bool mustChangePassword = session.mustChangePassword == true;

    _navigated = true;

    if (!loggedIn) {
      context.go(AppRoutes.login);
      return;
    }

    if (mustChangePassword) {
      context.go(AppRoutes.firstTimeSetup);
      return;
    }

    context.go(AppRoutes.home);
  }

  Future<void> _retryHydrate() async {
    final session = ref.read(sessionManagerProvider);
    setState(() => _showRetry = false);
    try {
      await session.hydrate();
    } catch (_) {
      if (!mounted) return;
      setState(() => _showRetry = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Background glow blobs
              const Positioned(
                top: -90,
                right: -70,
                child: _GlowCircle(size: 240, opacity: 0.14),
              ),
              const Positioned(
                bottom: -120,
                left: -90,
                child: _GlowCircle(size: 290, opacity: 0.12),
              ),
              Positioned(
                top: 120,
                left: -70,
                child: Transform.rotate(
                  angle: -math.pi / 10,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(72),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 140,
                right: -80,
                child: Transform.rotate(
                  angle: math.pi / 9,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(84),
                    ),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glass card
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(AppSpacing.rXl),
                              border: Border.all(color: Colors.white.withOpacity(0.18)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Logo
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(AppSpacing.rLg),
                                    border: Border.all(color: Colors.white.withOpacity(0.20)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Image.asset(
                                      'assets/images/app_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.school_rounded,
                                        color: Colors.white,
                                        size: 46,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                Text(
                                  'ASE School',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.displaySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Parent / Student App',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.92),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                SizedBox(
                                  width: 92,
                                  height: 92,
                                  child: _LottieOrSpinner(
                                    assetPath: 'assets/lottie/loader.json',
                                    color: scheme.onPrimary.withOpacity(0.95),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Loading your school experience…',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.90),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                if (_showRetry) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _retryHydrate,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.18),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          Text(
                            '© ${DateTime.now().year} ASE Technologies',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.86),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Secure • Fast • Reliable',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withOpacity(0.82),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom progress
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      scheme.onPrimary.withOpacity(0.92),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _LottieOrSpinner extends StatelessWidget {
  const _LottieOrSpinner({required this.assetPath, required this.color});
  final String assetPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }
}
