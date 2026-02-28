// lib/features/auth/domain/usecases/verify_otp_usecase.dart
import '../auth_repository.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repo);

  final AuthRepository _repo;

  /// Returns true if OTP is valid.
  Future<bool> call({
    required String schoolCode,
    required String email,
    required String otp,
  }) {
    return _repo.verifyOtp(
      schoolCode: schoolCode,
      email: email,
      otp: otp,
    );
  }
}
