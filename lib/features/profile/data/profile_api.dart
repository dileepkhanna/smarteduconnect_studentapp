// lib/features/profile/data/profile_api.dart

import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';
import '../../auth/data/models/user_me_response.dart';

class ProfileApi {
  ProfileApi(this._api);

  final ApiClient _api;

  /// GET /users/me
  Future<UserMeResponse> getMyProfile() async {
    try {
      final dynamic res = await _api.get<dynamic>(Endpoints.userMe);
      final data = unwrapAsMap(res);
      return UserMeResponse.fromJson(data);
    } catch (_) {
      return UserMeResponse.fromJson(const <String, dynamic>{});
    }
  }

  /// PATCH /users/me (backend returns partial payload)
  Future<void> updateMyProfile({
    String? phone,
    bool? biometricsEnabled,
  }) async {
    await _api.patch<dynamic>(
      Endpoints.userMe,
      body: <String, dynamic>{
        if (phone != null) 'phone': phone,
        if (biometricsEnabled != null) 'biometricsEnabled': biometricsEnabled,
      },
    );
  }

  /// POST /users/me/change-password (alias exists in backend)
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _api.post<dynamic>(
      Endpoints.userChangePassword,
      body: <String, dynamic>{
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }
}
