// lib/core/storage/secure_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_constants.dart';

/// Secure storage for sensitive values (tokens, role, user identifiers).
/// Uses encrypted storage on Android (EncryptedSharedPreferences) and Keychain on iOS.
class SecureStore {
  SecureStore()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  final FlutterSecureStorage _storage;

  // -----------------------
  // Low-level helpers
  // -----------------------
  Future<void> writeString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readString(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // -----------------------
  // Typed helpers (Session)
  // -----------------------
  Future<void> setAccessToken(String token) async {
    await writeString(AppConstants.kSecureAccessToken, token);
  }

  Future<String?> getAccessToken() async {
    return readString(AppConstants.kSecureAccessToken);
  }

  Future<void> setRefreshToken(String token) async {
    await writeString(AppConstants.kSecureRefreshToken, token);
  }

  Future<String?> getRefreshToken() async {
    return readString(AppConstants.kSecureRefreshToken);
  }

  Future<void> setRole(String role) async {
    await writeString(AppConstants.kSecureUserRole, role);
  }

  Future<String?> getRole() async {
    return readString(AppConstants.kSecureUserRole);
  }

  Future<void> setSchoolCode(String schoolCode) async {
    await writeString(AppConstants.kSecureSchoolCode, schoolCode);
  }

  Future<String?> getSchoolCode() async {
    return readString(AppConstants.kSecureSchoolCode);
  }

  Future<void> setUserId(String userId) async {
    await writeString(AppConstants.kSecureUserId, userId);
  }

  Future<String?> getUserId() async {
    return readString(AppConstants.kSecureUserId);
  }

  Future<void> setUserName(String name) async {
    await writeString(AppConstants.kSecureUserName, name);
  }

  Future<String?> getUserName() async {
    return readString(AppConstants.kSecureUserName);
  }

  Future<void> setMustChangePassword(bool value) async {
    await writeString(AppConstants.kSecureMustChangePassword, value ? '1' : '0');
  }

  Future<bool> getMustChangePassword() async {
    final v = await readString(AppConstants.kSecureMustChangePassword);
    return v == '1';
  }

  // -----------------------
  // Convenience
  // -----------------------
  Future<void> clearSession() async {
    await delete(AppConstants.kSecureAccessToken);
    await delete(AppConstants.kSecureRefreshToken);
    await delete(AppConstants.kSecureUserRole);
    await delete(AppConstants.kSecureMustChangePassword);
    await delete(AppConstants.kSecureSchoolCode);
    await delete(AppConstants.kSecureUserId);
    await delete(AppConstants.kSecureUserName);
  }
}
