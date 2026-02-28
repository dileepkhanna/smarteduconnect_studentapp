// lib/features/auth/domain/usecases/logout_usecase.dart
import '../auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repo);

  final AuthRepository _repo;

  Future<void> call({bool allDevices = false}) {
    return _repo.logout(allDevices: allDevices);
  }
}
