import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DiagnosticsStore {
  DiagnosticsStore._();

  static final DiagnosticsStore instance = DiagnosticsStore._();

  static const int _maxRecentEntries = 300;
  static const int _maxBytes = 1024 * 1024;

  final List<String> _recentEntries = <String>[];
  File? _logFile;

  Future<void> initialize() async {
    final supportDir = await getApplicationSupportDirectory();
    final logDir = Directory('${supportDir.path}/diagnostics');
    logDir.createSync(recursive: true);

    final primary = File('${logDir.path}/kanoli.log');
    final rotated = File('${logDir.path}/kanoli.log.1');
    if (primary.existsSync() && primary.lengthSync() > _maxBytes) {
      if (rotated.existsSync()) {
        rotated.deleteSync();
      }
      primary.renameSync(rotated.path);
    }
    _logFile = primary;
    if (!_logFile!.existsSync()) {
      _logFile!.createSync(recursive: true);
    }
  }

  String? get logFilePath => _logFile?.path;

  List<String> get recentEntries => List<String>.unmodifiable(_recentEntries);

  List<String> get recentErrors => _recentEntries
      .where((String entry) => entry.contains('[ERROR]') || entry.contains('[WARN]'))
      .toList(growable: false);

  void record(String line) {
    _recentEntries.add(line);
    if (_recentEntries.length > _maxRecentEntries) {
      _recentEntries.removeAt(0);
    }

    final file = _logFile;
    if (file == null) {
      return;
    }
    try {
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } on FileSystemException {
      // Non-fatal; diagnostics logging should never break app behavior.
    }
  }

  String exportText({
    String? activeBoardPath,
    String? activeTodoPath,
  }) {
    final buffer = StringBuffer()
      ..writeln('Kanoli Diagnostics Export')
      ..writeln('activeBoardPath=${activeBoardPath ?? "<none>"}')
      ..writeln('activeTodoPath=${activeTodoPath ?? "<none>"}')
      ..writeln('logFilePath=${logFilePath ?? "<not-initialized>"}')
      ..writeln()
      ..writeln('Recent Entries:')
      ..writeln(_recentEntries.join('\n'));
    return buffer.toString();
  }
}
