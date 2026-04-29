import 'dart:io';

class IoErrorFormatter {
  static String forOpen(String path, Object error) {
    if (error is FileSystemException) {
      return _format(
        title: 'Unable to open file',
        path: path,
        error: error,
        nextStep:
            'Confirm the file still exists and that Kanoli has permission to access this location.',
      );
    }
    return 'Unable to open file.\n$path\n$error';
  }

  static String forSave(String path, Object error) {
    if (error is FileSystemException) {
      return _format(
        title: 'Unable to save file',
        path: path,
        error: error,
        nextStep:
            'Choose a writable location or re-grant folder access in macOS and try again.',
      );
    }
    return 'Unable to save file.\n$path\n$error';
  }

  static String forImport(String path, Object error) {
    if (error is FileSystemException) {
      return _format(
        title: 'Unable to import file',
        path: path,
        error: error,
        nextStep:
            'Verify this is a valid JSON export and that Kanoli can read this location.',
      );
    }
    return 'Unable to import file.\n$path\n$error';
  }

  static String _format({
    required String title,
    required String path,
    required FileSystemException error,
    required String nextStep,
  }) {
    final reason = error.osError?.message ?? error.message;
    return '$title\n$path\nReason: $reason\nNext: $nextStep';
  }
}
