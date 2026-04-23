import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

abstract final class ErrorReporter {
  static void reportFlutterError(
    FlutterErrorDetails details,
    AppLogger logger,
  ) {
    logger.error(
      'flutterError',
      error: details.exception,
      stackTrace: details.stack,
      metadata: <String, Object?>{
        'library': details.library ?? 'unknown',
        'context': details.context?.toDescription() ?? 'none',
      },
    );
  }

  static void reportError(
    Object error,
    StackTrace stack,
    AppLogger logger, {
    required String source,
  }) {
    logger.error(
      'uncaughtError',
      error: error,
      stackTrace: stack,
      metadata: <String, Object?>{'source': source},
    );
  }
}
