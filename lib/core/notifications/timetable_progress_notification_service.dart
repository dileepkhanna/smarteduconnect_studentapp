import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimetableProgressNotificationService {
  TimetableProgressNotificationService._();

  static final TimetableProgressNotificationService instance =
      TimetableProgressNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int _notificationId = 91011;
  static const String _channelId = 'ase_parent_timetable_progress';
  static const String _channelName = 'Timetable Progress';
  static const String _channelDesc = 'Live class progress in notification bar';

  bool _initialized = false;
  String _lastSignature = '';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.low,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> showLiveProgress({
    required String title,
    required String body,
    required int progressPercent,
  }) async {
    await _ensureInitialized();

    final pct = progressPercent.clamp(0, 100);
    final signature = '$title|$body|$pct';
    if (signature == _lastSignature) return;
    _lastSignature = signature;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: pct,
      category: AndroidNotificationCategory.progress,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    await _plugin.show(
      _notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> clear() async {
    await _ensureInitialized();
    _lastSignature = '';
    await _plugin.cancel(_notificationId);
  }
}

