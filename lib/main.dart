// lib/main.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env (safe even if missing in release builds)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // ignore
  }

  // Keep app portrait (common for school apps; remove if you want tablet landscape later)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Better crash visibility during development + safe fallback in release.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // TODO: Hook Crashlytics/Sentry here later if you add it.
    }
  };

  // Zone guard catches async errors.
  runZonedGuarded(() async {
    // Clean error UI in release builds.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (!kReleaseMode) {
        return ErrorWidget(details.exception);
      }
      return const _ReleaseErrorScreen();
    };

    // Optional: style status bar (final colors come from theme later)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    await bootstrap();
  }, (error, stack) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print('UNCAUGHT ERROR: $error\n$stack');
    }
    // TODO: Hook Crashlytics/Sentry here later if you add it.
  });
}

class _ReleaseErrorScreen extends StatelessWidget {
  const _ReleaseErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Something went wrong.\nPlease restart the app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
