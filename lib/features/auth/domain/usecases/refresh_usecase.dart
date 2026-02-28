// lib/features/auth/domain/usecases/refresh_usecase.dart
import '../../../../core/session/session_manager.dart';

/// Used on app start (Splash) to restore session from SecureStore.
/// Returns true if a valid session exists on device.
class RefreshUseCase {
  const RefreshUseCase(this._session);

  final SessionManager _session;

  Future<bool> call() async {
    await _session.hydrate();
    return _session.isAuthenticated;
  }
}
