/// Mirrors backend error response format (NestJS filter):
/// { "code": "...", "message": "...", "details": ... }
///
/// Dio can also return non-map payloads, so this class is defensive.
class ApiError {
  const ApiError({
    this.code = 'UNKNOWN_ERROR',
    required this.message,
    this.details,
    this.statusCode,
  });

  final String code;
  final String message;
  final dynamic details;
  final int? statusCode;

  factory ApiError.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    return ApiError(
      code: (json['code'] ?? 'UNKNOWN_ERROR').toString(),
      message: (json['message'] ?? 'Something went wrong').toString(),
      details: json['details'],
      statusCode: statusCode,
    );
  }

  /// Parse backend response payload into ApiError.
  ///
  /// Typical backend payload:
  /// { "code": "...", "message": "...", "details": ... }
  factory ApiError.fromResponse({
    required int statusCode,
    required dynamic data,
  }) {
    if (data is Map<String, dynamic>) {
      return ApiError.fromJson(data, statusCode: statusCode);
    }

    // Sometimes `message` is a string/list in default Nest responses.
    if (data is Map) {
      final map = <String, dynamic>{};
      data.forEach((k, v) => map[k.toString()] = v);
      return ApiError.fromJson(map, statusCode: statusCode);
    }

    return ApiError(
      message: 'Something went wrong',
      details: data,
      statusCode: statusCode,
    );
  }

  factory ApiError.fallback({
    int? statusCode,
    String? message,
    String? code,
    dynamic details,
  }) {
    return ApiError(
      code: code ?? 'UNKNOWN_ERROR',
      message: message ?? 'Something went wrong',
      details: details,
      statusCode: statusCode,
    );
  }
}
