import 'package:dio/dio.dart';

/// Retries once on a fallback API base URL when the primary host is unreachable.
class BaseUrlFailoverInterceptor extends Interceptor {
  BaseUrlFailoverInterceptor({
    required this.dio,
    required this.fallbackApiBaseUrl,
  });

  final Dio dio;
  final String? fallbackApiBaseUrl;

  static const _retryKey = '__baseUrlFailoverRetried';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryOptions = _cloneWithFallback(
      err.requestOptions,
      _normalize(fallbackApiBaseUrl!),
    );

    try {
      final response = await dio.fetch<dynamic>(retryOptions);
      // Persist fallback for future requests in this session.
      dio.options.baseUrl = _normalize(fallbackApiBaseUrl!);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    final fallback = fallbackApiBaseUrl?.trim() ?? '';
    if (fallback.isEmpty) return false;

    final request = err.requestOptions;
    if (request.extra[_retryKey] == true) return false;
    if (request.extra['skipBaseUrlFailover'] == true) return false;

    // Skip absolute URLs pointing to external domains.
    final parsed = Uri.tryParse(request.path);
    if (parsed != null && parsed.hasScheme) return false;

    final isConnectionFailure =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.unknown;
    if (!isConnectionFailure) return false;

    if (_normalize(request.baseUrl) == _normalize(fallback)) return false;

    return true;
  }

  RequestOptions _cloneWithFallback(RequestOptions request, String baseUrl) {
    final extra = Map<String, dynamic>.from(request.extra);
    extra[_retryKey] = true;

    return RequestOptions(
      path: request.path,
      method: request.method,
      baseUrl: baseUrl,
      data: request.data,
      queryParameters: Map<String, dynamic>.from(request.queryParameters),
      headers: Map<String, dynamic>.from(request.headers),
      extra: extra,
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

  String _normalize(String value) {
    var v = value.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}
