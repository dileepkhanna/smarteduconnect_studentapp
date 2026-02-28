// lib/app/app_providers.dart

import 'dart:async';

import 'package:ase_parent_app/core/config/app_config.dart';
import 'package:ase_parent_app/core/device/device_id.dart';
import 'package:ase_parent_app/core/network/api_client.dart';
import 'package:ase_parent_app/core/network/dio_client.dart';
import 'package:ase_parent_app/core/notifications/fcm_service.dart';
import 'package:ase_parent_app/core/session/session_manager.dart';
import 'package:ase_parent_app/core/storage/prefs_store.dart';
import 'package:ase_parent_app/core/storage/secure_store.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ase_parent_app/features/auth/data/auth_api.dart';
import 'package:ase_parent_app/features/auth/data/auth_repository_impl.dart';
import 'package:ase_parent_app/features/auth/domain/auth_repository.dart';
import 'package:ase_parent_app/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:ase_parent_app/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:ase_parent_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:ase_parent_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:ase_parent_app/features/auth/domain/usecases/refresh_usecase.dart';
import 'package:ase_parent_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:ase_parent_app/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:ase_parent_app/features/auth/presentation/controllers/auth_controller.dart';

import 'package:ase_parent_app/features/profile/data/profile_api.dart';
import 'package:ase_parent_app/features/profile/data/profile_repository_impl.dart';
import 'package:ase_parent_app/features/profile/domain/profile_repository.dart';

import 'package:ase_parent_app/features/school/data/school_api.dart';
import 'package:ase_parent_app/features/school/data/school_repository_impl.dart';
import 'package:ase_parent_app/features/school/domain/school_repository.dart';

import 'package:ase_parent_app/features/cms_pages/data/cms_api.dart';
import 'package:ase_parent_app/features/cms_pages/data/cms_repository_impl.dart';
import 'package:ase_parent_app/features/cms_pages/domain/cms_repository.dart';

import 'package:ase_parent_app/features/timetable/data/timetable_api.dart';
import 'package:ase_parent_app/features/timetable/data/timetable_repository_impl.dart';
import 'package:ase_parent_app/features/timetable/domain/timetable_repository.dart';

import 'package:ase_parent_app/features/attendance/data/attendance_api.dart';
import 'package:ase_parent_app/features/attendance/data/attendance_repository_impl.dart';
import 'package:ase_parent_app/features/attendance/domain/attendance_repository.dart';

import 'package:ase_parent_app/features/recaps/data/recaps_api.dart';
import 'package:ase_parent_app/features/recaps/data/recaps_repository_impl.dart';
import 'package:ase_parent_app/features/recaps/domain/recaps_repository.dart';

import 'package:ase_parent_app/features/homework/data/homework_api.dart';
import 'package:ase_parent_app/features/homework/data/homework_repository_impl.dart';
import 'package:ase_parent_app/features/homework/domain/homework_repository.dart';

import 'package:ase_parent_app/features/circulars/data/circulars_api.dart';
import 'package:ase_parent_app/features/circulars/data/circulars_repository_impl.dart';
import 'package:ase_parent_app/features/circulars/domain/circulars_repository.dart';

import 'package:ase_parent_app/features/notifications_feed/data/notifications_api.dart';
import 'package:ase_parent_app/features/notifications_feed/data/notifications_repository_impl.dart';
import 'package:ase_parent_app/features/notifications_feed/domain/notifications_repository.dart';

import 'package:ase_parent_app/features/exams/data/exams_api.dart';
import 'package:ase_parent_app/features/exams/data/exams_repository_impl.dart';
import 'package:ase_parent_app/features/exams/domain/exams_repository.dart';

import 'package:ase_parent_app/features/birthdays/data/birthdays_api.dart';
import 'package:ase_parent_app/features/birthdays/data/birthdays_repository_impl.dart';
import 'package:ase_parent_app/features/birthdays/domain/birthdays_repository.dart';

/// -------------------------
/// Core / App providers
/// -------------------------

bool _envBool(String? v, {bool fallback = false}) {
  if (v == null) return fallback;
  final s = v.trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes' || s == 'y';
}

String? _env(String key) {
  final v = dotenv.env[key];
  if (v == null) return null;
  final s = v.trim();
  return s.isEmpty ? null : s;
}

