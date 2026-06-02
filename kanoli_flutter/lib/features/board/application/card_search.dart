// Pure active-board card search used by the command palette.
import '../../../domain/board/board_entities.dart';

enum CardSearchMatchKind { title, label, dueDate, checklist, note, todo }

class CardSearchResult {
  const CardSearchResult({
    required this.itemId,
    required this.title,
    required this.columnTitle,
    required this.matchKinds,
    this.boardTitle,
    this.boardTabId,
  });

  final String itemId;
  final String title;
  final String columnTitle;
  final List<CardSearchMatchKind> matchKinds;
  final String? boardTitle;
  final String? boardTabId;
}

List<CardSearchResult> searchBoardCards({
  required List<BoardColumn> columns,
  required String query,
  Map<String, List<String>> todoTextByCardId = const <String, List<String>>{},
  String? boardTitle,
  String? boardTabId,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return const <CardSearchResult>[];
  }

  final results = <CardSearchResult>[];
  for (final column in columns) {
    for (final item in column.items) {
      final matchKinds = _matchKindsForItem(
        item: item,
        query: _CardSearchQuery(normalizedQuery),
        todoText: todoTextByCardId[item.id] ?? const <String>[],
      );
      if (matchKinds.isEmpty) {
        continue;
      }

      results.add(
        CardSearchResult(
          itemId: item.id,
          title: item.displayTitle,
          columnTitle: column.menuTitle,
          matchKinds: matchKinds,
          boardTitle: boardTitle,
          boardTabId: boardTabId,
        ),
      );
    }
  }

  results.sort((CardSearchResult a, CardSearchResult b) {
    return a.matchKinds.first.index.compareTo(b.matchKinds.first.index);
  });
  return results;
}

List<CardSearchResult> searchOpenBoardCards({
  required List<CardSearchBoard> boards,
  required String query,
  Map<String, List<String>> todoTextByCardId = const <String, List<String>>{},
}) {
  final results = <CardSearchResult>[];
  for (final board in boards) {
    results.addAll(
      searchBoardCards(
        columns: board.columns,
        query: query,
        todoTextByCardId: todoTextByCardId,
        boardTitle: board.title,
        boardTabId: board.tabId,
      ),
    );
  }
  results.sort((CardSearchResult a, CardSearchResult b) {
    return a.matchKinds.first.index.compareTo(b.matchKinds.first.index);
  });
  return results;
}

class CardSearchBoard {
  const CardSearchBoard({
    required this.title,
    required this.tabId,
    required this.columns,
  });

  final String title;
  final String tabId;
  final List<BoardColumn> columns;
}

List<CardSearchMatchKind> _matchKindsForItem({
  required BoardItem item,
  required _CardSearchQuery query,
  required List<String> todoText,
}) {
  final matches = <CardSearchMatchKind>[];

  if (query.matchesText(item.title)) {
    matches.add(CardSearchMatchKind.title);
  }
  if (item.labels.any(query.matchesLabel)) {
    matches.add(CardSearchMatchKind.label);
  }
  if (query.matchesDueDate(item.dueDate)) {
    matches.add(CardSearchMatchKind.dueDate);
  }
  if (_checklistsContain(item.checklists, query)) {
    matches.add(CardSearchMatchKind.checklist);
  }
  if (query.matchesText(item.bodyMarkdown) ||
      item.notes.any((BoardNote note) => query.matchesText(note.text))) {
    matches.add(CardSearchMatchKind.note);
  }
  if (todoText.any(query.matchesText)) {
    matches.add(CardSearchMatchKind.todo);
  }

  return matches;
}

bool _checklistsContain(
  List<BoardChecklist> checklists,
  _CardSearchQuery query,
) {
  for (final checklist in checklists) {
    if (query.matchesText(checklist.title)) {
      return true;
    }
    if (checklist.items.any((BoardChecklistItem item) {
      return query.matchesText(item.text);
    })) {
      return true;
    }
  }
  return false;
}

class _CardSearchQuery {
  _CardSearchQuery(String value)
    : text = value,
      labelText = value.startsWith('+') ? value.substring(1) : value,
      dueDateText = value.startsWith('due:') ? value.substring(4) : value;

  final String text;
  final String labelText;
  final String dueDateText;

  bool matchesText(String value) {
    return value.toLowerCase().contains(text);
  }

  bool matchesLabel(String label) {
    if (labelText.isEmpty) {
      return false;
    }
    return label.toLowerCase().contains(labelText);
  }

  bool matchesDueDate(DateTime? dueDate) {
    if (dueDate == null || dueDateText.isEmpty) {
      return false;
    }
    return TodoDateFormatter.format(dueDate).contains(dueDateText);
  }
}
