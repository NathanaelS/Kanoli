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

    test('parses Swift-exported mixed board markdown safely', () {
      final store = MarkdownBoardStore();
      final filePath = _tempFilePath('.md');
      File(filePath).writeAsStringSync('''
# Krysilis Productions
## LPA +AI id:F8F1785E-7FFC-4700-9BDF-C5D076F9571A
> note:2026-04-11T21:44:49-07:00 nathanaels.github.io/LPA/
## Thing 2 +AI +Test +Test-2 id:4B5E1F0B-4EDE-4E86-8DBB-CBBDB336A61E
## Thing 3 id:5F5BA7B5-8D15-4983-B8E7-6F5FE557C1ED
##  id:252AC7EE-E608-41FD-A874-A38961E44B56

# Second column
## Second column item 1 id:7BBE9297-5243-4995-BF21-C66475E2DF73
## Thing 47 +Bug-Report due:2026-04-13 id:1DE4336D-075E-4870-8CC5-168635CEEF16
> note:2026-04-11T20:40:06-07:00 khkn/lkn
> note:2026-04-12T09:38:09-07:00 This is a new note
> checklist:20323199-5C5C-4DD5-A1BF-CAF95390327C Checklist
> checklist-item:20323199-5C5C-4DD5-A1BF-CAF95390327C:[ ] Check 1
> checklist-item:20323199-5C5C-4DD5-A1BF-CAF95390327C:[ ] Check 2
> checklist-item:20323199-5C5C-4DD5-A1BF-CAF95390327C:[ ] Thing 3
> checklist-item:20323199-5C5C-4DD5-A1BF-CAF95390327C:[ ] Thing 4

# Archive
## LPA id:F7CF22F3-D51F-47E5-B576-609E97DD8B97
> note:2026-04-11T21:44:49-07:00 nathanaels.github.io/LPA/

# Woohoo
## Item 1 id:7BB9F925-599F-4FAA-A7F2-ABFA62761F8A
''');

      final result = store.loadBoard(filePath);
      final secondColumn = result.columns.firstWhere(
        (BoardColumn column) => column.title == 'Second column',
      );
      final item = secondColumn.items.firstWhere(
        (BoardItem boardItem) => boardItem.id == '1DE4336D-075E-4870-8CC5-168635CEEF16',
      );

      expect(result.errorMessage, isNull);
      expect(result.columns.length, 4);
      expect(item.title, 'Thing 47');
      expect(item.labels, <String>['Bug-Report']);
      expect(TodoDateFormatter.format(item.dueDate!), '2026-04-13');
      expect(item.notes.length, 2);
      expect(item.checklists.single.items.length, 4);
    });
  });
}

String _tempFilePath(String extension) {
  final directory = Directory.systemTemp.createTempSync(
    'kanoli_markdown_test_',
  );
  return '${directory.path}/file$extension';
}
