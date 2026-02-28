// lib/core/storage/prefs_store.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_constants.dart';

/// SharedPreferences wrapper for non-sensitive app preferences.
class PrefsStore {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // Generic helpers
  Future<void> setString(String key, String value) async {
    final p = await _prefs;
    await p.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final p = await _prefs;
    return p.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    final p = await _prefs;
    await p.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final p = await _prefs;
    return p.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    final p = await _prefs;
    await p.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final p = await _prefs;
    return p.getInt(key);
  }

  Future<void> remove(String key) async {
    final p = await _prefs;
    await p.remove(key);
  }

  Future<void> clear() async {
    final p = await _prefs;
    await p.clear();
  }

  // Typed helpers
  Future<void> setDeviceId(String id) async => setString(AppConstants.kPrefsDeviceId, id);
  Future<String?> getDeviceId() async => getString(AppConstants.kPrefsDeviceId);

  Future<void> setLastSchoolCode(String schoolCode) async =>
      setString(AppConstants.kPrefsLastSchoolCode, schoolCode);
  Future<String?> getLastSchoolCode() async => getString(AppConstants.kPrefsLastSchoolCode);

  Future<void> setLastEmail(String email) async => setString(AppConstants.kPrefsLastEmail, email);
  Future<String?> getLastEmail() async => getString(AppConstants.kPrefsLastEmail);

  Future<void> setBiometricsEnabled(bool enabled) async =>
      setBool(AppConstants.kPrefsBiometricsEnabled, enabled);
  Future<bool> getBiometricsEnabled() async => (await getBool(AppConstants.kPrefsBiometricsEnabled)) ?? false;

  Future<void> setFcmToken(String token) async => setString(AppConstants.kPrefsFcmToken, token);
  Future<String?> getFcmToken() async => getString(AppConstants.kPrefsFcmToken);
}
