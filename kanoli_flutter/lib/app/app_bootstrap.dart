// Starts Kanoli with diagnostics, environment selection, and app-level error
// handling before mounting the root widget.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_environment.dart';
import '../core/diagnostics/diagnostics_store.dart';
import '../core/errors/error_reporter.dart';
import '../core/logging/app_logger.dart';
import 'app.dart';

Future<void> bootstrap() async {
  AppLogger? logger;
  const startupStateKey = 'kanoli.startup.inProgress.v1';

  // The guarded zone catches async failures outside Flutter's own error hooks.
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await DiagnosticsStore.instance.initialize();
      final prefs = await SharedPreferences.getInstance();
      final previousStartupIncomplete = prefs.getBool(startupStateKey) ?? false;
      await prefs.setBool(startupStateKey, true);

      final environment = AppEnvironment.fromDartDefine();
      logger = AppLogger(
        environment: environment,
        diagnosticsStore: DiagnosticsStore.instance,
      );

      logger!.info('bootstrap', {'environment': environment.name});

      // Route framework and platform errors into the same diagnostics path.
      FlutterError.onError = (FlutterErrorDetails details) {
        ErrorReporter.reportFlutterError(details, logger!);
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        logger!.error(
          'errorWidget',
          error: details.exception,
          stackTrace: details.stack,
        );

        return ColoredBox(
          color: const Color(0xFF15141B),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unexpected UI error:\n${details.exceptionAsString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFBDBDBD)),
              ),
            ),
          ),
        );
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        ErrorReporter.reportError(
          error,
          stack,
          logger!,
          source: 'platformDispatcher',
        );
        return true;
      };

      runApp(
        KanoliApp(
          environment: environment,
          logger: logger!,
          previousStartupIncomplete: previousStartupIncomplete,
          startupStateKey: startupStateKey,
        ),
      );
    },
    (Object error, StackTrace stack) {
      final localLogger = logger;
      if (localLogger == null) {
        debugPrint('bootstrap failure before logger init: $error');
        return;
      }
      ErrorReporter.reportError(
        error,
        stack,
        localLogger,
        source: 'runZonedGuarded',
      );
    },
  );
}
