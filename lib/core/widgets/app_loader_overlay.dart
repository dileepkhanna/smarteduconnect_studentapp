// lib/core/widgets/app_loader_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../app/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Global center circular loading overlay using Lottie (.json).
///
/// It listens to `globalLoadingCountProvider`.
/// If count > 0, show overlay.
/// Use helper: `withGlobalLoader(ref, () async { ... })`
/// to automatically increment/decrement.
class AppLoaderOverlay extends ConsumerWidget {
  const AppLoaderOverlay({
    super.key,
    required this.child,
    this.lottieAsset = 'assets/lottie/loader.json',
  });

  final Widget child;
  final String lottieAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(globalLoadingCountProvider);

    return Stack(
      children: [
        child,
        if (count > 0) ...[
          // Dim background
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
            ),
          ),
          // Center card
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.rXl),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: Lottie.asset(
                        lottieAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Loading…',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandTeal,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
