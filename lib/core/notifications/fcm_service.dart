// lib/core/notifications/fcm_service.dart
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../device/device_info.dart';
import '../network/api_client.dart';
import '../session/session_manager.dart';
import '../storage/prefs_store.dart';

/// FCM is used ONLY for Push Notifications.
/// Email OTP is handled by backend (auth_otps + Nodemailer SMTP).
///
/// Backend supports:
/// - Login can include optional fcmToken
/// - POST /auth/register-device (auth) with { deviceId, fcmToken, platform }
class FcmService {
  FcmService({
    required PrefsStore prefsStore,
    required SessionManager sessionManager,
    required ApiClient apiClient,
  })  : _prefs = prefsStore,
        _session = sessionManager,
        _api = apiClient;

  final PrefsStore _prefs;
  final SessionManager _session;
  final ApiClient _api;

  // ⚠️ IMPORTANT: Do NOT touch FirebaseMessaging.instance before Firebase init.
  FirebaseMessaging? _messaging;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final StreamController<RemoteMessage> _tapStream =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationTap => _tapStream.stream;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'ase_school_high',
    'ASE School Notifications',
    description: 'High priority notifications for ASE School app',
    importance: Importance.high,
  );

  bool _initialized = false;
  bool _firebaseReady = false;

  /// Backward-compatible: bootstrap.dart calls `initialize()`
  Future<void> initialize() => init();

  /// Main initializer
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return; // Mobile-only feature

    // ✅ Ensure Firebase is initialized. If it fails, we just skip FCM safely.
    _firebaseReady = await _ensureFirebaseInitialized();
    if (!_firebaseReady) return;

    _messaging = FirebaseMessaging.instance;

    // ✅ Background handler registration should be done ONCE after init
    // (bootstrap.dart already does it; keeping it here is safe but redundant).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await _requestPermissionIfNeeded();
    await _wireFirebaseHandlers();
    await syncTokenToBackendIfPossible();
  }

  Future<bool> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get the latest FCM token (may be null if not available).
  Future<String?> getToken() async {
    if (kIsWeb || !_firebaseReady || _messaging == null) return null;
    try {
      final t = await _messaging!.getToken();
      final token = t?.trim();
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Call this after login (or on app start if session exists).
  /// It will register token to backend if user is authenticated.
  Future<void> syncTokenToBackendIfPossible() async {
    if (kIsWeb || !_firebaseReady || _messaging == null) return;

    final token = await getToken();
    if (token == null) return;

    // Store locally (non-sensitive)
    await _prefs.setFcmToken(token);

    if (!_session.isAuthenticated) return;

    final deviceId = await _prefs.getDeviceId();
    if (deviceId == null || deviceId.trim().isEmpty) return;

    final platform = await _platformForBackend();

    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/register-device',
        body: {
          'deviceId': deviceId.trim(),
          'fcmToken': token,
          'platform': platform,
        },
      );
    } catch (_) {
      // Ignore: token sync can retry later
    }
  }

  Future<void> dispose() async {
    await _tapStream.close();
  }

  // ---------------------------
  // Internal
  // ---------------------------

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // ✅ flutter_local_notifications v18: NO onDidReceiveLocalNotification
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        // When user taps local notification (foreground show)
        _tapStream.add(
          RemoteMessage(
            data: resp.payload == null
                ? <String, dynamic>{}
                : <String, dynamic>{'payload': resp.payload},
          ),
        );
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
    }

    if (Platform.isIOS && _messaging != null) {
      // Foreground presentation for iOS
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (kIsWeb || !_firebaseReady || _messaging == null) return;

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _wireFirebaseHandlers() async {
    if (kIsWeb || !_firebaseReady || _messaging == null) return;

    // Handle tap when app was terminated
    final initial = await _messaging!.getInitialMessage();
    if (initial != null) _tapStream.add(initial);

    // Handle tap when app in background
    FirebaseMessaging.onMessageOpenedApp.listen(_tapStream.add);

    // Foreground messages -> show local notification
    FirebaseMessaging.onMessage.listen((message) async {
      await _showLocalNotification(message);
    });

    // Token refresh
    _messaging!.onTokenRefresh.listen((newToken) async {
      final t = newToken.trim();
      if (t.isEmpty) return;
      await _prefs.setFcmToken(t);
      await syncTokenToBackendIfPossible();
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final title = message.notification?.title ??
        ((message.data['title']?.toString().trim().isNotEmpty ?? false)
            ? message.data['title'].toString()
            : 'ASE School');

    final body = message.notification?.body ??
        ((message.data['body']?.toString().trim().isNotEmpty ?? false)
            ? message.data['body'].toString()
            : '');

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    await _local.show(
      id,
      title,
      body,
      details,
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  Future<String> _platformForBackend() async {
    final p = await DeviceInfo.platform();
    if (p == DeviceInfo.platformAndroid) return 'android';
    if (p == DeviceInfo.platformIos) return 'ios';
    return 'unknown';
  }
}

/// Background handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    // ignore
  }
  // Keep minimal: OS will show notification if configured from server.
}
