import 'dart:io';

import '../../domain/board/board_entities.dart';

class MarkdownBoardStore {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  BoardLoadResult loadBoard(String filePath) {
    final file = File(filePath);

    if (!file.existsSync()) {
      return BoardLoadResult(
        columns: <BoardColumn>[],
        errorMessage: 'File not found.',
      );
    }

    try {
      final markdown = file.readAsStringSync();
      return BoardLoadResult(columns: parse(markdown));
    } on FileSystemException catch (error) {
      return BoardLoadResult(
        columns: <BoardColumn>[],
        errorMessage: error.message,
      );
    }
  }

  void save({required List<BoardColumn> columns, required String filePath}) {
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(serialize(columns));
  }

  List<BoardColumn> parse(String markdown) {
    final parsedColumns = <BoardColumn>[];
    BoardColumn? currentColumn;
    String? currentItemId;
    String? currentChecklistId;

    for (final rawLine in markdown.split('\n')) {
      final line = rawLine.trim();

      final itemTitle = _headerContent(line, 2);
      if (itemTitle != null) {
        if (currentColumn == null) {
          continue;
        }

        final item = _parseTodoItem(itemTitle);
        currentColumn.items.add(item);
        currentItemId = item.id;
        currentChecklistId = null;
        continue;
      }

      final columnTitle = _headerContent(line, 1);
      if (columnTitle != null) {
        if (currentColumn != null) {
          parsedColumns.add(currentColumn);
        }

        currentColumn = BoardColumn(title: columnTitle);
        currentItemId = null;
        currentChecklistId = null;
        continue;
      }

      final noteLine = _noteContent(line);
      if (currentItemId != null && noteLine != null && currentColumn != null) {
        final itemIndex = currentColumn.items.indexWhere(
          (BoardItem item) => item.id == currentItemId,
        );
        if (itemIndex < 0) {
          continue;
        }

        final checklist = _parseChecklist(noteLine);
        if (checklist != null) {
          currentColumn.items[itemIndex].checklists.add(checklist);
          currentChecklistId = checklist.id;
          continue;
        }

        final checklistItem = _parseChecklistItem(noteLine);
        if (checklistItem != null) {
          _appendChecklistItem(
            checklistItem: checklistItem,
            column: currentColumn,
            itemIndex: itemIndex,
            checklistId: currentChecklistId,
            onChecklistIdChanged: (String value) => currentChecklistId = value,
          );
          continue;
        }

        final legacyChecklistItem = _parseLegacyChecklistItem(noteLine);
        if (legacyChecklistItem != null) {
          _appendLegacyChecklistItem(
            checklistItem: legacyChecklistItem,
            column: currentColumn,
            itemIndex: itemIndex,
            checklistId: currentChecklistId,
            onChecklistIdChanged: (String value) => currentChecklistId = value,
          );
          continue;
        }

        currentColumn.items[itemIndex].notes.add(_parseNote(noteLine));
      }
    }

    if (currentColumn != null) {
      parsedColumns.add(currentColumn);
    }

    return parsedColumns;
  }

  String serialize(List<BoardColumn> columns) {
    return columns
        .map((BoardColumn column) {
          final lines = <String>['# ${column.title}'];

          for (final item in column.items) {
            lines.add('## ${_todoLine(item)}');

            for (final note in item.notes.where(
              (BoardNote note) => note.text.trim().isNotEmpty,
            )) {
              final createdAt = NoteDateFormatter.format(note.createdAt);
              final noteLines = note.text
                  .split('\n')
                  .map((String text) => '> note:$createdAt $text');
              lines.addAll(noteLines);
            }

            for (final checklist in item.checklists.where((
              BoardChecklist checklist,
            ) {
              final hasTitle = checklist.title.trim().isNotEmpty;
              final hasAnyItem = checklist.items.any(
                (BoardChecklistItem item) => item.text.trim().isNotEmpty,
              );
              return hasTitle || hasAnyItem;
            })) {
              lines.add('> checklist:${checklist.id} ${checklist.title}');
              for (final checklistItem in checklist.items.where(
                (BoardChecklistItem item) => item.text.trim().isNotEmpty,
              )) {
                final marker = checklistItem.isDone ? 'x' : ' ';
                lines.add(
                  '> checklist-item:${checklist.id}:[$marker] ${checklistItem.text}',
                );
              }
            }
          }

          return lines.join('\n');
        })
        .join('\n\n');
  }

  String? _headerContent(String line, int level) {
    final prefix = List<String>.filled(level, '#').join();
    if (line == prefix || line.startsWith('$prefix ')) {
      return line.substring(level).trim();
    }
    return null;
  }