/// Removes trailing slash + prevents /api/api mistakes.
String _normalizeBaseUrl(String raw, {required String apiPrefix}) {
  var url = raw.trim();
  var normalizedPrefix = apiPrefix.trim();

  // Normalize prefix (supports both "api" and "/api" env styles).
  while (normalizedPrefix.startsWith('/')) {
    normalizedPrefix = normalizedPrefix.substring(1);
  }
  while (normalizedPrefix.endsWith('/')) {
    normalizedPrefix =
        normalizedPrefix.substring(0, normalizedPrefix.length - 1);
  }

  // Ensure scheme (optional but helpful)
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'http://$url';
  }

  // Remove trailing slash
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }

  // If user mistakenly put /api in BASE_URL and apiPrefix is api, strip it.
  final suffix = normalizedPrefix.isEmpty ? '' : '/$normalizedPrefix';
  if (suffix.isNotEmpty && url.toLowerCase().endsWith(suffix.toLowerCase())) {
    url = url.substring(0, url.length - suffix.length);
  }

  return url;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  // IMPORTANT:
  // - For real phone: BASE_URL must be your PC WiFi IP, NOT localhost.
  //   Example: http://192.168.1.50:3000
  // - Keep API_PREFIX=api (so final base becomes .../api)
  const defineApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  const defineBaseUrl = String.fromEnvironment('BASE_URL');
  const defineFallbackApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL_FALLBACK',
  );
  const defineFallbackBaseUrl = String.fromEnvironment(
    'BASE_URL_FALLBACK',
  );
  const definePrefix = String.fromEnvironment('API_PREFIX', defaultValue: 'api');
  const defineFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  const defineLogs = String.fromEnvironment('ENABLE_NETWORK_LOGS', defaultValue: 'false');

  final apiPrefix = _env('API_PREFIX') ?? definePrefix;

  final rawBaseUrl =
      _env('API_BASE_URL') ??
      _env('BASE_URL') ??
      (defineApiBaseUrl.isNotEmpty
          ? defineApiBaseUrl
          : (defineBaseUrl.isNotEmpty ? defineBaseUrl : 'http://10.0.2.2:3000'));

  final baseUrl = _normalizeBaseUrl(rawBaseUrl, apiPrefix: apiPrefix);

  final rawFallbackBaseUrl =
      _env('API_BASE_URL_FALLBACK') ??
      _env('BASE_URL_FALLBACK') ??
      (defineFallbackApiBaseUrl.isNotEmpty
          ? defineFallbackApiBaseUrl
          : (defineFallbackBaseUrl.isNotEmpty ? defineFallbackBaseUrl : null));

  final fallbackBaseUrl = rawFallbackBaseUrl == null
      ? null
      : _normalizeBaseUrl(rawFallbackBaseUrl, apiPrefix: apiPrefix);

  final flavor = _env('FLAVOR') ?? defineFlavor;

  final enableLogs = _envBool(
    _env('ENABLE_NETWORK_LOGS') ?? defineLogs,
  );

  return AppConfig(
    baseUrl: baseUrl,
    fallbackBaseUrl: fallbackBaseUrl,
    apiPrefix: apiPrefix,
    flavor: flavor,
    enableNetworkLogs: enableLogs,
  );
});

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final prefsStoreProvider = Provider<PrefsStore>((ref) => PrefsStore());

final prefsProvider = prefsStoreProvider;

final deviceIdProvider = FutureProvider<String>((ref) async {
  final prefs = ref.read(prefsStoreProvider);
  return DeviceId.getOrCreate(prefs);
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

final sessionManagerProvider = ChangeNotifierProvider<SessionManager>((ref) {
  final secure = ref.read(secureStoreProvider);
  final prefs = ref.read(prefsStoreProvider);
  final config = ref.read(appConfigProvider);

  final sm = SessionManager(
    secureStore: secure,
    prefsStore: prefs,
    config: config,
  );

  unawaited(sm.hydrate());
  return sm;
});

final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.read(appConfigProvider);
  final secure = ref.read(secureStoreProvider);
  final sm = ref.read(sessionManagerProvider);

  return DioClient(
    config: config,
    secureStore: secure,
    sessionManager: sm,
    prefsStore: ref.read(prefsStoreProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioClientProvider).dio);
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  final prefs = ref.read(prefsStoreProvider);
  final sm = ref.read(sessionManagerProvider);
  final api = ref.read(apiClientProvider);

  return FcmService(
    prefsStore: prefs,
    sessionManager: sm,
    apiClient: api,
  );
});

