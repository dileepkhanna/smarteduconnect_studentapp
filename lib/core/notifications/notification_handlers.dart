// lib/core/notifications/notification_handlers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'fcm_service.dart';

class NotificationHandlers {
  static void attach({
    required ProviderContainer container,
    required GoRouter router,
    required FcmService fcm,
  }) {
    fcm.onNotificationTap.listen((msg) {
      final data = msg.data;

      final type = (data['type'] ?? data['notificationType'] ?? '')
          .toString()
          .toUpperCase();

      switch (type) {
        case 'CIRCULAR':
          _openCircular(router, data);
          break;

        case 'ATTENDANCE':
          router.go(AppRoutes.attendance);
          break;

        case 'HOMEWORK':
          router.go(AppRoutes.homework);
          break;

        case 'RECAP':
          router.go(AppRoutes.recaps);
          break;

        case 'EXAM':
        case 'EXAM_REMINDER':
          router.go(AppRoutes.exams);
          break;

        case 'EXAM_RESULT':
        case 'RESULT_PUBLISHED':
          _openExamResult(router, data);
          break;

        default:
          // ✅ FIX: your routes file has `notifications`
          router.go(AppRoutes.notifications);
          break;
      }
    });
  }

  static void _openCircular(GoRouter router, Map<String, dynamic> data) {
    final id = (data['id'] ?? data['circularId'] ?? '').toString();
    final circularType = (data['circularType'] ?? data['typeEnum'] ?? '').toString();

    if (id.isNotEmpty) {
      router.go(AppRoutes.withQuery(AppRoutes.circularDetail, {'id': id}));
      return;
    }

    if (circularType.isNotEmpty) {
      router.go(AppRoutes.withQuery(AppRoutes.circularList, {'type': circularType}));
      return;
    }

    router.go(AppRoutes.circularTypes);
  }

  static void _openExamResult(GoRouter router, Map<String, dynamic> data) {
    final examId = (data['examId'] ?? data['id'] ?? '').toString();
    final examName = (data['examName'] ?? data['name'] ?? '').toString();

    // Your ExamResultScreen requires BOTH examId + examName
    if (examId.isNotEmpty && examName.isNotEmpty) {
      router.go(
        AppRoutes.withQuery(
          AppRoutes.examResult,
          {'examId': examId, 'examName': examName},
        ),
      );
      return;
    }

    // Fallback if payload doesn't include name
    router.go(AppRoutes.exams);
  }
}
