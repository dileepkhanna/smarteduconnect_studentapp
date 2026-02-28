import 'package:dio/dio.dart';
import '../api_error.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      final response = err.response;
      final status = response?.statusCode;
      final data = response?.data;

      // Backend standard error shape
      if (data is Map<String, dynamic>) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: response,
            type: err.type,
            error: ApiError.fromJson(data, statusCode: status),
          ),
        );
      }

      final msg =
          err.message ??
          'Something went wrong. Please try again.';

      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: response,
          type: err.type,
          error: ApiError.fallback(
            message: msg,
            details: data,
            statusCode: status,
          ),
        ),
      );
    } catch (_) {
      return handler.next(err);
    }
  }
}
