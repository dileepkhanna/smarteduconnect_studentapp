// lib/core/review/app_review_io.dart
import 'package:in_app_review/in_app_review.dart';

/// Native (Android/iOS/macOS) app review helper.
class AppReview {
  AppReview._();

  static final InAppReview _inAppReview = InAppReview.instance;

  /// Requests an in-app review if available; otherwise opens the store listing.
  static Future<bool> requestReview() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        await _inAppReview.requestReview();
        return true;
      } else {
        await _inAppReview.openStoreListing();
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}
