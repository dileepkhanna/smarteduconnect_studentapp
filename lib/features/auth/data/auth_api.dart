// lib/features/auth/data/auth_api.dart
import 'package:dio/dio.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';

class AuthApi {
  AuthApi(this._api);

  final ApiClient _api;

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  /// ✅ Backend sometimes returns: { success: true, data: {...} }
  /// This helper returns the inner `data` map if present, otherwise returns the root map.
  Map<String, dynamic> _unwrapData(dynamic raw) {
    final root = _asMap(raw);
    final inner = root['data'];
    if (inner is Map<String, dynamic>) return inner;
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return root;
  }

  Future<Map<String, dynamic>> login({
    required String schoolCode,
    required String email,
    required String password,
    required String deviceId,
    String? fcmToken,
    String? platform,
    double? lat,
    double? lng,
  }) async {
    final res = await _api.post<dynamic>(
      Endpoints.login,
      data: <String, dynamic>{
        'schoolCode': schoolCode.trim().toUpperCase(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'deviceId': deviceId.trim(),
        if (fcmToken != null && fcmToken.trim().isNotEmpty)
          'fcmToken': fcmToken.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim().toLowerCase(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
      options: Options(extra: const {'skipAuth': true}),
    );

    // ✅ Return only actual payload (tokens etc.)
    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    final res = await _api.post<dynamic>(
      Endpoints.refresh,
      data: <String, dynamic>{
        'refreshToken': refreshToken.trim(),
        'deviceId': deviceId.trim(),
      },
      options: Options(extra: const {'skipAuth': true}),
    );

    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> logout({
    required String deviceId,
    bool allDevices = false,
  }) async {
    final res = await _api.post<dynamic>(
      Endpoints.logout,
      data: <String, dynamic>{
        'deviceId': deviceId.trim(),
        if (allDevices) 'allDevices': true,
      },
    );

    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String schoolCode,
    required String email,
  }) async {
    final res = await _api.post<dynamic>(
      Endpoints.forgotPassword,
      data: <String, dynamic>{
        'schoolCode': schoolCode.trim().toUpperCase(),
        'email': email.trim().toLowerCase(),
      },
      options: Options(extra: const {'skipAuth': true}),
    );

    return _unwrapData(res.data);
  }

  Future<bool> verifyOtp({
    required String schoolCode,
    required String email,
    required String otp,
  }) async {
    final res = await _api.post<dynamic>(
      Endpoints.verifyOtp,
      data: <String, dynamic>{
        'schoolCode': schoolCode.trim().toUpperCase(),
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      },
      options: Options(extra: const {'skipAuth': true}),
    );

    // verifyOtp may return { valid: true } OR { success:true, data:{ valid:true } }
    final payload = _unwrapData(res.data);
    return payload['valid'] == true;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String schoolCode,
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final res = await _api.post<dynamic>(
      Endpoints.resetPassword,
      data: <String, dynamic>{
        'schoolCode': schoolCode.trim().toUpperCase(),
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
      options: Options(extra: const {'skipAuth': true}),
    );

    return _unwrapData(res.data);
  }

  /// ✅ First-time setup / in-session password change
  /// Backend supports:
  /// - POST /users/me/change-password
  /// - POST /users/change-password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final res = await _api.post<dynamic>(
      Endpoints.changePassword,
      data: <String, dynamic>{
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );

    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String fcmToken,
    String? platform,
  }) async {
    final res = await _api.post<dynamic>(
      Endpoints.registerDevice,
      data: <String, dynamic>{
        'deviceId': deviceId.trim(),
        'fcmToken': fcmToken.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim().toLowerCase(),
      },
    );

    return _unwrapData(res.data);
  }

  /// Validate a freshly received token against backend identity.
  /// Used to guarantee Parent app keeps only STUDENT sessions.
  Future<Map<String, dynamic>> getMeWithAccessToken(String accessToken) async {
    final res = await _api.get<dynamic>(
      Endpoints.userMe,
      options: Options(
        headers: <String, dynamic>{
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
        // We are sending explicit auth header.
        extra: const {'skipAuth': true},
      ),
    );
    return _unwrapData(res.data);
  }
}
