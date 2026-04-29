import 'dart:io';

class SafeFileStore {
  SafeFileStore({this.maxBackups = 5, this.backupDirectoryName = '.kanoli_backups'});

  final int maxBackups;
  final String backupDirectoryName;

  void writeTextAtomic({
    required String targetPath,
    required String content,
    bool createBackup = true,
  }) {
    final targetFile = File(targetPath);
    targetFile.parent.createSync(recursive: true);

    if (createBackup && targetFile.existsSync()) {
      try {
        _createBackup(targetFile);
      } on FileSystemException {
        // Backup is best-effort; writes must continue even when backup
        // directories cannot be created due to platform sandbox restrictions.
      }
    }

    final tempFile = File(
      '$targetPath.tmp.${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      tempFile.writeAsStringSync(content, flush: true);
      tempFile.renameSync(targetPath);
      return;
    } on FileSystemException {
      if (tempFile.existsSync()) {
        tempFile.copySync(targetPath);
        tempFile.deleteSync();
        return;
      }
      // If the sandbox blocks creating sibling temp files, fall back to
      // writing directly to the authorized target file path.
      final target = File(targetPath);
      target.writeAsStringSync(content, flush: true);
      return;
    }
  }

  void writeEmptyFileIfMissing(String targetPath) {
    final file = File(targetPath);
    if (file.existsSync()) {
      return;
    }
    writeTextAtomic(targetPath: targetPath, content: '', createBackup: false);
  }

  void deleteFile(String targetPath) {
    final file = File(targetPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  void _createBackup(File targetFile) {
    final backupDirectory = Directory(_backupDirectoryPathFor(targetFile.path));
    backupDirectory.createSync(recursive: true);

    final basename = targetFile.path.split(Platform.pathSeparator).last;
    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-');
    final backupFile = File('${backupDirectory.path}/$timestamp.$basename.bak');

    targetFile.copySync(backupFile.path);
    _trimBackups(backupDirectory);
  }

  String _backupDirectoryPathFor(String targetPath) {
    final normalized = File(targetPath).absolute.path;
    final key = _stableHashHex(normalized);
    final parent = File(targetPath).parent.path;
    return '$parent/$backupDirectoryName/$key';
  }

  void _trimBackups(Directory backupDirectory) {
    if (maxBackups < 1) {
      return;
    }

    final files = backupDirectory
        .listSync()
        .whereType<File>()
        .toList()
      ..sort((File a, File b) {
        final aMs = a.lastModifiedSync().millisecondsSinceEpoch;
        final bMs = b.lastModifiedSync().millisecondsSinceEpoch;
        return bMs.compareTo(aMs);
      });

    for (final stale in files.skip(maxBackups)) {
      stale.deleteSync();
    }
  }

  String _stableHashHex(String value) {
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
