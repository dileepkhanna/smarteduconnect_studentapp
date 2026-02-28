// lib/features/auth/domain/usecases/login_usecase.dart
import '../auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repo);

  final AuthRepository _repo;

  Future<AuthLoginResult> call({
    required String schoolCode,
    required String email,
    required String password,
  }) {
    return _repo.login(
      schoolCode: schoolCode,
      email: email,
      password: password,
    );
  }
}
