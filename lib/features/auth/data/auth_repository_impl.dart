// lib/features/auth/data/auth_repository_impl.dart
import '../../../core/device/device_id.dart';
import '../../../core/device/device_info.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/storage/prefs_store.dart';
import '../domain/auth_repository.dart';
import 'auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApi api,
    required SessionManager session,
    required PrefsStore prefs,
    required FcmService fcm,
  })  : _api = api,
        _session = session,
        _prefs = prefs,
        _fcm = fcm;

  final AuthApi _api;
  final SessionManager _session;
  final PrefsStore _prefs;
  final FcmService _fcm;

  @override
  Future<AuthLoginResult> login({
    required String schoolCode,
    required String email,
    required String password,
  }) async {
    final deviceId = await DeviceId.getOrCreate(_prefs);

    // Optional for backend: fcmToken + platform during login
    final fcmToken = await _fcm.getToken();
    final platform = (await DeviceInfo.platform()).toLowerCase(); // ANDROID -> android

    final data = await _api.login(
      schoolCode: schoolCode.trim(),
      email: email.trim(),
      password: password,
      deviceId: deviceId,
      fcmToken: fcmToken,
      platform: platform,
    );

    final accessToken = (data['accessToken'] as String?)?.trim() ?? '';
    final refreshToken = (data['refreshToken'] as String?)?.trim() ?? '';
    var role = (data['role'] as String?)?.trim() ?? '';
    var mustChangePassword = data['mustChangePassword'] == true;

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw StateError('Invalid login response from server.');
    }

    // Verify token identity with backend to avoid stale/wrong-role sessions.
    try {
      final me = await _api.getMeWithAccessToken(accessToken);
      final meRole = (me['role'] ?? '').toString().trim();
      final meMustChange = me['mustChangePassword'] == true;
      if (meRole.isNotEmpty) {
        role = meRole;
      }
      mustChangePassword = meMustChange;
    } catch (_) {
      // Keep login response values if /users/me is temporarily unreachable.
    }

    // Parent/Student app only
    if (role.toUpperCase() != 'STUDENT') {
      await _session.clearSession();
      throw StateError('This app is only for Students/Parents.');
    }

    await _session.applyLogin(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: role,
      mustChangePassword: mustChangePassword,
      schoolCode: schoolCode.trim(),
    );

    // Ensure token is synced (safe even if already sent in login)
    await _fcm.syncTokenToBackendIfPossible();

    return AuthLoginResult(
      role: role,
      mustChangePassword: mustChangePassword,
    );
  }

  @override
  Future<void> logout({bool allDevices = false}) async {
    final deviceId = await DeviceId.getOrCreate(_prefs);

    try {
      await _api.logout(deviceId: deviceId, allDevices: allDevices);
    } finally {
      // Always clear locally (auto-logout rule)
      await _session.clearSession();
    }
  }

  @override
  Future<void> forgotPassword({
    required String schoolCode,
    required String email,
  }) async {
    await _api.forgotPassword(
      schoolCode: schoolCode.trim(),
      email: email.trim(),
    );
  }

  @override
  Future<bool> verifyOtp({
    required String schoolCode,
    required String email,
    required String otp,
  }) {
    return _api.verifyOtp(
      schoolCode: schoolCode.trim(),
      email: email.trim(),
      otp: otp.trim(),
    );
  }

  @override
  Future<void> resetPassword({
    required String schoolCode,
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _api.resetPassword(
      schoolCode: schoolCode.trim(),
      email: email.trim(),
      otp: otp.trim(),
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
  }

  // ✅ FIX: Implement missing abstract method
  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _api.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );

    // Backend sets mustChangePassword=false; clear local flag too.
    await _session.clearMustChangePassword();
  }
}