final globalLoadingCountProvider = StateProvider<int>((ref) => 0);

Future<T> withGlobalLoader<T>(WidgetRef ref, Future<T> Function() job) async {
  ref.read(globalLoadingCountProvider.notifier).state++;
  try {
    return await job();
  } finally {
    ref.read(globalLoadingCountProvider.notifier).state--;
  }
}

/// -------------------------
/// Biometrics
/// -------------------------

class BiometricsService {
  BiometricsService(this._localAuth);

  final LocalAuthentication _localAuth;

  Future<bool> enableBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck || !isSupported) return false;

    final didAuth = await _localAuth.authenticate(
      localizedReason: 'Enable biometrics to quickly unlock your account.',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    return didAuth;
  }
}

final biometricsServiceProvider = Provider<BiometricsService>((ref) {
  return BiometricsService(LocalAuthentication());
});

/// -------------------------
/// Auth (Api + Repository + Usecases + Controller)
/// -------------------------

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.read(authApiProvider),
    session: ref.read(sessionManagerProvider),
    prefs: ref.read(prefsStoreProvider),
    fcm: ref.read(fcmServiceProvider),
  );
});

final loginUsecaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final refreshUsecaseProvider = Provider<RefreshUseCase>((ref) {
  return RefreshUseCase(ref.read(sessionManagerProvider));
});

final logoutUsecaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

final forgotPasswordUsecaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  return ForgotPasswordUseCase(ref.read(authRepositoryProvider));
});

final verifyOtpUsecaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.read(authRepositoryProvider));
});

final resetPasswordUsecaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.read(authRepositoryProvider));
});

final changePasswordUsecaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.read(authRepositoryProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    session: ref.read(sessionManagerProvider),
    loginUseCase: ref.read(loginUsecaseProvider),
    logoutUseCase: ref.read(logoutUsecaseProvider),
    forgotPasswordUseCase: ref.read(forgotPasswordUsecaseProvider),
    verifyOtpUseCase: ref.read(verifyOtpUsecaseProvider),
    resetPasswordUseCase: ref.read(resetPasswordUsecaseProvider),
    changePasswordUseCase: ref.read(changePasswordUsecaseProvider),
  );
});

class AuthUiState {
  const AuthUiState({this.user});
  final dynamic user;

  AuthUiState copyWith({dynamic user}) => AuthUiState(user: user ?? this.user);
}

class AuthUiController extends StateNotifier<AuthUiState> {
  AuthUiController() : super(const AuthUiState());

  void updateUser(dynamic user) {
    state = state.copyWith(user: user);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthUiController, AuthUiState>((ref) {
  return AuthUiController();
});

/// -------------------------
/// Feature repositories
/// -------------------------

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final api = ProfileApi(ref.read(apiClientProvider));
  return ProfileRepositoryImpl(api);
});

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  final api = SchoolApi(ref.read(apiClientProvider));
  return SchoolRepositoryImpl(api);
});

final cmsRepositoryProvider = Provider<CmsRepository>((ref) {
  final api = CmsApi(ref.read(apiClientProvider));
  return CmsRepositoryImpl(api);
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final api = TimetableApi(ref.read(apiClientProvider));
  return TimetableRepositoryImpl(api);
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final api = AttendanceApi(ref.read(apiClientProvider));
  return AttendanceRepositoryImpl(api);
});

final recapsRepositoryProvider = Provider<RecapsRepository>((ref) {
  final api = RecapsApi(ref.read(apiClientProvider));
  return RecapsRepositoryImpl(api);
});

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  final api = HomeworkApi(ref.read(apiClientProvider));
  return HomeworkRepositoryImpl(api);
});

final circularsRepositoryProvider = Provider<CircularsRepository>((ref) {
  final api = CircularsApi(ref.read(apiClientProvider));
  return CircularsRepositoryImpl(api);
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final api = NotificationsApi(ref.read(apiClientProvider));
  return NotificationsRepositoryImpl(api);
});

final examsRepositoryProvider = Provider<ExamsRepository>((ref) {
  final api = ExamsApi(ref.read(apiClientProvider));
  return ExamsRepositoryImpl(api);
});

final birthdaysRepositoryProvider = Provider<BirthdaysRepository>((ref) {
  final api = BirthdaysApi(ref.read(apiClientProvider));
  return BirthdaysRepositoryImpl(api);
});
