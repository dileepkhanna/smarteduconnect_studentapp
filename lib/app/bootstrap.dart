// lib/app/bootstrap.dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import '../core/config/endpoints.dart';
import '../core/notifications/fcm_service.dart'
    show firebaseMessagingBackgroundHandler;
import '../core/session/lifecycle_logout_observer.dart';
import 'app.dart';
import 'app_providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await _safe(() => _validateRestoredSession(container));

  final firebaseReady = await _safeInitFirebase();

  // ✅ Register background handler only on mobile + only after Firebase init
  if (firebaseReady && !kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ✅ Init local notifications + token sync only when Firebase is ready
  if (firebaseReady) {
    await _safe(() => container.read(fcmServiceProvider).init());
  }

  WidgetsBinding.instance.addObserver(
    LifecycleLogoutObserver(container: container),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}

Future<bool> _safeInitFirebase() async {
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

Future<void> _safe(Future<void> Function() fn) async {
  try {
    await fn();
  } catch (_) {}
}

Future<void> _validateRestoredSession(ProviderContainer container) async {
  final session = container.read(sessionManagerProvider);
  await session.hydrate();

  if (!session.isAuthenticated) return;

  try {
    final res = await container.read(apiClientProvider).get<dynamic>(
          Endpoints.userMe,
        );
    final raw = res.data;

    Map<String, dynamic> root = <String, dynamic>{};
    if (raw is Map<String, dynamic>) {
      root = raw;
    } else if (raw is Map) {
      root = Map<String, dynamic>.from(raw);
    }

    final data = (root['data'] is Map<String, dynamic>)
        ? root['data'] as Map<String, dynamic>
        : (root['data'] is Map)
            ? Map<String, dynamic>.from(root['data'] as Map)
            : root;

    final role = (data['role'] ?? '').toString().trim().toUpperCase();
    if (role != 'STUDENT') {
      await session.clearSession();
      return;
    }

    final mustChangePassword = data['mustChangePassword'] == true;
    if (mustChangePassword && !session.mustChangePassword) {
      await session.markMustChangePasswordRequired();
    } else if (!mustChangePassword && session.mustChangePassword) {
      await session.clearMustChangePassword();
    }
  } on DioException catch (e) {
    final status = e.response?.statusCode ?? 0;
    if (status == 401 || status == 403) {
      await session.clearSession();
    }
  } catch (_) {
    // ignore non-auth errors (network/server temporary issues)
  }
}
