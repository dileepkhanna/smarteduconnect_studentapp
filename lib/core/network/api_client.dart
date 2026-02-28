import 'package:dio/dio.dart';

/// Thin Dio wrapper used across the app.
///
/// NOTE: Many feature APIs in this codebase call this client using `body:` and
/// `query:` named parameters. Dio's standard names are `data:` and
/// `queryParameters:`.
///
/// To keep the feature layer stable (and avoid touching many files), this
/// client supports both sets of parameter names.
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    /// Backward-compatible alias for [queryParameters].
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    final qp = query ?? queryParameters;

    return _dio.get<T>(
      path,
      queryParameters: qp,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    /// Backward-compatible alias for [data].
    dynamic body,
    dynamic data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final qp = query ?? queryParameters;
    final payload = body ?? data;

    return _dio.post<T>(
      path,
      data: payload,
      queryParameters: qp,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic body,
    dynamic data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final qp = query ?? queryParameters;
    final payload = body ?? data;

    return _dio.put<T>(
      path,
      data: payload,
      queryParameters: qp,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic body,
    dynamic data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final qp = query ?? queryParameters;
    final payload = body ?? data;

    return _dio.patch<T>(
      path,
      data: payload,
      queryParameters: qp,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic body,
    dynamic data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    final qp = query ?? queryParameters;
    final payload = body ?? data;

    return _dio.delete<T>(
      path,
      data: payload,
      queryParameters: qp,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
