// Core board domain model used by storage, filtering, and the board UI.
import 'board_formatters.dart';

export 'board_formatters.dart';

class BoardLoadResult {
  BoardLoadResult({required this.columns, this.errorMessage});

  final List<BoardColumn> columns;
  final String? errorMessage;
}

class BoardFilter {
  BoardFilter({
    this.dueDateRule = DueDateRule.any,
    this.labels = const <String>[],
  });

  final DueDateRule dueDateRule;
  final List<String> labels;

  bool get isActive => dueDateRule != DueDateRule.any || labels.isNotEmpty;

  bool matches(BoardItem item) {
    // Filters are additive: a card must match the due-date rule and all chosen
    // labels to appear in filtered results.
    return _matchesDueDate(item.dueDate) && _containsAll(labels, item.labels);
  }

  bool _matchesDueDate(DateTime? dueDate) {
    switch (dueDateRule) {
      case DueDateRule.any:
        return true;
      case DueDateRule.hasDueDate:
        return dueDate != null;
      case DueDateRule.noDueDate:
        return dueDate == null;
      case DueDateRule.dueToday:
        if (dueDate == null) {
          return false;
        }
        final now = DateTime.now();
        return dueDate.year == now.year &&
            dueDate.month == now.month &&
            dueDate.day == now.day;
      case DueDateRule.overdue:
        if (dueDate == null) {
          return false;
        }
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        return dueDate.isBefore(startOfToday);
    }
  }

  bool _containsAll(List<String> required, List<String> itemTerms) {
    if (required.isEmpty) {
      return true;
    }

    final normalized = itemTerms
        .map((String value) => value.toLowerCase())
        .toSet();
    return required.every(
      (String term) => normalized.contains(term.toLowerCase()),
    );
  }
}

enum DueDateRule { any, hasDueDate, noDueDate, dueToday, overdue }

class BoardColumn {
  BoardColumn({required this.title, List<BoardItem>? items, String? id})
    : id = id ?? IdGenerator.uuid(),
      items = items ?? <BoardItem>[];

  final String id;
  String title;
  List<BoardItem> items;

  String get menuTitle => title.trim().isEmpty ? 'Untitled column' : title;
}

class BoardItem {
  BoardItem({
    required this.title,
    List<BoardNote>? notes,
    List<BoardChecklist>? checklists,
    this.bodyMarkdown = '',
    this.dueDate,
    this.priority,
    List<String>? labels,
    String? id,
  }) : id = id ?? IdGenerator.uuid(),
       notes = notes ?? <BoardNote>[],
       checklists = checklists ?? <BoardChecklist>[],
       labels = labels ?? <String>[];

  final String id;
  String title;
  String bodyMarkdown;
  List<BoardNote> notes;
  List<BoardChecklist> checklists;
  DateTime? dueDate;
  String? priority;
  List<String> labels;

  String get displayTitle => title.isEmpty ? 'New item' : title;

  String get metadataSummary {
    final parts = <String>[];
    if (priority != null && priority!.isNotEmpty) {
      parts.add('(${priority!})');
    }
    parts.addAll(labels.map((String label) => '+$label'));
    if (dueDate != null) {
      parts.add('due:${TodoDateFormatter.format(dueDate!)}');
    }
    return parts.join(' ');
  }

  BoardItem duplicatedWithNewIds() {
    // Duplicates keep user-authored content but receive fresh IDs for the card
    // and nested checklist/note records.
    return BoardItem(
      title: title,
      bodyMarkdown: bodyMarkdown,
      notes: notes
          .map(
            (BoardNote note) =>
                BoardNote(createdAt: note.createdAt, text: note.text),
          )
          .toList(),
      checklists: checklists
          .map(
            (BoardChecklist checklist) => BoardChecklist(
              title: checklist.title,
              items: checklist.items
                  .map(
                    (BoardChecklistItem item) => BoardChecklistItem(
                      text: item.text,
                      isDone: item.isDone,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      dueDate: dueDate,
      priority: priority,
      labels: List<String>.from(labels),
    );
  }
}

class BoardChecklist {
  BoardChecklist({
    required this.title,
    List<BoardChecklistItem>? items,
    String? id,
  }) : id = id ?? IdGenerator.uuid(),
       items = items ?? <BoardChecklistItem>[];

  final String id;
  String title;
  List<BoardChecklistItem> items;
}

class BoardChecklistItem {
  BoardChecklistItem({required this.text, this.isDone = false, String? id})
    : id = id ?? IdGenerator.uuid();

  final String id;
  String text;
  bool isDone;
}

class BoardNote {
  BoardNote({required this.text, DateTime? createdAt, String? id})
    : id = id ?? IdGenerator.uuid(),
      createdAt = createdAt ?? DateTime.now();

  final String id;
  final DateTime createdAt;
  String text;
}

class TodoListEntry {
  TodoListEntry({
    required this.text,
    required this.isCompleted,
    this.completionDate,
    this.priority,
    this.dueDate,
    String? id,
  }) : id = id ?? IdGenerator.uuid();

  factory TodoListEntry.fromLine({
    required String line,
    required bool isCompleted,
    String? id,
  }) {
    // Parses the subset of todo.txt syntax Kanoli edits directly: completion
    // date, priority, text, and due date.
    final parts = line
        .split(' ')
        .where((String value) => value.isNotEmpty)
        .toList();
    DateTime? completionDate;
    String? priority;
    DateTime? dueDate;

    if (isCompleted && parts.isNotEmpty) {
      final parsed = TodoDateFormatter.tryParse(parts.first);
      if (parsed != null) {
        completionDate = parsed;
        parts.removeAt(0);
      }
    }

    if (parts.isNotEmpty &&
        parts.first.length == 3 &&
        parts.first.startsWith('(') &&
        parts.first.endsWith(')')) {
      priority = parts.first.substring(1, 2);
      parts.removeAt(0);
    }

    final textParts = <String>[];
    for (final part in parts) {
      if (part.startsWith('due:')) {
        dueDate = TodoDateFormatter.tryParse(part.substring(4));
      } else {
        textParts.add(part);
      }
    }

    return TodoListEntry(
      id: id,
      text: textParts.join(' '),
      isCompleted: isCompleted,
      completionDate: completionDate,
      priority: priority,
      dueDate: dueDate,
    );
  }

  final String id;
  String text;
  bool isCompleted;
  DateTime? completionDate;
  String? priority;
  DateTime? dueDate;

  String get priorityLabel => priority ?? '-';

  String get todoLine {
    final parts = <String>[];

    if (isCompleted && completionDate != null) {
      parts.add(TodoDateFormatter.format(completionDate!));
    }

    if (priority != null && priority!.isNotEmpty) {
      parts.add('($priority)');
    }

    parts.add(text);

    if (dueDate != null) {
      parts.add('due:${TodoDateFormatter.format(dueDate!)}');
    }

    return parts.join(' ');
  }
}
