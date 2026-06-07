// Small parsing helpers for Kanoli Markdown headings, metadata, legacy notes,
// and checklist items.
import '../../domain/board/board_entities.dart';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const Set<String> _supportedPriorities = <String>{'A', 'B', 'C', 'D'};

String? headerContent(String line, int level) {
  final prefix = List<String>.filled(level, '#').join();
  if (line == prefix || line.startsWith('$prefix ')) {
    return line.substring(level).trim();
  }
  return null;
}

String? noteContent(String line) {
  if (!line.startsWith('>')) {
    return null;
  }
  return line.substring(1).trim();
}

BoardItem parseLegacyCardHeading(String line) {
  // Legacy card headings combine priority, title, labels, due date, and ID in
  // one compact line.
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
      final parsed = part.substring(1, 2).toUpperCase();
      if (_supportedPriorities.contains(parsed)) {
        priority = parsed;
      }
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

KanoliMetadata? parseKanoliMetadata(String line) {
  if (!line.startsWith('kanoli:')) {
    return null;
  }

  final remainder = line.substring(7);
  final firstSpace = remainder.indexOf(' ');
  if (firstSpace < 0) {
    return KanoliMetadata(remainder.trim().toLowerCase(), '');
  }

  return KanoliMetadata(
    remainder.substring(0, firstSpace).trim().toLowerCase(),
    remainder.substring(firstSpace + 1).trim(),
  );
}

void applyItemMetadata({
  required String key,
  required String value,
  required BoardColumn column,
  required int itemIndex,
}) {
  // v2 metadata lives under the card heading. Unknown keys are ignored so
  // future metadata can be introduced safely.
  final item = column.items[itemIndex];
  switch (key) {
    case 'id':
      if (value.isEmpty) {
        return;
      }
      column.items[itemIndex] = BoardItem(
        id: value,
        title: item.title,
        bodyMarkdown: item.bodyMarkdown,
        notes: item.notes,
        checklists: item.checklists,
        startDate: item.startDate,
        dueDate: item.dueDate,
        priority: item.priority,
        labels: item.labels,
      );
      return;
    case 'priority':
      final priority = value.toUpperCase();
      item.priority = _supportedPriorities.contains(priority) ? priority : null;
      return;
    case 'labels':
      item.labels = value
          .split(',')
          .map((String label) => label.trim())
          .where((String label) => label.isNotEmpty)
          .toList();
      return;
    case 'due':
      item.dueDate = TodoDateFormatter.tryParse(value);
      return;
    case 'start':
      item.startDate = TodoDateFormatter.tryParse(value);
      return;
  }
}

String? setCurrentChecklistId({
  required BoardColumn column,
  required int itemIndex,
  required String? currentChecklistId,
  required String newChecklistId,
}) {
  // A checklist ID line belongs to the most recently opened checklist section.
  if (newChecklistId.isEmpty || !_uuidPattern.hasMatch(newChecklistId)) {
    return currentChecklistId;
  }

  final checklistIndex = currentChecklistId == null
      ? column.items[itemIndex].checklists.length - 1
      : column.items[itemIndex].checklists.indexWhere(
          (BoardChecklist checklist) => checklist.id == currentChecklistId,
        );
  if (checklistIndex < 0) {
    return currentChecklistId;
  }

  final checklist = column.items[itemIndex].checklists[checklistIndex];
  column.items[itemIndex].checklists[checklistIndex] = BoardChecklist(
    id: newChecklistId,
    title: checklist.title,
    items: checklist.items,
  );
  return newChecklistId;
}

BoardNote? parseLegacyNote(String line) {
  if (!line.startsWith('note:')) {
    return null;
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

BoardChecklist? parseLegacyChecklist(String line) {
  if (!line.startsWith('checklist:')) {
    return null;
  }

  final remainder = line.substring(10);
  final firstSpace = remainder.indexOf(' ');
  final idPart =
      (firstSpace < 0 ? remainder : remainder.substring(0, firstSpace)).trim();

  if (idPart.isEmpty || !_uuidPattern.hasMatch(idPart)) {
    return null;
  }

  final title = firstSpace < 0
      ? 'Checklist'
      : remainder.substring(firstSpace + 1);
  return BoardChecklist(id: idPart, title: title);
}

BoardChecklistItem? parseLegacyChecklistItem(String line) {
  if (line.startsWith('checklist-item:')) {
    return _parseLegacyChecklistItemWithPrefix(line);
  }

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

BoardChecklistItem? _parseLegacyChecklistItemWithPrefix(String line) {
  final uncheckedIndex = line.indexOf(':[ ]');
  if (uncheckedIndex >= 0) {
    return BoardChecklistItem(text: line.substring(uncheckedIndex + 4).trim());
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

BoardChecklistItem? parseReadableChecklistItem(String line) {
  if (line.startsWith('- [ ]')) {
    return BoardChecklistItem(text: line.substring(5).trim());
  }

  if (line.startsWith('- [x]')) {
    return BoardChecklistItem(text: line.substring(5).trim(), isDone: true);
  }

  if (line.startsWith('- [X]')) {
    return BoardChecklistItem(text: line.substring(5).trim(), isDone: true);
  }

  return null;
}

String? appendChecklistItem({
  required BoardChecklistItem checklistItem,
  required BoardColumn column,
  required int itemIndex,
  required String? checklistId,
}) {
  // Legacy item lines may appear without an explicit checklist header. In that
  // case Kanoli creates a default checklist to preserve the item.
  var currentChecklistId = checklistId;

  if (currentChecklistId == null) {
    final checklist = BoardChecklist(title: 'Checklist');
    column.items[itemIndex].checklists.add(checklist);
    currentChecklistId = checklist.id;
  }

  final checklistIndex = column.items[itemIndex].checklists.indexWhere(
    (BoardChecklist checklist) => checklist.id == currentChecklistId,
  );
  if (checklistIndex < 0) {
    return currentChecklistId;
  }

  column.items[itemIndex].checklists[checklistIndex].items.add(checklistItem);
  return currentChecklistId;
}

class KanoliMetadata {
  KanoliMetadata(this.key, this.value);

  final String key;
  final String value;
}
