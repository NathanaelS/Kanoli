import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';

class AppLogger {
  AppLogger({required this.environment});

  final AppEnvironment environment;

  void info(
    String event, [
    Map<String, Object?> metadata = const <String, Object?>{},
  ]) {
    _log('INFO', event, metadata: metadata);
  }

  void warning(
    String event, [
    Map<String, Object?> metadata = const <String, Object?>{},
  ]) {
    _log('WARN', event, metadata: metadata);
  }

  void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final fullMetadata = <String, Object?>{
      ...metadata,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack': stackTrace.toString(),
    };

    _log('ERROR', event, metadata: fullMetadata);
  }

  void _log(
    String level,
    String event, {
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final values = metadata.entries
        .map((MapEntry<String, Object?> entry) => '${entry.key}=${entry.value}')
        .join(' ');

    debugPrint(
      '[Kanoli][$level][${environment.name}] $event ${values.trim()}'.trim(),
    );
  }
}
