// Reads and writes card-scoped todo.txt sidecar files while preserving todo
// lines owned by other cards or external tools.
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

class TodoBoardItemCounts {
  const TodoBoardItemCounts({
    required this.total,
    required this.completed,
    required this.overdue,
  });

  final int total;
  final int completed;
  final int overdue;
}

class TodoBoardStore {
  TodoBoardStore({SafeFileStore? safeFileStore})
    : _safeFileStore = safeFileStore ?? SafeFileStore();

  final SafeFileStore _safeFileStore;

  String defaultTodoListPath({required String boardFilePath}) {
    // Sidecar todo lists live beside the board by default and use the board
    // filename so users can recognize them outside Kanoli.
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

    // Keep non-card lines untouched so Kanoli can share a todo.txt file with
    // manual entries or other card-scoped tasks.
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

  Map<String, TodoBoardItemCounts> countsByCardId({required String text}) {
    final counts = <String, TodoBoardItemCounts>{};
    final rawLines = text.split('\n').toList();

    if (text.endsWith('\n') || text.endsWith('\r\n')) {
      rawLines.removeLast();
    }

    for (final rawLine in rawLines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final isCompleted = line.startsWith('x ');
      final activeLine = isCompleted ? line.substring(2) : line;
      final cardId = _cardIdForTodoLine(activeLine);
      if (cardId == null || cardId.isEmpty) {
        continue;
      }

      final todoEntry = TodoListEntry.fromLine(
        line: _todoLineForCurrentCardEditor(activeLine),
        isCompleted: isCompleted,
      );

      final current =
          counts[cardId] ??
          const TodoBoardItemCounts(total: 0, completed: 0, overdue: 0);
      counts[cardId] = TodoBoardItemCounts(
        total: current.total + 1,
        completed: current.completed + (isCompleted ? 1 : 0),
        overdue: current.overdue + (todoEntry.isOverdue ? 1 : 0),
      );
    }

    return counts;
  }

  Map<String, List<String>> searchableTextByCardId({required String text}) {
    final textByCardId = <String, List<String>>{};
    final rawLines = text.split('\n').toList();

    if (text.endsWith('\n') || text.endsWith('\r\n')) {
      rawLines.removeLast();
    }

    for (final rawLine in rawLines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final isCompleted = line.startsWith('x ');
      final activeLine = isCompleted ? line.substring(2) : line;
      final cardId = _cardIdForTodoLine(activeLine);
      if (cardId == null || cardId.isEmpty) {
        continue;
      }

      final todoEntry = TodoListEntry.fromLine(
        line: _todoLineForCurrentCardEditor(activeLine),
        isCompleted: isCompleted,
      );
      if (todoEntry.text.trim().isEmpty) continue;

      textByCardId.putIfAbsent(cardId, () => <String>[]).add(todoEntry.text);
    }

    return textByCardId;
  }

  String serialize({
    required List<TodoListEntry> currentCardItems,
    required List<String> otherLines,
    required String cardId,
    String? columnContext,
  }) {
    // Rebuild only the current card's lines and append them after preserved
    // external lines.
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

    _safeFileStore.writeTextAtomic(
      targetPath: todoListPath,
      content: serialized,
    );
  }

  void deleteTodoList(String todoListPath) {
    _safeFileStore.deleteFile(todoListPath);
  }

  String _serializedBoardTodoLine(
    TodoListEntry item,
    String cardId,
    String? columnContext,
  ) {
    // Strip stale card/column tags before writing the current association.
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

  String? _cardIdForTodoLine(String line) {
    for (final part in line.split(' ')) {
      if (part.startsWith('card:') && part.length > 5) {
        return part.substring(5);
      }
    }
    return null;
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
