// lib/features/auth/domain/auth_repository.dart

/// Domain contract for authentication flows.
/// NOTE: Email OTP is handled by backend using auth_otps + Nodemailer SMTP.
/// Firebase is ONLY for FCM push notifications (not OTP).
abstract class AuthRepository {
  Future<AuthLoginResult> login({
    required String schoolCode,
    required String email,
    required String password,
  });

  Future<void> logout({bool allDevices = false});

  Future<void> forgotPassword({
    required String schoolCode,
    required String email,
  });

  /// Returns true when OTP is valid
  Future<bool> verifyOtp({
    required String schoolCode,
    required String email,
    required String otp,
  });

  Future<void> resetPassword({
    required String schoolCode,
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  });

  /// Used for first-time setup / change password while logged in
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  });
}

/// Result after login for routing decisions.
class AuthLoginResult {
  const AuthLoginResult({
    required this.role,
    required this.mustChangePassword,
  });

  final String role; // e.g. "STUDENT"
  final bool mustChangePassword;
}
