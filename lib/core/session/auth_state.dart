// lib/core/session/auth_state.dart

/// In-memory session snapshot.
/// Kept minimal and safe; sensitive tokens are stored in SecureStore.
class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.role,
    this.schoolCode,
    this.userId,
    this.userName,
    this.mustChangePassword = false,
  });

  final bool isAuthenticated;

  /// Backend role string (for this app must be STUDENT)
  final String? role;

  final String? schoolCode;
  final String? userId;
  final String? userName;

  /// Backend flag to enforce first-time setup / password reset
  final bool mustChangePassword;

  AuthState copyWith({
    bool? isAuthenticated,
    String? role,
    String? schoolCode,
    String? userId,
    String? userName,
    bool? mustChangePassword,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      schoolCode: schoolCode ?? this.schoolCode,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  static const unauthenticated = AuthState(isAuthenticated: false);

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, role: $role, schoolCode: $schoolCode, '
        'userId: $userId, mustChangePassword: $mustChangePassword)';
  }
}
