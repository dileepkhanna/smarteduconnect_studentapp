// lib/features/profile/domain/profile_repository.dart

import '../../auth/data/models/user_me_response.dart';

abstract class ProfileRepository {
  Future<UserMeResponse> getMyProfile();

  /// We re-fetch GET /users/me after PATCH because PATCH returns partial fields.
  Future<UserMeResponse> updateMyProfile({
    String? phone,
    bool? biometricsEnabled,
  });

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  });
}
