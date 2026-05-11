import '../../domain/board/board_entities.dart';

class MarkdownBoardSerializer {
  String serialize(List<BoardColumn> columns) {
    final lines = <String>[];

    for (final column in columns) {
      _addSeparated(lines, '# ${column.title}');

      for (final item in column.items) {
        _addSeparated(lines, '## ${item.title}');
        lines.add('> kanoli:id ${item.id}');
        _addItemMetadata(lines, item);
        _addBody(lines, item);
        _addNotes(lines, item);
        _addChecklists(lines, item);
      }
    }

    return '${lines.join('\n')}\n';
  }

  void _addItemMetadata(List<String> lines, BoardItem item) {
    if (item.priority != null && item.priority!.isNotEmpty) {
      lines.add('> kanoli:priority ${item.priority}');
    }

    final labels = item.labels
        .map(_normalizedTag)
        .where((String value) => value.isNotEmpty)
        .toList();
    if (labels.isNotEmpty) {
      lines.add('> kanoli:labels ${labels.join(', ')}');
    }

    if (item.dueDate != null) {
      lines.add('> kanoli:due ${TodoDateFormatter.format(item.dueDate!)}');
    }
  }

  void _addBody(List<String> lines, BoardItem item) {
    final body = item.bodyMarkdown.trimRight();
    if (body.isEmpty) {
      return;
    }

    _addSeparated(lines, body);
  }

  void _addNotes(List<String> lines, BoardItem item) {
    final notes = item.notes
        .where((BoardNote note) => note.text.trim().isNotEmpty)
        .toList();
    if (notes.isEmpty) {
      return;
    }

    _addSeparated(lines, '### Notes');
    for (final note in notes) {
      _addSeparated(lines, '#### ${NoteDateFormatter.format(note.createdAt)}');
      lines.addAll(note.text.split('\n'));
    }
  }

  void _addChecklists(List<String> lines, BoardItem item) {
    for (final checklist in item.checklists.where(_hasChecklistContent)) {
      _addSeparated(lines, '### ${checklist.title}');
      lines.add('> kanoli:checklist ${checklist.id}');
      for (final checklistItem in checklist.items.where(
        (BoardChecklistItem item) => item.text.trim().isNotEmpty,
      )) {
        final marker = checklistItem.isDone ? 'x' : ' ';
        lines.add('- [$marker] ${checklistItem.text}');
      }
    }
  }

  bool _hasChecklistContent(BoardChecklist checklist) {
    return checklist.title.trim().isNotEmpty ||
        checklist.items.any(
          (BoardChecklistItem item) => item.text.trim().isNotEmpty,
        );
  }

  void _addSeparated(List<String> lines, String value) {
    if (lines.isNotEmpty && lines.last.isNotEmpty) {
      lines.add('');
    }
    lines.add(value);
  }

  String _normalizedTag(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .join('-');
  }
}