  BoardItem _parseTodoItem(String line) {
    final parts = line
        .split(' ')
        .where((String value) => value.isNotEmpty)
        .toList();
    final titleParts = <String>[];
    String? priority;
    DateTime? dueDate;
    final labels = <String>[];
    var id = IdGenerator.uuid();

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i == 0 &&
          part.length == 3 &&
          part.startsWith('(') &&
          part.endsWith(')')) {
        priority = part.substring(1, 2);
      } else if (part.startsWith('+')) {
        labels.add(part.substring(1));
      } else if (part.startsWith('due:')) {
        dueDate = TodoDateFormatter.tryParse(part.substring(4));
      } else if (part.startsWith('id:')) {
        id = part.substring(3);
      } else if (part.startsWith('todo:')) {
        continue;
      } else {
        titleParts.add(part);
      }
    }

    return BoardItem(
      id: id,
      title: titleParts.join(' '),
      notes: <BoardNote>[],
      checklists: <BoardChecklist>[],
      dueDate: dueDate,
      priority: priority,
      labels: labels,
    );
  }

  String _todoLine(BoardItem item) {
    final parts = <String>[];

    if (item.priority != null && item.priority!.isNotEmpty) {
      parts.add('(${item.priority})');
    }

    parts.add(item.title);
    parts.addAll(
      item.labels
          .map(_normalizedTag)
          .where((String value) => value.isNotEmpty)
          .map((String value) => '+$value'),
    );

    if (item.dueDate != null) {
      parts.add('due:${TodoDateFormatter.format(item.dueDate!)}');
    }

    parts.add('id:${item.id}');
    return parts.join(' ');
  }

  String _normalizedTag(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .join('-');
  }

  String? _noteContent(String line) {
    if (!line.startsWith('>')) {
      return null;
    }
    return line.substring(1).trim();
  }

  BoardNote _parseNote(String line) {
    if (!line.startsWith('note:')) {
      return BoardNote(text: line);
    }

    final remainder = line.substring(5);
    final firstSpace = remainder.indexOf(' ');
    if (firstSpace < 0) {
      return BoardNote(text: line);
    }

    final datePart = remainder.substring(0, firstSpace);
    final textPart = remainder.substring(firstSpace + 1);
    final createdAt = NoteDateFormatter.tryParse(datePart);

    if (createdAt == null) {
      return BoardNote(text: line);
    }

    return BoardNote(createdAt: createdAt, text: textPart);
  }

  BoardChecklist? _parseChecklist(String line) {
    if (!line.startsWith('checklist:')) {
      return null;
    }

    final remainder = line.substring(10);
    final firstSpace = remainder.indexOf(' ');
    final idPart =
        (firstSpace < 0 ? remainder : remainder.substring(0, firstSpace))
            .trim();

    if (idPart.isEmpty || !_uuidPattern.hasMatch(idPart)) {
      return null;
    }

    final title = firstSpace < 0
        ? 'Checklist'
        : remainder.substring(firstSpace + 1);
    return BoardChecklist(id: idPart, title: title);
  }

  BoardChecklistItem? _parseChecklistItem(String line) {
    if (!line.startsWith('checklist-item:')) {
      return null;
    }

    final uncheckedIndex = line.indexOf(':[ ]');
    if (uncheckedIndex >= 0) {
      return BoardChecklistItem(
        text: line.substring(uncheckedIndex + 4).trim(),
      );
    }

    final checkedIndex = line.indexOf(':[x]');
    if (checkedIndex >= 0) {
      return BoardChecklistItem(
        text: line.substring(checkedIndex + 4).trim(),
        isDone: true,
      );
    }

    final checkedUpperIndex = line.indexOf(':[X]');
    if (checkedUpperIndex >= 0) {
      return BoardChecklistItem(
        text: line.substring(checkedUpperIndex + 4).trim(),
        isDone: true,
      );
    }

    return null;
  }

  BoardChecklistItem? _parseLegacyChecklistItem(String line) {
    if (line.startsWith('checklist:[ ]')) {
      return BoardChecklistItem(
        text: line.substring('checklist:[ ]'.length).trim(),
      );
    }

    if (line.startsWith('checklist:[x]')) {
      return BoardChecklistItem(
        text: line.substring('checklist:[x]'.length).trim(),
        isDone: true,
      );
    }

    if (line.startsWith('checklist:[X]')) {
      return BoardChecklistItem(
        text: line.substring('checklist:[X]'.length).trim(),
        isDone: true,
      );
    }

    return null;
  }

  void _appendChecklistItem({
    required BoardChecklistItem checklistItem,
    required BoardColumn column,
    required int itemIndex,
    required String? checklistId,
    required void Function(String value) onChecklistIdChanged,
  }) {
    if (checklistId == null) {
      _appendLegacyChecklistItem(
        checklistItem: checklistItem,
        column: column,
        itemIndex: itemIndex,
        checklistId: checklistId,
        onChecklistIdChanged: onChecklistIdChanged,
      );
      return;
    }

    final checklistIndex = column.items[itemIndex].checklists.indexWhere(
      (BoardChecklist checklist) => checklist.id == checklistId,
    );

    if (checklistIndex < 0) {
      _appendLegacyChecklistItem(
        checklistItem: checklistItem,
        column: column,
        itemIndex: itemIndex,
        checklistId: checklistId,
        onChecklistIdChanged: onChecklistIdChanged,
      );
      return;
    }

    column.items[itemIndex].checklists[checklistIndex].items.add(checklistItem);
  }

  void _appendLegacyChecklistItem({
    required BoardChecklistItem checklistItem,
    required BoardColumn column,
    required int itemIndex,
    required String? checklistId,
    required void Function(String value) onChecklistIdChanged,
  }) {
    var currentChecklistId = checklistId;

    if (currentChecklistId == null) {
      final checklist = BoardChecklist(title: 'Checklist');
      column.items[itemIndex].checklists.add(checklist);
      currentChecklistId = checklist.id;
      onChecklistIdChanged(currentChecklistId);
    }

    final checklistIndex = column.items[itemIndex].checklists.indexWhere(
      (BoardChecklist checklist) => checklist.id == currentChecklistId,
    );
    if (checklistIndex < 0) {
      return;
    }

    column.items[itemIndex].checklists[checklistIndex].items.add(checklistItem);
  }
}
