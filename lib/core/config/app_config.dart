// lib/core/config/app_config.dart
import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig({
    required this.baseUrl,
    this.fallbackBaseUrl,
    this.apiPrefix = 'api',
    this.connectTimeoutMs = 15000,
    this.receiveTimeoutMs = 20000,
    this.sendTimeoutMs = 20000,
    this.flavor = 'dev',
    this.enableNetworkLogs = true,
  });

  /// Example values:
  /// - Local:  http://10.0.2.2:3000   (Android emulator)
  /// - Local:  http://localhost:3000  (iOS simulator)
  /// - Device: http://your-lan-ip:3000
  /// - Prod:   https://api.yourdomain.com
  final String baseUrl;
  final String? fallbackBaseUrl;

  /// Backend uses `app.setGlobalPrefix('api')`
  final String apiPrefix;

  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final int sendTimeoutMs;

  /// dev / staging / prod
  final String flavor;

  /// Enable request/response logs (disable for prod builds)
  final bool enableNetworkLogs;

  /// Full API base: {baseUrl}/{apiPrefix}
  String get apiBaseUrl {
    final b = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = apiPrefix.startsWith('/') ? apiPrefix.substring(1) : apiPrefix;
    return '$b/$p';
  }

  String? get fallbackApiBaseUrl {
    final raw = fallbackBaseUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    final b = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    final p = apiPrefix.startsWith('/') ? apiPrefix.substring(1) : apiPrefix;
    return '$b/$p';
  }

  bool get isProd => flavor.toLowerCase() == 'prod';

  factory AppConfig.fromDartDefines() {
    // You can override at build/run time:
    // flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
    // flutter run --dart-define=FLAVOR=dev
    const definedBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
    );
    final fallbackBaseUrl = _defaultLocalBaseUrl();

    // Disable noisy logs in release mode by default
    final enableLogs = !kReleaseMode;

    return AppConfig(
      baseUrl: definedBaseUrl.isNotEmpty ? definedBaseUrl : fallbackBaseUrl,
      enableNetworkLogs: enableLogs,
    );
  }

  static String _defaultLocalBaseUrl() {
    // Safe defaults for local dev:
    // - Android emulator uses 10.0.2.2 to reach host machine.
    // - iOS simulator can use localhost.
    // - Web uses localhost typically.
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }
}
