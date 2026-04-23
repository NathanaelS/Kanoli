import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/data/board/markdown_board_store.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';

void main() {
  group('MarkdownBoardStore', () {
    test('round-trips columns, item metadata, notes, and checklists', () {
      final store = MarkdownBoardStore();
      final dueDate = TodoDateFormatter.tryParse('2026-04-16')!;
      final noteDate = DateTime.parse('2026-04-13T12:30:00-07:00');

      final columns = <BoardColumn>[
        BoardColumn(
          title: 'Doing',
          items: <BoardItem>[
            BoardItem(
              id: '11111111-1111-1111-1111-111111111111',
              title: 'Test Item',
              notes: <BoardNote>[
                BoardNote(createdAt: noteDate, text: 'First note'),
              ],
              checklists: <BoardChecklist>[
                BoardChecklist(
                  id: '22222222-2222-2222-2222-222222222222',
                  title: 'Launch',
                  items: <BoardChecklistItem>[
                    BoardChecklistItem(text: 'Write tests'),
                    BoardChecklistItem(text: 'Ship', isDone: true),
                  ],
                ),
              ],
              dueDate: dueDate,
              priority: 'A',
              labels: <String>['AI', 'more-testing'],
            ),
          ],
        ),
      ];

      final filePath = _tempFilePath('.md');
      store.save(columns: columns, filePath: filePath);

      final result = store.loadBoard(filePath);
      final loadedItem = result.columns.first.items.first;

      expect(result.errorMessage, isNull);
      expect(result.columns.first.title, 'Doing');
      expect(loadedItem.id, '11111111-1111-1111-1111-111111111111');
      expect(loadedItem.title, 'Test Item');
      expect(loadedItem.priority, 'A');
      expect(loadedItem.labels, <String>['AI', 'more-testing']);
      expect(TodoDateFormatter.format(loadedItem.dueDate!), '2026-04-16');
      expect(loadedItem.notes.first.text, 'First note');
      expect(
        loadedItem.checklists.first.id,
        '22222222-2222-2222-2222-222222222222',
      );
      expect(loadedItem.checklists.first.title, 'Launch');
      expect(
        loadedItem.checklists.first.items.map(
          (BoardChecklistItem item) => item.text,
        ),
        <String>['Write tests', 'Ship'],
      );
      expect(
        loadedItem.checklists.first.items.map(
          (BoardChecklistItem item) => item.isDone,
        ),
        <bool>[false, true],
      );
    });

    test('parses legacy checklist items', () {
      final store = MarkdownBoardStore();
      final filePath = _tempFilePath('.md');
      File(filePath).writeAsStringSync('''
# Doing
## Legacy Card id:11111111-1111-1111-1111-111111111111
> checklist:[ ] First legacy item
> checklist:[x] Second legacy item
''');

      final result = store.loadBoard(filePath);
      final checklist = result.columns.first.items.first.checklists.first;

      expect(checklist.title, 'Checklist');
      expect(
        checklist.items.map((BoardChecklistItem item) => item.text),
        <String>['First legacy item', 'Second legacy item'],
      );
      expect(
        checklist.items.map((BoardChecklistItem item) => item.isDone),
        <bool>[false, true],
      );
    });

    test('ignores legacy todo metadata token on card heading', () {
      final store = MarkdownBoardStore();
      final filePath = _tempFilePath('.md');
      File(filePath).writeAsStringSync('''
# Doing
## Card Title todo:Old%20Todo.txt +AI id:11111111-1111-1111-1111-111111111111
''');

      final result = store.loadBoard(filePath);
      final item = result.columns.first.items.first;

      expect(item.title, 'Card Title');
      expect(item.labels, <String>['AI']);
    });
  });
}

String _tempFilePath(String extension) {
  final directory = Directory.systemTemp.createTempSync(
    'kanoli_markdown_test_',
  );
  return '${directory.path}/file$extension';
}
