// lib/core/widgets/secure_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenshot_callback_plus/flutter_screenshot_callback_plus.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

/// Wrap any screen with [SecureScreen] to enforce screenshot restriction.
///
/// - **Android**: Uses `FLAG_SECURE` to prevent screenshots/screen recording.
/// - **iOS**: Full prevention isn't possible from Flutter; we *detect* screenshot
///   events and show a warning message.
///
/// Notes:
/// - Screenshot detection only works on **real devices**, not simulators.
/// - Some Android OEMs may behave differently; we keep both FLAG_SECURE and
///   screenshot detection enabled for reliability.
/// - On Web: no-op (still compiles).
class SecureScreen extends StatefulWidget {
  const SecureScreen({
    super.key,
    required this.child,
    this.allowScreenshots = true,
    this.blockMessage = 'You are allowed to take a screenshot only on this page.',
  });

  final Widget child;
  final bool allowScreenshots;
  final String blockMessage;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen>
    with WidgetsBindingObserver
    implements IScreenshotCallback {
  ScreenshotCallback? _callback;
  bool _callbackStarted = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyPolicy();
  }

  @override
  void didUpdateWidget(covariant SecureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allowScreenshots != widget.allowScreenshots ||
        oldWidget.blockMessage != widget.blockMessage) {
      _applyPolicy();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScreenshotListener();
    _clearAndroidSecureFlag();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.allowScreenshots) return;

    // Helps on some devices where screenshot gestures can affect lifecycle.
    if (state == AppLifecycleState.resumed) {
      _applyAndroidSecureFlag();
      _startScreenshotListener();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopScreenshotListener();
    }
  }

  Future<void> _applyPolicy() async {
    if (kIsWeb) return;

    if (widget.allowScreenshots) {
      await _clearAndroidSecureFlag();
      _stopScreenshotListener();
      return;
    }

    await _applyAndroidSecureFlag();
    _startScreenshotListener();
  }

  Future<void> _applyAndroidSecureFlag() async {
    if (!_isAndroid) return;
    try {
      await FlutterWindowManagerPlus.addFlags(
        FlutterWindowManagerPlus.FLAG_SECURE,
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> _clearAndroidSecureFlag() async {
    if (!_isAndroid) return;
    try {
      await FlutterWindowManagerPlus.clearFlags(
        FlutterWindowManagerPlus.FLAG_SECURE,
      );
    } catch (_) {
      // ignore
    }
  }

  void _startScreenshotListener() {
    if (kIsWeb) return;

    // Only meaningful on mobile platforms
    if (!_isAndroid && !_isApple) return;

    if (_callbackStarted) return;

    _callback ??= ScreenshotCallback();
    try {
      _callback!.setInterfaceScreenshotCallback(this);
      _callback!.startScreenshot();
      _callbackStarted = true;
    } catch (_) {
      _callbackStarted = false;
    }
  }

  void _stopScreenshotListener() {
    if (!_callbackStarted || _callback == null) return;
    try {
      _callback!.stopScreenshot();
    } catch (_) {
      // ignore
    } finally {
      _callbackStarted = false;
    }
  }

  @override
  void screenshotCallback(String data) {
    if (!mounted) return;
    if (widget.allowScreenshots) return;

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.blockMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void deniedPermission() {
    // Android: permission denied for screenshot detection.
    // We still rely on FLAG_SECURE on Android.
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
