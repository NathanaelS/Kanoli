import 'dart:io';

import '../../domain/board/board_entities.dart';
import 'safe_file_store.dart';

class TodoBoardParseResult {
  TodoBoardParseResult({
    required this.currentCardItems,
    required this.otherLines,
  });

  final List<TodoListEntry> currentCardItems;
  final List<String> otherLines;
}

class TodoBoardStore {
  TodoBoardStore({SafeFileStore? safeFileStore})
    : _safeFileStore = safeFileStore ?? SafeFileStore();

  final SafeFileStore _safeFileStore;

  String defaultTodoListPath({required String boardFilePath}) {
    final boardFile = File(boardFilePath);
    final directory = boardFile.parent.path;
    final filename = _sanitizeTodoListFilename(
      _basenameWithoutExtension(boardFile.path),
    );
    return '$directory/$filename.todo.txt';
  }

  String? existingTodoListPath(String todoListPath) {
    return File(todoListPath).existsSync() ? todoListPath : null;
  }

  void createTodoListIfNeeded(String todoListPath) {
    _safeFileStore.writeEmptyFileIfMissing(todoListPath);
  }

  String todoListPath({
    required String todoListFilePath,
    String? boardFilePath,
  }) {
    if (boardFilePath == null) {
      return File(todoListFilePath).absolute.path;
    }

    final boardDir = Directory(boardFilePath).parent.absolute.path;
    final todoFile = File(todoListFilePath).absolute;

    if (todoFile.parent.path == boardDir) {
      return _basename(todoListFilePath);
    }

    return todoFile.path;
  }

  TodoBoardParseResult parse({required String text, required String cardId}) {
    final currentCardItems = <TodoListEntry>[];
    final otherLines = <String>[];
    final rawLines = text.split('\n').toList();

    if (text.endsWith('\n') || text.endsWith('\r\n')) {
      rawLines.removeLast();
    }

    for (final rawLine in rawLines) {
      final line = rawLine.trim();

      if (line.isEmpty) {
        otherLines.add(rawLine);
        continue;
      }

      final isCompleted = line.startsWith('x ');
      final activeLine = isCompleted ? line.substring(2) : line;

      if (!_todoLineMatchesCardId(activeLine, cardId)) {
        otherLines.add(rawLine);
        continue;
      }

      currentCardItems.add(
        TodoListEntry.fromLine(
          line: _todoLineForCurrentCardEditor(activeLine),
          isCompleted: isCompleted,
        ),
      );
    }

    return TodoBoardParseResult(
      currentCardItems: currentCardItems,
      otherLines: otherLines,
    );
  }

  String serialize({
    required List<TodoListEntry> currentCardItems,
    required List<String> otherLines,
    required String cardId,
    String? columnContext,
  }) {
    final currentCardLines = currentCardItems
        .where((TodoListEntry item) => item.text.trim().isNotEmpty)
        .map(
          (TodoListEntry item) =>
              _serializedBoardTodoLine(item, cardId, columnContext),
        )
        .toList();

    final lines = <String>[...otherLines, ...currentCardLines];
    return lines.isEmpty ? '' : '${lines.join('\n')}\n';
  }

  void saveTodoList({
    required String todoListPath,
    required List<TodoListEntry> currentCardItems,
    required List<String> otherLines,
    required String cardId,
    String? columnContext,
  }) {
    final serialized = serialize(
      currentCardItems: currentCardItems,
      otherLines: otherLines,
      cardId: cardId,
      columnContext: columnContext,
    );

    _safeFileStore.writeTextAtomic(targetPath: todoListPath, content: serialized);
  }

  void deleteTodoList(String todoListPath) {
    _safeFileStore.deleteFile(todoListPath);
  }

  String _serializedBoardTodoLine(
    TodoListEntry item,
    String cardId,
    String? columnContext,
  ) {
    final parts = item.todoLine
        .split(' ')
        .where(
          (String part) =>
              part.isNotEmpty &&
              !part.startsWith('card:') &&
              !part.startsWith('@'),
        )
        .toList();

    parts.add('card:$cardId');
    if (columnContext != null && columnContext.isNotEmpty) {
      parts.add('@$columnContext');
    }

    final line = parts.join(' ');
    return item.isCompleted ? 'x $line' : line;
  }

  bool _todoLineMatchesCardId(String line, String cardId) {
    return line.split(' ').contains('card:$cardId');
  }

  String _todoLineForCurrentCardEditor(String line) {
    return line
        .split(' ')
        .where(
          (String part) =>
              part.isNotEmpty &&
              !part.startsWith('card:') &&
              !part.startsWith('@'),
        )
        .join(' ');
  }

  String _sanitizeTodoListFilename(String title) {
    final sanitized = title
        .replaceAll(RegExp(r'[/:\n\r\t]'), '-')
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();

    return sanitized.isEmpty ? 'Untitled Todo List' : sanitized;
  }

  String _basenameWithoutExtension(String path) {
    final base = _basename(path);
    final dot = base.lastIndexOf('.');
    return dot > 0 ? base.substring(0, dot) : base;
  }

  String _basename(String path) {
    return path.split(Platform.pathSeparator).last;
  }
}
