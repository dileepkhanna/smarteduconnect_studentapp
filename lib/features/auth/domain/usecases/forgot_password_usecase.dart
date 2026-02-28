// lib/features/auth/domain/usecases/forgot_password_usecase.dart
import '../auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repo);

  final AuthRepository _repo;

  Future<void> call({
    required String schoolCode,
    required String email,
  }) {
    return _repo.forgotPassword(
      schoolCode: schoolCode,
      email: email,
    );
  }
}
