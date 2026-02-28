// lib/core/config/app_constants.dart

class AppConstants {
  // App
  static const String appName = 'ASE School';

  // Storage keys (Prefs)
  static const String kPrefsDeviceId = 'device_id';
  static const String kPrefsLastSchoolCode = 'last_school_code';
  static const String kPrefsLastEmail = 'last_email';
  static const String kPrefsBiometricsEnabled = 'biometrics_enabled';
  static const String kPrefsFcmToken = 'fcm_token';

  // Storage keys (Secure)
  static const String kSecureAccessToken = 'access_token';
  static const String kSecureRefreshToken = 'refresh_token';
  static const String kSecureUserRole = 'user_role';
  static const String kSecureMustChangePassword = 'must_change_password';
  static const String kSecureSchoolCode = 'school_code';
  static const String kSecureUserId = 'user_id';
  static const String kSecureUserName = 'user_name';

  // API / backend
  // Backend returns: { code, message, details }
  static const String backendErrorCodeKey = 'code';
  static const String backendErrorMessageKey = 'message';
  static const String backendErrorDetailsKey = 'details';

  // UI
  static const Duration toastDuration = Duration(seconds: 2);
  static const Duration pageTransitionDuration = Duration(milliseconds: 220);

  // OTP
  static const int otpLength = 6;
  static const Duration otpResendCooldown = Duration(seconds: 45);

  // Attendance
  static const String attendancePresent = 'P';
  static const String attendanceAbsent = 'A';
  static const String attendanceHalfDay = 'H';

  // Circular Types (must match backend enum)
  static const List<String> circularTypes = <String>[
    'EXAM',
    'EVENT',
    'PTM',
    'HOLIDAY',
    'TRANSPORT',
    'GENERAL',
  ];

  // Role (this app must be student)
  static const String roleStudent = 'STUDENT';
}
