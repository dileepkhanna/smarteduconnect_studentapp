// lib/features/auth/domain/usecases/change_password_usecase.dart
import '../auth_repository.dart';

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repo);

  final AuthRepository _repo;

  Future<void> call({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return _repo.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
  }
}
