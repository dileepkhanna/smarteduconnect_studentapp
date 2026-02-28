import 'api_error.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiError? error;

  ApiException(this.message, {this.statusCode, this.error});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
