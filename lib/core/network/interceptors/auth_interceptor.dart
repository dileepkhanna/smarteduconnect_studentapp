// lib/core/network/interceptors/auth_interceptor.dart
import 'dart:async';

import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../config/endpoints.dart';
import '../../device/device_id.dart';
import '../response_unwrap.dart';
import '../../storage/prefs_store.dart';
import '../../storage/secure_store.dart';
import '../../session/session_manager.dart';

/// Adds `Authorization: Bearer <accessToken>` to secured requests
/// and auto-refreshes tokens on 401 using /auth/refresh.
///
/// Backend facts:
/// - Access JWT is sent in Authorization Bearer token
/// - Refresh uses body { refreshToken, deviceId }
/// - Refresh response returns: { accessToken, refreshToken, mustChangePassword, role }
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SessionManager sessionManager,
    required SecureStore secureStore,
    required PrefsStore prefsStore,
    required AppConfig config,
  })  : _dio = dio,
        _sessionManager = sessionManager,
        _secureStore = secureStore,
        _prefsStore = prefsStore,
        _config = config;

  final Dio _dio;
  final SessionManager _sessionManager;
  final SecureStore _secureStore;
  final PrefsStore _prefsStore;
  final AppConfig _config;

  Completer<void>? _refreshCompleter;

  // -----------------------
  // Request
  // -----------------------
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Allow manual opt-out from auth header
    final skipAuth = options.extra['skipAuth'] == true;
    if (skipAuth || _isPublicPath(options.path)) {
      handler.next(options);
      return;
    }

    var token = _sessionManager.accessToken;
    if (token == null || token.trim().isEmpty) {
      token = await _secureStore.getAccessToken();
    }
    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    handler.next(options);
  }

  // -----------------------
  // Error (401 -> refresh -> retry)
  // -----------------------
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final request = err.requestOptions;

    // Do not refresh for auth endpoints themselves
    if (_isPublicPath(request.path) || request.extra['skipAuth'] == true) {
      handler.next(err);
      return;
    }

    // Backend can return MUST_CHANGE_PASSWORD (403) if first-time setup isn't completed.
    if (statusCode == 403 && _isMustChangePasswordError(err)) {
      await _sessionManager.markMustChangePasswordRequired();
      handler.next(err);
      return;
    }

    // Treat unauthorized-like 403 as auth-expired flow too.
    final unauthorizedLike403 =
        statusCode == 403 && _isUnauthorizedLike403(err);

    // Only handle auth refresh logic here
    if (statusCode != 401 && !unauthorizedLike403) {
      handler.next(err);
      return;
    }

    // Prevent infinite loop
    if (request.extra['__retried'] == true) {
      await _safeClearSession();
      handler.next(err);
      return;
    }

    try {
      await _refreshTokensOnce();

      var newAccess = _sessionManager.accessToken;
      if (newAccess == null || newAccess.trim().isEmpty) {
        newAccess = await _secureStore.getAccessToken();
      }
      if (newAccess == null || newAccess.isEmpty) {
        await _safeClearSession();
        handler.next(err);
        return;
      }

      // Retry original request with new token
      final retryOptions = _cloneRequestOptions(request);
      retryOptions.extra['__retried'] = true;
      retryOptions.headers['Authorization'] = 'Bearer ${newAccess.trim()}';

      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (_) {
      // Refresh failed => logout
      await _safeClearSession();
      handler.next(err);
    }
  }

  // -----------------------
  // Refresh handling
  // -----------------------
  Future<void> _refreshTokensOnce() async {
    // If a refresh is already running, wait for it.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();

    try {
      var refreshToken = _sessionManager.refreshToken;
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        refreshToken = await _secureStore.getRefreshToken();
      }
      final deviceId = await DeviceId.getOrCreate(_prefsStore);

      if (refreshToken == null || refreshToken.trim().isEmpty) {
        throw StateError('Missing refresh token');
      }

      // Use a separate Dio without app interceptors to avoid recursion
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _config.apiBaseUrl,
          connectTimeout: Duration(milliseconds: _config.connectTimeoutMs),
          receiveTimeout: Duration(milliseconds: _config.receiveTimeoutMs),
          sendTimeout: Duration(milliseconds: _config.sendTimeoutMs),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final res = await refreshDio.post<Map<String, dynamic>>(
        Endpoints.refresh,
        data: {
          'refreshToken': refreshToken.trim(),
          'deviceId': deviceId.trim(),
        },
      );

      final data = unwrapAsMap(res.data);

      final accessToken = (data['accessToken'] as String?)?.trim() ?? '';
      final newRefreshToken = (data['refreshToken'] as String?)?.trim() ?? '';
      final role = (data['role'] as String?)?.trim();
      final mustChangePassword = data['mustChangePassword'] == true;

      if (accessToken.isEmpty || newRefreshToken.isEmpty) {
        throw StateError('Invalid refresh response');
      }

      // Update session (keep existing schoolCode/user info)
      await _sessionManager.applyLogin(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        role: role ?? (_sessionManager.role ?? ''),
        schoolCode: _sessionManager.schoolCode ??
            (await _secureStore.getSchoolCode()) ??
            '',
        mustChangePassword: mustChangePassword,
        userId: _sessionManager.userId,
        userName: _sessionManager.userName,
      );

      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  // -----------------------
  // Helpers
  // -----------------------
  bool _isPublicPath(String path) {
    final parsed = Uri.tryParse(path.trim());
    final p = (parsed?.path ?? path).trim();
    return p == Endpoints.login ||
        p == Endpoints.refresh ||
        p == Endpoints.logout ||
        p == Endpoints.forgotPassword ||
        p == Endpoints.verifyOtp ||
        p == Endpoints.resetPassword;
  }

  Future<void> _safeClearSession() async {
    try {
      await _sessionManager.clearSession();
    } catch (_) {
      _sessionManager.forceLocalLogout();
    }
  }

  RequestOptions _cloneRequestOptions(RequestOptions request) {
    return RequestOptions(
      path: request.path,
      method: request.method,
      baseUrl: request.baseUrl,
      data: request.data,
      queryParameters: Map<String, dynamic>.from(request.queryParameters),
      headers: Map<String, dynamic>.from(request.headers),
      extra: Map<String, dynamic>.from(request.extra),
      contentType: request.contentType,
      responseType: request.responseType,
      followRedirects: request.followRedirects,
      validateStatus: request.validateStatus,
      receiveDataWhenStatusError: request.receiveDataWhenStatusError,
      listFormat: request.listFormat,
      maxRedirects: request.maxRedirects,
      requestEncoder: request.requestEncoder,
      responseDecoder: request.responseDecoder,
      sendTimeout: request.sendTimeout,
      receiveTimeout: request.receiveTimeout,
      connectTimeout: request.connectTimeout,
      onReceiveProgress: request.onReceiveProgress,
      onSendProgress: request.onSendProgress,
      cancelToken: request.cancelToken,
    );
  }

  bool _isMustChangePasswordError(DioException err) {
    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['code']?.toString().trim().toUpperCase() ?? '') ==
          'MUST_CHANGE_PASSWORD';
    }
    if (data is Map) {
      final code = data['code']?.toString().trim().toUpperCase() ?? '';
      return code == 'MUST_CHANGE_PASSWORD';
    }
    return false;
  }

  bool _isUnauthorizedLike403(DioException err) {
    final data = err.response?.data;
    String code = '';
    String message = '';

    if (data is Map<String, dynamic>) {
      code = (data['code'] ?? '').toString().trim().toUpperCase();
      message = (data['message'] ?? '').toString().trim().toUpperCase();
    } else if (data is Map) {
      code = (data['code'] ?? '').toString().trim().toUpperCase();
      message = (data['message'] ?? '').toString().trim().toUpperCase();
    }

    if (code == 'AUTH_UNAUTHORIZED' ||
        code == 'AUTH_INVALID_TOKEN' ||
        code == 'AUTH_TOKEN_EXPIRED' ||
        code == 'AUTH_INVALID_CREDENTIALS') {
      return true;
    }

    if (message.contains('UNAUTHORIZED') ||
        message.contains('INVALID TOKEN') ||
        message.contains('TOKEN EXPIRED')) {
      return true;
    }

    return false;
  }
}
