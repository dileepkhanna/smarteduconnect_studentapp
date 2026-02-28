// lib/features/notifications_feed/data/notifications_api.dart
import '../../../core/network/api_client.dart';
import '../../../core/network/response_unwrap.dart';

/// Notifications Feed API (Student / Parent)
///
/// ✅ Real Backend (Backend_Final_Code.zip):
/// - GET  /notifications
/// - POST /notifications/mark-read   { notificationId } OR { all:true }
///
/// Notes:
/// - Token-scoped: returns ONLY current user's notifications (school + user).
/// - Pagination: page, limit
/// - Filter: isRead (true/false), search
class NotificationsApi {
  NotificationsApi(this._api);

  final ApiClient _api;

  static const String _base = '/notifications';

  /// GET /notifications
  Future<Map<String, dynamic>> listMine({
    int page = 1,
    int limit = 50,
    bool? isRead, // true => read only, false => unread only, null => all
    String? search,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (isRead != null) 'isRead': isRead,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final res = await _api.get<Map<String, dynamic>>(
      _base,
      queryParameters: qp,
    );

    return unwrapAsMap(res.data);
  }

  /// POST /notifications/mark-read  { notificationId: "..."}
  Future<void> markOneRead(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return;

    try {
      await _api.post<Map<String, dynamic>>(
        '$_base/mark-read',
        data: <String, dynamic>{'notificationId': id},
      );
    } catch (_) {}
  }

  /// POST /notifications/mark-read  { all: true }
  Future<void> markAllRead() async {
    try {
      await _api.post<Map<String, dynamic>>(
        '$_base/mark-read',
        data: const <String, dynamic>{'all': true},
      );
    } catch (_) {}
  }

  // -----------------------
  // Helpers
  // -----------------------

  /// Safe parse int from dynamic.
  static int asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return fallback;
    return int.tryParse(s) ?? fallback;
  }
}
