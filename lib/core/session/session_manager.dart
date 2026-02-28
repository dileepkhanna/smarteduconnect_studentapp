// lib/core/session/session_manager.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../config/app_constants.dart';
import '../storage/prefs_store.dart';
import '../storage/secure_store.dart';
import 'auth_state.dart';

/// Holds the current authenticated session in memory and persists it securely.
///
/// IMPORTANT RULES:
/// - Tokens are stored only in SecureStore.
/// - Parent/Student role must be STUDENT (enforced in routing / feature guards).
/// - Auto logout on app close/background is triggered via LifecycleLogoutObserver.
class SessionManager extends ChangeNotifier {
  SessionManager({
    required SecureStore secureStore,
    required PrefsStore prefsStore,
    required AppConfig config,
  })  : _secureStore = secureStore,
        _prefsStore = prefsStore,
        _config = config;

  final SecureStore _secureStore;
  final PrefsStore _prefsStore;
  final AppConfig _config;

  AuthState _state = AuthState.unauthenticated;
  String? _accessTokenCache;
  String? _refreshTokenCache;

  bool _hydrated = false;
  bool _hydrating = false;

  // -----------------------
  // Public getters
  // -----------------------
  AuthState get state => _state;

  bool get isAuthenticated => _state.isAuthenticated;
  bool get mustChangePassword => _state.mustChangePassword;

  String? get role => _state.role;
  String? get schoolCode => _state.schoolCode;
  String? get userId => _state.userId;
  String? get userName => _state.userName;
  String? get accessToken => _accessTokenCache;
  String? get refreshToken => _refreshTokenCache;

  bool get isHydrated => _hydrated;
  bool get isHydrating => _hydrating;

  // -----------------------
  // Boot hydrate
  // -----------------------
  Future<void> hydrate() async {
    if (_hydrated || _hydrating) return;
    _hydrating = true;

    try {
      final accessToken = await _secureStore.getAccessToken();
      final refreshToken = await _secureStore.getRefreshToken();
      final role = await _secureStore.getRole();
      final schoolCode = await _secureStore.getSchoolCode();
      final userId = await _secureStore.getUserId();
      final userName = await _secureStore.getUserName();
      final mustChangePassword = await _secureStore.getMustChangePassword();
      _accessTokenCache = accessToken;
      _refreshTokenCache = refreshToken;

      final normalizedRole = (role ?? '').trim().toUpperCase();
      final hasSession = (accessToken != null && accessToken.isNotEmpty) &&
          (refreshToken != null && refreshToken.isNotEmpty) &&
          normalizedRole == AppConstants.roleStudent;

      if (!hasSession) {
        // Parent app is strictly STUDENT-role only. Clear any stale/invalid session.
        await _secureStore.clearSession();
        _state = AuthState.unauthenticated;
      } else {
        _state = AuthState(
          isAuthenticated: true,
          role: normalizedRole,
          schoolCode: schoolCode,
          userId: userId,
          userName: userName,
          mustChangePassword: mustChangePassword,
        );
      }
    } finally {
      _hydrated = true;
      _hydrating = false;
      notifyListeners();
    }
  }

  // -----------------------
  // Mutations after Auth API calls
  // -----------------------
  Future<void> applyLogin({
    required String accessToken,
    required String refreshToken,
    required String role,
    required bool mustChangePassword,
    String? schoolCode,
    String? userId,
    String? userName,
  }) async {
    final normalizedRole = role.trim().toUpperCase();
    if (normalizedRole != AppConstants.roleStudent) {
      throw StateError('Only STUDENT role is allowed in Parent App');
    }

    await _secureStore.setAccessToken(accessToken);
    await _secureStore.setRefreshToken(refreshToken);
    await _secureStore.setRole(normalizedRole);
    await _secureStore.setMustChangePassword(mustChangePassword);

    if (schoolCode != null) await _secureStore.setSchoolCode(schoolCode);
    if (userId != null) await _secureStore.setUserId(userId);
    if (userName != null) await _secureStore.setUserName(userName);
    _accessTokenCache = accessToken;
    _refreshTokenCache = refreshToken;

    _state = AuthState(
      isAuthenticated: true,
      role: normalizedRole,
      schoolCode: schoolCode ?? _state.schoolCode,
      userId: userId ?? _state.userId,
      userName: userName ?? _state.userName,
      mustChangePassword: mustChangePassword,
    );
    notifyListeners();
  }

  Future<void> applyRefresh({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStore.setAccessToken(accessToken);
    await _secureStore.setRefreshToken(refreshToken);
    _accessTokenCache = accessToken;
    _refreshTokenCache = refreshToken;
  }

  Future<void> clearMustChangePassword() async {
    await _secureStore.setMustChangePassword(false);
    _state = _state.copyWith(mustChangePassword: false);
    notifyListeners();
  }

  Future<void> markMustChangePasswordRequired() async {
    await _secureStore.setMustChangePassword(true);
    _state = _state.copyWith(mustChangePassword: true);
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    await _secureStore.setUserName(name);
    _state = _state.copyWith(userName: name);
    notifyListeners();
  }

  // -----------------------
  // Logout (Local only here)
  // Network logout is handled by AuthRepository, then it calls these.
  // -----------------------

  /// Clears tokens and session from device immediately (fire-and-forget).
  /// Used for auto logout on app close / background removal.
  ///
  /// ✅ FIX: changed return type from `Future<void>` to `void` to avoid analyzer error.
  void forceLocalLogout() {
    unawaited(_secureStore.clearSession());
    _accessTokenCache = null;
    _refreshTokenCache = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Preferred async version when you want to await storage clearing.
  Future<void> clearSession() async {
    await _secureStore.clearSession();
    _accessTokenCache = null;
    _refreshTokenCache = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // -----------------------
  // Biometrics flag (stored in prefs)
  // -----------------------
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _prefsStore.setBiometricsEnabled(enabled);
  }

  Future<bool> getBiometricsEnabled() => _prefsStore.getBiometricsEnabled();

  @override
  String toString() {
    return 'SessionManager(state=$_state, apiBase=${_config.apiBaseUrl})';
  }

  static String get requiredStudentRole => AppConstants.roleStudent;
}
