// lib/core/device/device_id.dart
import 'package:uuid/uuid.dart';

import '../storage/prefs_store.dart';

/// Backend requires `deviceId` for login + single-device policy.
/// We generate a stable UUID once and persist it in SharedPreferences.
class DeviceId {
  static const _uuid = Uuid();

  static Future<String> getOrCreate(PrefsStore prefs) async {
    final existing = await prefs.getDeviceId();
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final fresh = _uuid.v4();
    await prefs.setDeviceId(fresh);
    return fresh;
  }
}
