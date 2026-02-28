// lib/core/session/lifecycle_logout_observer.dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';

/// Enforces: Auto Logout on App Close / Background removal.
///
/// Requirement: "Whenever the app is closed, force stopped, or removed from background,
/// the user must be automatically logged out."
///
/// We schedule logout on:
/// - hidden (app no longer visible)
/// - detached (app closing; immediate)
///
/// NOTE:
/// `paused` can happen during transient flows (permissions/pickers), so we avoid
/// instant logout there to prevent accidental token clears.
class LifecycleLogoutObserver extends WidgetsBindingObserver {
  LifecycleLogoutObserver({required ProviderContainer container})
      : _container = container;

  final ProviderContainer _container;
  Timer? _logoutTimer;
  static const Duration _backgroundLogoutDelay = Duration(minutes: 2);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _cancelLogoutTimer();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // no-op (avoid accidental logout on transient transitions)
        break;
      case AppLifecycleState.hidden:
        _scheduleLogout(forceNow: false);
        break;
      case AppLifecycleState.detached:
        _scheduleLogout(forceNow: true);
        break;
    }
  }

  void _scheduleLogout({required bool forceNow}) {
    final session = _container.read(sessionManagerProvider);
    if (!session.isAuthenticated) return;

    if (forceNow) {
      _cancelLogoutTimer();
      session.forceLocalLogout();
      return;
    }

    _cancelLogoutTimer();
    _logoutTimer = Timer(_backgroundLogoutDelay, () {
      final s = _container.read(sessionManagerProvider);
      if (s.isAuthenticated) s.forceLocalLogout();
    });
  }

  void _cancelLogoutTimer() {
    _logoutTimer?.cancel();
    _logoutTimer = null;
  }
}
