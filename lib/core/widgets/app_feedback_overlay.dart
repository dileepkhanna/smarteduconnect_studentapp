import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Global success/fail Lottie overlay for important app actions.
///
/// Required assets:
/// - assets/lottie/success.json
/// - assets/lottie/fail.json
class AppFeedbackOverlay {
  static OverlayEntry? _entry;
  static int _token = 0;

  static Future<void> showSuccess(
    BuildContext context, {
    String message = 'Success',
    Duration duration = const Duration(milliseconds: 1100),
  }) {
    return _show(
      context,
      assetPath: 'assets/lottie/success.json',
      message: message,
      duration: duration,
      dismissible: false,
    );
  }

  static Future<void> showFail(
    BuildContext context, {
    String message = 'Failed',
    Duration duration = const Duration(milliseconds: 1300),
  }) {
    return _show(
      context,
      assetPath: 'assets/lottie/fail.json',
      message: message,
      duration: duration,
      dismissible: true,
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String assetPath,
    required String message,
    required Duration duration,
    required bool dismissible,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final myToken = ++_token;
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => _FeedbackLayer(
        assetPath: assetPath,
        message: message,
        dismissible: dismissible,
      ),
    );
    overlay.insert(_entry!);

    await Future<void>.delayed(duration);
    if (myToken == _token) {
      hide();
    }
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _FeedbackLayer extends StatelessWidget {
  const _FeedbackLayer({
    required this.assetPath,
    required this.message,
    required this.dismissible,
  });

  final String assetPath;
  final String message;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.black.withOpacity(0.35),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: dismissible ? AppFeedbackOverlay.hide : null,
        child: Center(
          child: Container(
            width: 196,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 74,
                  width: 74,
                  child: Lottie.asset(assetPath, repeat: false, fit: BoxFit.contain),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withOpacity(0.82),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
