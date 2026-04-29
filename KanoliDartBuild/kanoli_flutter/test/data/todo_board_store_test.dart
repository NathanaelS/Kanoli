import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/data/board/todo_board_store.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';

void main() {
  group('TodoBoardStore', () {
    test('parses card-scoped items and preserves other lines', () {
      final cardId = '11111111-1111-1111-1111-111111111111';
      final otherCardId = '22222222-2222-2222-2222-222222222222';
      final text =
          '(A) Current card task due:2026-04-16 card:$cardId @Doing\n'
          '  Other card task card:$otherCardId @Backlog\n\n'
          'x 2026-04-13 Done task card:$cardId @Doing\n'
          '\tUntagged board-level task\n';

      final store = TodoBoardStore();
      final result = store.parse(text: text, cardId: cardId);

      expect(
        result.currentCardItems.map((TodoListEntry item) => item.text),
        <String>['Current card task', 'Done task'],
      );
      expect(result.currentCardItems.first.priority, 'A');
      expect(
        TodoDateFormatter.format(result.currentCardItems.first.dueDate!),
        '2026-04-16',
      );
      expect(result.currentCardItems[1].isCompleted, isTrue);
      expect(result.otherLines, <String>[
        '  Other card task card:$otherCardId @Backlog',
        '',
        '\tUntagged board-level task',
      ]);
    });

    test('serializes while preserving other lines and card metadata', () {
      final cardId = '11111111-1111-1111-1111-111111111111';
      final dueDate = TodoDateFormatter.tryParse('2026-04-16');
      final completionDate = TodoDateFormatter.tryParse('2026-04-13');

      final items = <TodoListEntry>[
        TodoListEntry(
          text: 'Current task',
          isCompleted: false,
          priority: 'B',
          dueDate: dueDate,
        ),
        TodoListEntry(
          text: 'Finished task',
          isCompleted: true,
          completionDate: completionDate,
        ),
      ];

      final store = TodoBoardStore();
      final serialized = store.serialize(
        currentCardItems: items,
        otherLines: <String>[
          'Existing other card card:22222222-2222-2222-2222-222222222222 @Backlog',
        ],
        cardId: cardId,
        columnContext: 'Doing',
      );

      expect(
        serialized,
        'Existing other card card:22222222-2222-2222-2222-222222222222 @Backlog\n'
        '(B) Current task due:2026-04-16 card:$cardId @Doing\n'
        'x 2026-04-13 Finished task card:$cardId @Doing\n',
      );
    });

    test('load-save-delete todo list file', () {
      final cardId = '11111111-1111-1111-1111-111111111111';
      final store = TodoBoardStore();
      final filePath = _tempFilePath('.todo.txt');

      store.createTodoListIfNeeded(filePath);
      store.saveTodoList(
        todoListPath: filePath,
        currentCardItems: <TodoListEntry>[
          TodoListEntry(
            text: 'Write todo file',
            isCompleted: false,
            priority: 'A',
            dueDate: TodoDateFormatter.tryParse('2026-04-16'),
          ),
        ],
        otherLines: <String>[
          'Existing task card:22222222-2222-2222-2222-222222222222 @Backlog',
        ],
        cardId: cardId,
        columnContext: 'Doing',
      );

      final loadedText = File(filePath).readAsStringSync();
      final parsed = store.parse(text: loadedText, cardId: cardId);

      expect(
        parsed.currentCardItems.map((TodoListEntry item) => item.text),
        <String>['Write todo file'],
      );
      expect(parsed.currentCardItems.first.priority, 'A');
      expect(
        TodoDateFormatter.format(parsed.currentCardItems.first.dueDate!),
        '2026-04-16',
      );
      expect(parsed.otherLines, <String>[
        'Existing task card:22222222-2222-2222-2222-222222222222 @Backlog',
      ]);

      store.deleteTodoList(filePath);
      expect(File(filePath).existsSync(), isFalse);
    });
  });
}

String _tempFilePath(String extension) {
  final directory = Directory.systemTemp.createTempSync('kanoli_todo_test_');
  return '${directory.path}/file$extension';
}
