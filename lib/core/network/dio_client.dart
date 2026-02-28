// lib/core/network/dio_client.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../storage/prefs_store.dart';
import '../storage/secure_store.dart';
import '../session/session_manager.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/base_url_failover_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class DioClient {
  DioClient({
    required AppConfig config,
    required SecureStore secureStore,
    required SessionManager sessionManager,
    PrefsStore? prefsStore,
  })  : _config = config,
        _secureStore = secureStore,
        _sessionManager = sessionManager,
        _prefsStore = prefsStore ?? PrefsStore() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.apiBaseUrl,
        connectTimeout: Duration(milliseconds: _config.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: _config.receiveTimeoutMs),
        sendTimeout: Duration(milliseconds: _config.sendTimeoutMs),
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _attachInterceptors();
    _sessionManager.addListener(_syncDefaultAuthHeader);
    _syncDefaultAuthHeader();
  }

  final AppConfig _config;
  final SecureStore _secureStore;
  final SessionManager _sessionManager;
  final PrefsStore _prefsStore;

  late final Dio _dio;

  Dio get dio => _dio;

  void _attachInterceptors() {
    // Order matters:
    // - AuthInterceptor must see 401 first to refresh tokens.
    // - ErrorInterceptor should convert only after auth/base-url retries are exhausted.
    // - Logger is added last so request logs include final headers after auth injection.
    _dio.interceptors.addAll([
      BaseUrlFailoverInterceptor(
        dio: _dio,
        fallbackApiBaseUrl: _config.fallbackApiBaseUrl,
      ),
      AuthInterceptor(
        dio: _dio,
        sessionManager: _sessionManager,
        secureStore: _secureStore,
        prefsStore: _prefsStore,
        config: _config,
      ),
      ErrorInterceptor(),
      if (_config.enableNetworkLogs) _PrettyLogInterceptor(),
    ]);
  }

  void _syncDefaultAuthHeader() {
    final token = _sessionManager.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}

/// Simple, clean network logs (only in dev).
class _PrettyLogInterceptor extends Interceptor {
  final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = Map<String, dynamic>.from(options.headers);
    final auth = headers['Authorization'] ?? headers['authorization'];
    if (auth is String && auth.trim().isNotEmpty) {
      headers['Authorization'] = _maskBearer(auth);
      headers.remove('authorization');
    }

    final sb = StringBuffer()
      ..writeln('REQ ${options.method} ${options.baseUrl}${options.path}')
      ..writeln('Headers: ${_safeJson(headers)}');

    if (options.queryParameters.isNotEmpty) {
      sb.writeln('Query: ${_safeJson(options.queryParameters)}');
    }
    if (options.data != null) {
      sb.writeln('Body: ${_safeJson(options.data)}');
    }

    _log.i(sb.toString());
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final sb = StringBuffer()
      ..writeln(
        'RES ${response.statusCode} '
        '${response.requestOptions.method} '
        '${response.requestOptions.baseUrl}${response.requestOptions.path}',
      )
      ..writeln('Response: ${_safeJson(response.data)}');

    _log.i(sb.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sb = StringBuffer()
      ..writeln(
        'ERR ${err.response?.statusCode ?? 'NO_STATUS'} '
        '${err.requestOptions.method} '
        '${err.requestOptions.baseUrl}${err.requestOptions.path}',
      )
      ..writeln('Error: ${err.message}')
      ..writeln('Data: ${_safeJson(err.response?.data)}');

    _log.w(sb.toString());
    handler.next(err);
  }

  String _safeJson(Object? data) {
    try {
      if (data == null) return 'null';
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  String _maskBearer(String value) {
    const prefix = 'Bearer ';
    final v = value.trim();
    if (!v.startsWith(prefix)) return '***';

    final token = v.substring(prefix.length);
    if (token.length <= 16) return '$prefix***';

    final head = token.substring(0, 10);
    final tail = token.substring(token.length - 6);
    return '$prefix$head...$tail';
  }
}
