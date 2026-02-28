import 'package:dio/dio.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/network/api_client.dart';

/// Circulars API (Parent/Student)
///
/// Read-only endpoints:
/// - GET  /api/circulars?type=GENERAL&page=1&limit=20
/// - GET  /api/circulars/:id
/// - POST /api/circulars/mark-seen   { type }
/// - GET  /api/circulars/unseen/all
class CircularsApi {
  CircularsApi(this._api);

  final ApiClient _api;

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic v) => v is List ? v : const <dynamic>[];

  dynamic _unwrapData(dynamic payload) {
    final root = _asMap(payload);
    return root.containsKey('data') ? root['data'] : payload;
  }

  Future<List<dynamic>> getCircularsByType(
    String type, {
    String? search,
    bool? isActive,
    int? page,
    int? limit,
  }) async {
    final typeUpper = type.trim().toUpperCase();
    final endpoint = Endpoints.circulars(typeUpper);

    final qp = <String, dynamic>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (isActive != null) 'isActive': isActive,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };

    final endpointHasType = endpoint.contains('type=');
    if (!endpointHasType) {
      qp['type'] = typeUpper;
    }

    final Response<dynamic> res = await _api.get<dynamic>(
      endpoint,
      queryParameters: qp.isEmpty ? null : qp,
    );

    final payload = res.data;
    if (payload == null) return <dynamic>[];

    final unwrapped = _unwrapData(payload);
    final m = _asMap(unwrapped);

    final itemsRaw = m['items'];
    final items = _asList(itemsRaw)
        .where((e) => e is Map)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (items.isEmpty && unwrapped is List) {
      return unwrapped
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return items;
  }

  Future<Map<String, dynamic>> getCircularDetail(String id) async {
    final Response<dynamic> res = await _api.get<dynamic>(
      Endpoints.circularDetail(id),
    );

    final payload = res.data;
    if (payload == null) return <String, dynamic>{};

    final unwrapped = _unwrapData(payload);
    return _asMap(unwrapped);
  }

  Future<void> markSeen(String type) async {
    final typeUpper = type.trim().toUpperCase();
    try {
      await _api.post<dynamic>(
        Endpoints.circularMarkSeen(typeUpper),
        data: <String, dynamic>{'type': typeUpper},
      );
    } catch (_) {
      // Non-blocking side-effect.
    }
  }

  Future<Map<String, dynamic>> getUnseenCounts() async {
    final Response<dynamic> res = await _api.get<dynamic>(
      Endpoints.circularUnseenCounts,
    );

    final payload = res.data;
    if (payload == null) return <String, dynamic>{};

    final unwrapped = _unwrapData(payload);
    return _asMap(unwrapped);
  }
}
