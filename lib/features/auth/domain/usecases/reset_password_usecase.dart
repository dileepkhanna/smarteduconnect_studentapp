// lib/features/auth/domain/usecases/reset_password_usecase.dart
import '../auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repo);

  final AuthRepository _repo;

  Future<void> call({
    required String schoolCode,
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return _repo.resetPassword(
      schoolCode: schoolCode,
      email: email,
      otp: otp,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
  }
}
