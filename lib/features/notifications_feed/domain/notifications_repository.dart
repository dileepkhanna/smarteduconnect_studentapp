// lib/features/notifications_feed/domain/notifications_repository.dart

abstract class NotificationsRepository {
  /// Returns the current user's notifications (token-scoped).
  ///
  /// Backend: GET /notifications
  Future<List<Map<String, dynamic>>> getMyNotifications({
    int page = 1,
    int limit = 50,
    bool? isSeen, // null => all, true => read, false => unread
    String? search,
  });

  /// Mark a single notification as seen (read)
  ///
  /// Backend: POST /notifications/mark-read { notificationId }
  Future<void> markNotificationSeen(String id);

  /// Mark all notifications as seen (read)
  ///
  /// Backend: POST /notifications/mark-read { all: true }
  Future<void> markAllSeen();

  /// Returns unseen count efficiently.
  ///
  /// Implemented by calling GET /notifications?isRead=false&limit=1
  /// and reading `total`.
  Future<int> getUnseenCount();
}
