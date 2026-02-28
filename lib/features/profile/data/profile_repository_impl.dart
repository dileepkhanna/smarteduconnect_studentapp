// lib/features/profile/data/profile_repository_impl.dart

import '../data/profile_api.dart';
import '../domain/profile_repository.dart';
import '../../auth/data/models/user_me_response.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final ProfileApi _api;

  @override
  Future<UserMeResponse> getMyProfile() {
    return _api.getMyProfile();
  }

  @override
  Future<UserMeResponse> updateMyProfile({
    String? phone,
    bool? biometricsEnabled,
  }) async {
    await _api.updateMyProfile(
      phone: phone,
      biometricsEnabled: biometricsEnabled,
    );

    // ✅ ensure UI always gets full backend shape
    return _api.getMyProfile();
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return _api.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
  }
}
