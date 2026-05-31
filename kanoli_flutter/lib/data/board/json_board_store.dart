// Imports Kanoli JSON and Trello JSON exports, normalizing both into board
// columns that can be saved as Kanoli Markdown.
import 'dart:convert';
import 'dart:io';

import '../../domain/board/board_entities.dart';
import 'markdown_board_store.dart';

class JsonBoardImportException implements Exception {
  JsonBoardImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JsonBoardStore {
  JsonBoardStore({MarkdownBoardStore? markdownBoardStore})
    : _markdownBoardStore = markdownBoardStore ?? MarkdownBoardStore();

  final MarkdownBoardStore _markdownBoardStore;

  void importBoard({required String jsonPath, required String boardPath}) {
    final data = File(jsonPath).readAsStringSync();
    final columns = decodeBoard(data);
    _markdownBoardStore.save(columns: columns, filePath: boardPath);
  }

  List<BoardColumn> loadBoard(String filePath) {
    final data = File(filePath).readAsStringSync();
    return decodeBoard(data);
  }

  List<BoardColumn> decodeBoard(String data) {
    final decoded = jsonDecode(data);
    if (decoded is! Map<String, dynamic>) {
      throw JsonBoardImportException(
        'Unsupported JSON format. Expected Kanoli export or Trello board export.',
      );
    }

    if (decoded.containsKey('columns')) {
      return _decodeImportedBoard(decoded);
    }

    if (decoded.containsKey('lists') && decoded.containsKey('cards')) {
      return _decodeTrelloBoard(decoded);
    }

    throw JsonBoardImportException(
      'Unsupported JSON format. Expected Kanoli export or Trello board export.',
    );
  }

  List<BoardColumn> _decodeImportedBoard(Map<String, dynamic> json) {
    // Kanoli JSON mirrors the domain model, so this path mainly validates
    // loose JSON values and restores dates, notes, and checklist state.
    final rawColumns = (json['columns'] as List<dynamic>? ?? <dynamic>[]);

    return rawColumns.whereType<Map<String, dynamic>>().map((
      Map<String, dynamic> rawColumn,
    ) {
      final rawItems = rawColumn['items'] as List<dynamic>? ?? <dynamic>[];
      final items = rawItems.whereType<Map<String, dynamic>>().map((
        Map<String, dynamic> rawItem,
      ) {
        final rawNotes = rawItem['notes'] as List<dynamic>? ?? <dynamic>[];
        final notes = rawNotes.map((dynamic rawNote) {
          if (rawNote is String) {
            return BoardNote(text: rawNote);
          }

          if (rawNote is Map<String, dynamic>) {
            final createdAt = rawNote['createdAt'] is String
                ? NoteDateFormatter.tryParse(rawNote['createdAt'] as String)
                : null;
            return BoardNote(
              text: (rawNote['text'] ?? '').toString(),
              createdAt: createdAt,
            );
          }

          return BoardNote(text: rawNote.toString());
        }).toList();

        final rawChecklists =
            rawItem['checklists'] as List<dynamic>? ?? <dynamic>[];
        final checklists = rawChecklists.whereType<Map<String, dynamic>>().map((
          Map<String, dynamic> rawChecklist,
        ) {
          final rawChecklistItems =
              rawChecklist['items'] as List<dynamic>? ?? <dynamic>[];
          final checklistItems = rawChecklistItems
              .whereType<Map<String, dynamic>>()
              .map(
                (Map<String, dynamic> rawChecklistItem) => BoardChecklistItem(
                  id: rawChecklistItem['id']?.toString(),
                  text: (rawChecklistItem['text'] ?? '').toString(),
                  isDone: rawChecklistItem['isDone'] == true,
                ),
              )
              .toList();

          return BoardChecklist(
            id: rawChecklist['id']?.toString(),
            title: (rawChecklist['title'] ?? '').toString(),
            items: checklistItems,
          );
        }).toList();

        final dueDateValue = rawItem['dueDate']?.toString();
        final dueDate = dueDateValue == null
            ? null
            : TodoDateFormatter.tryParse(dueDateValue);
        if (dueDateValue != null && dueDate == null) {
          throw JsonBoardImportException(
            'Expected date formatted as yyyy-MM-dd.',
          );
        }

        return BoardItem(
          id: rawItem['id']?.toString(),
          title: (rawItem['title'] ?? '').toString(),
          notes: notes,
          checklists: checklists,
          dueDate: dueDate,
          priority: rawItem['priority']?.toString(),
          labels: (rawItem['labels'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic value) => value.toString())
              .toList(),
        );
      }).toList();

      return BoardColumn(
        title: (rawColumn['title'] ?? '').toString(),
        items: items,
      );
    }).toList();
  }

  List<BoardColumn> _decodeTrelloBoard(Map<String, dynamic> json) {
    // Trello exports are relationship-heavy. Build lookup maps first so cards
    // can be assembled in list order with labels, comments, and checklists.
    final lists = (json['lists'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final cards = (json['cards'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final checklists = (json['checklists'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final labels = (json['labels'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final actions = (json['actions'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    final labelsById = <String, String>{
      for (final label in labels)
        if (label['id'] != null)
          label['id'].toString(): (label['name'] ?? '').toString(),
    };

    final checklistByCardId = <String, List<Map<String, dynamic>>>{};
    for (final checklist in checklists) {
      final cardId = checklist['idCard']?.toString();
      if (cardId == null) {
        continue;
      }
      checklistByCardId
          .putIfAbsent(cardId, () => <Map<String, dynamic>>[])
          .add(checklist);
    }

    final commentsByCardId = <String, List<_TrelloComment>>{};
    for (final action in actions) {
      if (action['type']?.toString() != 'commentCard') {
        continue;
      }

      final data = action['data'];
      if (data is! Map<String, dynamic>) {
        continue;
      }

      final cardData = data['card'];
      final cardId = cardData is Map<String, dynamic>
          ? cardData['id']?.toString()
          : null;
      final text = data['text']?.toString();
      final date = DateTime.tryParse((action['date'] ?? '').toString());

      if (cardId == null ||
          text == null ||
          text.trim().isEmpty ||
          date == null) {
        continue;
      }

      commentsByCardId
          .putIfAbsent(cardId, () => <_TrelloComment>[])
          .add(_TrelloComment(cardId: cardId, text: text, date: date));
    }

    final cardsByListId = <String, List<Map<String, dynamic>>>{};
    for (final card in cards) {
      final listId = card['idList']?.toString();
      if (listId == null) {
        continue;
      }
      cardsByListId
          .putIfAbsent(listId, () => <Map<String, dynamic>>[])
          .add(card);
    }

    lists.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final pa = (a['pos'] as num?)?.toDouble() ?? 0;
      final pb = (b['pos'] as num?)?.toDouble() ?? 0;
      return pa.compareTo(pb);
    });

    final closedListIds = lists
        .where((Map<String, dynamic> list) => _isTrelloClosed(list))
        .map((Map<String, dynamic> list) => list['id']?.toString())
        .whereType<String>()
        .toSet();
    final listPositionById = <String, double>{
      for (final list in lists)
        if (list['id'] != null)
          list['id'].toString(): (list['pos'] as num?)?.toDouble() ?? 0,
    };

    BoardItem boardItemForCard(Map<String, dynamic> card) {
      final cardId = card['id']?.toString() ?? '';

      final rawCardChecklists =
          checklistByCardId[cardId] ?? <Map<String, dynamic>>[];
      rawCardChecklists.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final pa = (a['pos'] as num?)?.toDouble() ?? 0;
        final pb = (b['pos'] as num?)?.toDouble() ?? 0;
        return pa.compareTo(pb);
      });

      final boardChecklists = rawCardChecklists.map((
        Map<String, dynamic> rawChecklist,
      ) {
        final rawItems =
            (rawChecklist['checkItems'] as List<dynamic>? ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList();
        rawItems.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
          final pa = (a['pos'] as num?)?.toDouble() ?? 0;
          final pb = (b['pos'] as num?)?.toDouble() ?? 0;
          return pa.compareTo(pb);
        });

        return BoardChecklist(
          title: (rawChecklist['name'] ?? '').toString(),
          items: rawItems
              .map(
                (Map<String, dynamic> rawItem) => BoardChecklistItem(
                  text: (rawItem['name'] ?? '').toString(),
                  isDone: rawItem['state']?.toString() == 'complete',
                ),
              )
              .toList(),
        );
      }).toList();

      final cardLabels = (card['idLabels'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic id) => labelsById[id.toString()] ?? '')
          .where((String label) => label.isNotEmpty)
          .toList();

      final comments = commentsByCardId[cardId] ?? <_TrelloComment>[];
      comments.sort(
        (_TrelloComment a, _TrelloComment b) => a.date.compareTo(b.date),
      );

      final notes = <BoardNote>[];
      final description = (card['desc'] ?? '').toString();
      if (description.trim().isNotEmpty) {
        notes.add(BoardNote(text: description));
      }
      notes.addAll(
        comments.map((c) => BoardNote(createdAt: c.date, text: c.text)),
      );

      final dueRaw = card['due']?.toString();
      DateTime? dueDate;
      if (dueRaw != null && dueRaw.isNotEmpty) {
        dueDate = DateTime.tryParse(dueRaw);
        if (dueDate == null) {
          throw JsonBoardImportException(
            'Expected ISO8601 date in Trello export.',
          );
        }
      }

      return BoardItem(
        title: (card['name'] ?? '').toString(),
        notes: notes,
        checklists: boardChecklists,
        dueDate: dueDate == null
            ? null
            : DateTime(dueDate.year, dueDate.month, dueDate.day),
        labels: cardLabels,
      );
    }

    final columns = lists
        .where((Map<String, dynamic> list) => !_isTrelloClosed(list))
        .map((Map<String, dynamic> list) {
          final listId = list['id']?.toString();
          final listCards = (cardsByListId[listId] ?? <Map<String, dynamic>>[])
              .where((Map<String, dynamic> card) => !_isTrelloClosed(card))
              .toList();

          listCards.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
            final pa = (a['pos'] as num?)?.toDouble() ?? 0;
            final pb = (b['pos'] as num?)?.toDouble() ?? 0;
            return pa.compareTo(pb);
          });

          final items = listCards.map(boardItemForCard).toList();

          return BoardColumn(
            title: (list['name'] ?? '').toString(),
            items: items,
          );
        })
        .toList();

    final archivedCards = cards.where((Map<String, dynamic> card) {
      final listId = card['idList']?.toString();
      return _isTrelloClosed(card) ||
          (listId != null && closedListIds.contains(listId));
    }).toList();
    archivedCards.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final aListPos = listPositionById[a['idList']?.toString()] ?? 0;
      final bListPos = listPositionById[b['idList']?.toString()] ?? 0;
      final listComparison = aListPos.compareTo(bListPos);
      if (listComparison != 0) {
        return listComparison;
      }

      final pa = (a['pos'] as num?)?.toDouble() ?? 0;
      final pb = (b['pos'] as num?)?.toDouble() ?? 0;
      return pa.compareTo(pb);
    });

    if (archivedCards.isNotEmpty) {
      columns.add(
        BoardColumn(
          title: 'Archive',
          items: archivedCards.map(boardItemForCard).toList(),
        ),
      );
    }

    return columns;
  }

  bool _isTrelloClosed(Map<String, dynamic> value) => value['closed'] == true;
}

class _TrelloComment {
  _TrelloComment({
    required this.cardId,
    required this.text,
    required this.date,
  });

  final String cardId;
  final String text;
  final DateTime date;
}
