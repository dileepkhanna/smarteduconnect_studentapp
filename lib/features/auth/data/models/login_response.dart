// lib/features/auth/data/models/login_response.dart

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.mustChangePassword,
    required this.role,
  });

  /// JWT access token
  final String accessToken;

  /// JWT refresh token
  final String refreshToken;

  /// Backend flag for first-time setup
  final bool mustChangePassword;

  /// Role string from backend (e.g., STUDENT / TEACHER / PRINCIPAL / ASE_ADMIN)
  final String role;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: (json['accessToken'] as String?)?.trim() ?? '',
      refreshToken: (json['refreshToken'] as String?)?.trim() ?? '',
      mustChangePassword: json['mustChangePassword'] == true,
      role: (json['role'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'mustChangePassword': mustChangePassword,
      'role': role,
    };
  }

  String get roleUpper => role.trim().toUpperCase();
  bool get isStudent => roleUpper == 'STUDENT';
}
