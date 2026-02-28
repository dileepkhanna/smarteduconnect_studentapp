// lib/features/notifications_feed/data/notifications_repository_impl.dart
import '../data/notifications_api.dart';
import '../domain/notifications_repository.dart';

/// Notifications Repository Implementation (Student / Parent)
///
/// ✅ Backend:
/// - GET  /notifications
/// - POST /notifications/mark-read
///
/// UI expects:
/// - image (mapped from backend imageUrl)
/// - isSeen (mapped from backend isRead)
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsApi _api;

  NotificationsRepositoryImpl(this._api);

  Map<String, dynamic> _mapItem(Map<String, dynamic> n) {
    // Backend returns:
    // { id, title, body, imageUrl, data, isRead, createdAt, readAt }
    return <String, dynamic>{
      'id': n['id'],
      'title': n['title'],
      'body': n['body'],
      'image': n['imageUrl'], // UI expects `image`
      'data': n['data'],
      'isSeen': n['isRead'] == true, // UI expects `isSeen`
      'createdAt': n['createdAt'],
      'readAt': n['readAt'],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getMyNotifications({
    int page = 1,
    int limit = 50,
    bool? isSeen,
    String? search,
  }) async {
    // UI uses "seen", backend uses isRead
    final raw = await _api.listMine(
      page: page,
      limit: limit,
      isRead: isSeen, // same boolean meaning
      search: search,
    );

    final items = raw['items'];
    if (items is! List) return <Map<String, dynamic>>[];

    return items
        .whereType<Map>()
        .map((e) => _mapItem(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  @override
  Future<void> markNotificationSeen(String id) {
    return _api.markOneRead(id);
  }

  @override
  Future<void> markAllSeen() {
    return _api.markAllRead();
  }

  @override
  Future<int> getUnseenCount() async {
    try {
      // Efficient: ask for unread-only and read `total`
      final raw = await _api.listMine(
        page: 1,
        limit: 1,
        isRead: false,
        search: null,
      );

      return NotificationsApi.asInt(raw['total'], fallback: 0);
    } catch (_) {
      return 0;
    }
  }
}
