import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/data/board/safe_file_store.dart';

void main() {
  group('SafeFileStore', () {
    test('writes atomically and creates backups capped by maxBackups', () {
      final tempDir = Directory.systemTemp.createTempSync('kanoli_safe_store_');
      final filePath = '${tempDir.path}/board.md';
      final store = SafeFileStore(maxBackups: 2);

      store.writeTextAtomic(targetPath: filePath, content: 'v1');
      store.writeTextAtomic(targetPath: filePath, content: 'v2');
      store.writeTextAtomic(targetPath: filePath, content: 'v3');
      store.writeTextAtomic(targetPath: filePath, content: 'v4');

      expect(File(filePath).readAsStringSync(), 'v4');

      final backupRoot = Directory('${tempDir.path}/.kanoli_backups');
      expect(backupRoot.existsSync(), isTrue);

      final backupDirs = backupRoot
          .listSync()
          .whereType<Directory>()
          .toList();
      expect(backupDirs.length, 1);

      final backups = backupDirs.single
          .listSync()
          .whereType<File>()
          .toList();
      expect(backups.length, 2);
    });

    test('writeEmptyFileIfMissing creates file only once', () {
      final tempDir = Directory.systemTemp.createTempSync('kanoli_safe_empty_');
      final filePath = '${tempDir.path}/todos.txt';
      final store = SafeFileStore(maxBackups: 2);

      store.writeEmptyFileIfMissing(filePath);
      expect(File(filePath).existsSync(), isTrue);
      expect(File(filePath).readAsStringSync(), isEmpty);

      File(filePath).writeAsStringSync('existing');
      store.writeEmptyFileIfMissing(filePath);
      expect(File(filePath).readAsStringSync(), 'existing');
    });
  });
}
