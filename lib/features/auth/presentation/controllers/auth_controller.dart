// lib/features/auth/presentation/controllers/auth_controller.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/auth_repository.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController({
    required SessionManager session,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
  })  : _session = session,
        _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        super(const AsyncData(null));

  final SessionManager _session;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;

  // --------
  // Helpers
  // --------
  String mapError(Object error) {
    if (error is DioException) {
      final wrapped = error.error;
      if (wrapped is ApiError && wrapped.message.trim().isNotEmpty) {
        return wrapped.message.trim();
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = (data['message'] ?? '').toString().trim();
        if (msg.isNotEmpty) return msg;
      } else if (data is Map) {
        final msg = (data['message'] ?? '').toString().trim();
        if (msg.isNotEmpty) return msg;
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'No internet connection. Please check your network.';
      }
    }

    if (error is ApiException) {
      final apiError = error.error;
      final msg = (apiError?.message ?? '').trim();
      return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _saveLastCredentials({
    required String schoolCode,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kPrefsLastSchoolCode, schoolCode.trim());
    await prefs.setString(AppConstants.kPrefsLastEmail, email.trim());
  }

  // -------------
  // Convenience
  // -------------
  Future<String?> getLastSchoolCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.kPrefsLastSchoolCode);
  }

  Future<String?> getLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.kPrefsLastEmail);
  }

  bool isLoggedIn() => _session.isAuthenticated;

  // -----
  // Auth
  // -----
  Future<AuthLoginResult> login({
    required String schoolCode,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _loginUseCase(
        schoolCode: schoolCode.trim(),
        email: email.trim(),
        password: password,
      );

      await _saveLastCredentials(
        schoolCode: schoolCode,
        email: email,
      );

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      // If login failed, ensure stale local session cannot keep user on protected screens.
      try {
        await _session.clearSession();
      } catch (_) {
        _session.forceLocalLogout();
      }
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout({bool allDevices = false}) async {
    state = const AsyncLoading();
    try {
      await _logoutUseCase(allDevices: allDevices);

      // forceLocalLogout() is void (no await)
      _session.forceLocalLogout();

      state = const AsyncData(null);
    } catch (e, st) {
      _session.forceLocalLogout();
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // -----------------
  // Forgot Password
  // -----------------
  Future<void> forgotPassword({
    required String schoolCode,
    required String email,
  }) async {
    state = const AsyncLoading();
    try {
      await _forgotPasswordUseCase(
        schoolCode: schoolCode.trim(),
        email: email.trim(),
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<bool> verifyOtp({
    required String schoolCode,
    required String email,
    required String otp,
  }) async {
    state = const AsyncLoading();
    try {
      final ok = await _verifyOtpUseCase(
        schoolCode: schoolCode.trim(),
        email: email.trim(),
        otp: otp.trim(),
      );
      state = const AsyncData(null);
      return ok;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String schoolCode,
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    state = const AsyncLoading();
    try {
      await _resetPasswordUseCase(
        schoolCode: schoolCode.trim(),
        email: email.trim(),
        otp: otp.trim(),
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // -----------------
  // First-Time Setup
  // -----------------
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    state = const AsyncLoading();
    try {
      await _changePasswordUseCase(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );

      await _session.clearMustChangePassword();

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
