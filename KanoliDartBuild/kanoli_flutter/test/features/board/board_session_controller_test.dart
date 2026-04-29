import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/core/config/app_environment.dart';
import 'package:kanoli_flutter/core/logging/app_logger.dart';
import 'package:kanoli_flutter/data/board/markdown_board_store.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';
import 'package:kanoli_flutter/features/board/application/board_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppLogger logger;
  late MarkdownBoardStore markdownStore;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    logger = AppLogger(environment: AppEnvironment.dev);
    markdownStore = MarkdownBoardStore();
  });

  test('moves item across columns with destination item positioning', () async {
    final boardPath = _tempPath('.md');
    markdownStore.save(
      filePath: boardPath,
      columns: <BoardColumn>[
        BoardColumn(
          id: 'col-a',
          title: 'A',
          items: <BoardItem>[
            BoardItem(id: 'item-1', title: 'One'),
            BoardItem(id: 'item-2', title: 'Two'),
          ],
        ),
        BoardColumn(
          id: 'col-b',
          title: 'B',
          items: <BoardItem>[BoardItem(id: 'item-3', title: 'Three')],
        ),
      ],
    );

    final controller = BoardSessionController(logger: logger);
    await controller.openBoard(boardPath);
    final colAId = controller.columns
        .firstWhere((BoardColumn c) => c.title == 'A')
        .id;
    final colBId = controller.columns
        .firstWhere((BoardColumn c) => c.title == 'B')
        .id;
    final colBFirstItemId = controller.columns
        .firstWhere((BoardColumn c) => c.id == colBId)
        .items
        .first
        .id;

    controller.moveItemBefore(
      itemId: 'item-2',
      destinationColumnId: colBId,
      destinationItemId: colBFirstItemId,
    );

    final colA = controller.columns.firstWhere(
      (BoardColumn c) => c.id == colAId,
    );
    final colB = controller.columns.firstWhere(
      (BoardColumn c) => c.id == colBId,
    );

    expect(colA.items.map((BoardItem i) => i.id), <String>['item-1']);
    expect(colB.items.map((BoardItem i) => i.id), <String>['item-2', 'item-3']);
  });

  test('moves item within same column to exactly before destination', () async {
    final boardPath = _tempPath('_within.md');
    markdownStore.save(
      filePath: boardPath,
      columns: <BoardColumn>[
        BoardColumn(
          id: 'col-a',
          title: 'A',
          items: <BoardItem>[
            BoardItem(id: 'item-1', title: 'One'),
            BoardItem(id: 'item-2', title: 'Two'),
            BoardItem(id: 'item-3', title: 'Three'),
            BoardItem(id: 'item-4', title: 'Four'),
          ],
        ),
      ],
    );

    final controller = BoardSessionController(logger: logger);
    await controller.openBoard(boardPath);
    final colAId = controller.columns.first.id;

    controller.moveItemBefore(
      itemId: 'item-1',
      destinationColumnId: colAId,
      destinationItemId: 'item-3',
    );

    final colA = controller.columns.firstWhere(
      (BoardColumn c) => c.id == colAId,
    );
    expect(
      colA.items.map((BoardItem i) => i.id),
      <String>['item-2', 'item-1', 'item-3', 'item-4'],
    );
  });

  test('archives item and auto-creates Archive column', () async {
    final boardPath = _tempPath('.md');
    markdownStore.save(
      filePath: boardPath,
      columns: <BoardColumn>[
        BoardColumn(
          id: 'col-a',
          title: 'Doing',
          items: <BoardItem>[BoardItem(id: 'item-1', title: 'One')],
        ),
      ],
    );

    final controller = BoardSessionController(logger: logger);
    await controller.openBoard(boardPath);

    controller.archiveItem('item-1');

    final archive = controller.columns.firstWhere(
      (BoardColumn c) => c.title.toLowerCase() == 'archive',
    );
    expect(archive.items.map((BoardItem i) => i.id), <String>['item-1']);
  });

  test('builds filtered cross-board results across open tabs', () async {
    final boardA = _tempPath('_a.md');
    final boardB = _tempPath('_b.md');

    markdownStore.save(
      filePath: boardA,
      columns: <BoardColumn>[
        BoardColumn(
          title: 'Doing',
          items: <BoardItem>[
            BoardItem(id: 'a1', title: 'A1', labels: <String>['urgent']),
            BoardItem(id: 'a2', title: 'A2', labels: <String>['backlog']),
          ],
        ),
      ],
    );

    markdownStore.save(
      filePath: boardB,
      columns: <BoardColumn>[
        BoardColumn(
          title: 'Backlog',
          items: <BoardItem>[
            BoardItem(id: 'b1', title: 'B1', labels: <String>['urgent']),
          ],
        ),
      ],
    );

    final controller = BoardSessionController(logger: logger);
    await controller.openBoard(boardA);
    await controller.openBoard(boardB);
    controller.setBoardFilter(
      dueDateRule: DueDateRule.any,
      labels: <String>['urgent'],
    );

    final result = controller.filteredResultsColumns();

    expect(result.length, 2);
    expect(
      result
          .expand((BoardColumn c) => c.items)
          .map((BoardItem i) => i.id)
          .toSet(),
      <String>{'a1', 'b1'},
    );
  });

  test('restores tab session and selected board path from prefs', () async {
    final boardA = _tempPath('_restore_a.md');
    final boardB = _tempPath('_restore_b.md');

    markdownStore.save(
      filePath: boardA,
      columns: <BoardColumn>[BoardColumn(title: 'A')],
    );
    markdownStore.save(
      filePath: boardB,
      columns: <BoardColumn>[BoardColumn(title: 'B')],
    );

    final first = BoardSessionController(logger: logger);
    await first.openBoard(boardA);
    await first.openBoard(boardB);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final second = BoardSessionController(logger: logger);
    await second.restoreSessionIfAvailable();

    expect(second.boardTabs.length, 2);
    expect(second.activeBoardPath, boardB);
    expect(second.columns.first.title, 'B');
  });

  test('moves and copies items to other boards', () async {
    final source = _tempPath('_source.md');
    final target = _tempPath('_target.md');

    markdownStore.save(
      filePath: source,
      columns: <BoardColumn>[
        BoardColumn(
          title: 'Doing',
          items: <BoardItem>[BoardItem(id: 's1', title: 'Source')],
        ),
      ],
    );
    markdownStore.save(
      filePath: target,
      columns: <BoardColumn>[BoardColumn(title: 'Inbox')],
    );

    final controller = BoardSessionController(logger: logger);
    await controller.openBoard(source);

    await controller.copyItemToBoard('s1', target);
    await controller.moveItemToBoard('s1', target);

    final sourceColumns = markdownStore.loadBoard(source).columns;
    final targetColumns = markdownStore.loadBoard(target).columns;

    expect(sourceColumns.first.items, isEmpty);
    expect(targetColumns.first.items.length, 2);
    expect(
      targetColumns.first.items.map((BoardItem item) => item.title),
      <String>['Source', 'Source'],
    );
  });

  test('restore session skips missing paths and keeps valid tabs', () async {
    final keepBoard = _tempPath('_keep.md');
    final missingBoard = _tempPath('_missing.md');

    markdownStore.save(
      filePath: keepBoard,
      columns: <BoardColumn>[BoardColumn(title: 'Keep')],
    );
    markdownStore.save(
      filePath: missingBoard,
      columns: <BoardColumn>[BoardColumn(title: 'DeleteMe')],
    );

    final first = BoardSessionController(logger: logger);
    await first.openBoard(keepBoard);
    await first.openBoard(missingBoard);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    File(missingBoard).deleteSync();

    final restored = BoardSessionController(logger: logger);
    await restored.restoreSessionIfAvailable();

    expect(restored.boardTabs.length, 1);
    expect(restored.activeBoardPath, keepBoard);
    expect(restored.columns.first.title, 'Keep');
  });

  test('importJsonBoard surfaces parse errors without crashing', () async {
    final badJsonPath = _tempPath('_bad.json');
    final outputBoard = _tempPath('_import_target.md');

    File(badJsonPath).writeAsStringSync('{bad json');

    final controller = BoardSessionController(logger: logger);
    await controller.importJsonBoard(
      jsonPath: badJsonPath,
      boardPath: outputBoard,
    );

    expect(controller.lastError, isNotNull);
    expect(controller.lastError, contains('FormatException'));
    expect(File(outputBoard).existsSync(), isFalse);
  });

  test('openBoard returns file-not-found error for missing board path', () async {
    final missingPath = _tempPath('_not_found.md');
    if (File(missingPath).existsSync()) {
      File(missingPath).deleteSync();
    }

    final controller = BoardSessionController(logger: logger);
    await controller.openBoard(missingPath);

    expect(controller.lastError, isNotNull);
    expect(controller.lastError, contains('Unable to open file'));
    expect(controller.lastError, contains('File not found.'));
    expect(controller.hasActiveBoard, isFalse);
  });
}

String _tempPath(String suffix) {
  final dir = Directory.systemTemp.createTempSync('kanoli_session_test_');
  return '${dir.path}${Platform.pathSeparator}board$suffix';
}
