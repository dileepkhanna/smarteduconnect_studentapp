// lib/core/review/app_review_stub.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web/unsupported-platform fallback for "Rate this app".
class AppReview {
  AppReview._();

  static const String fallbackUrl =
      String.fromEnvironment('STORE_URL', defaultValue: '');

  static Future<bool> requestReview() async {
    try {
      final url = fallbackUrl;
      if (url.isEmpty) return false;

      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('AppReview: fallback launch failed');
      }
      return false;
    }
  }
}
