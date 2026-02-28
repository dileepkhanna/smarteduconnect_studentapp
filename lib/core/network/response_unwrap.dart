import 'package:dio/dio.dart';

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) return List<dynamic>.from(value);
  return <dynamic>[];
}

dynamic unwrapEnvelope(dynamic raw) {
  final payload = raw is Response ? raw.data : raw;
  final map = asMap(payload);
  if (map.containsKey('success') && map.containsKey('data')) {
    return map['data'];
  }
  return payload;
}

Map<String, dynamic> unwrapAsMap(dynamic raw) {
  return asMap(unwrapEnvelope(raw));
}

List<dynamic> unwrapAsList(dynamic raw) {
  final data = unwrapEnvelope(raw);
  if (data is List) return List<dynamic>.from(data);
  if (data is Map) {
    if (data['items'] is List) return List<dynamic>.from(data['items'] as List);
    if (data['data'] is List) return List<dynamic>.from(data['data'] as List);
  }
  return <dynamic>[];
}
