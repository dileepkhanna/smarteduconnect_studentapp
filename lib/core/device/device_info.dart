// lib/core/device/device_info.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Lightweight device info helper used mainly for:
/// - platform string for backend (optional)
/// - debugging / logs
class DeviceInfo {
  static const String platformAndroid = 'ANDROID';
  static const String platformIos = 'IOS';
  static const String platformWeb = 'WEB';
  static const String platformUnknown = 'UNKNOWN';

  static Future<String> platform() async {
    if (kIsWeb) return platformWeb;
    if (Platform.isAndroid) return platformAndroid;
    if (Platform.isIOS) return platformIos;
    return platformUnknown;
  }

  static Future<String?> deviceModel() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await plugin.webBrowserInfo;
        return '${web.browserName.name} ${web.userAgent ?? ''}'.trim();
      }
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        return '${a.brand} ${a.model}'.trim();
      }
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        return i.utsname.machine;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
