// Covers managed Mermaid regeneration across board persistence workflows.
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
  late MarkdownBoardStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    logger = AppLogger(environment: AppEnvironment.dev);
    store = MarkdownBoardStore();
  });

  test('new boards immediately contain a managed timeline', () async {
    final boardPath = _tempPath('new.md');
    final controller = BoardSessionController(
      logger: logger,
      markdownBoardStore: store,
    );

    await controller.createBoard(boardPath);

    final markdown = File(boardPath).readAsStringSync();
    expect(markdown, contains('<!-- kanoli:timeline:start -->'));
    expect(markdown, contains('dateFormat YYYY-MM-DD'));
    expect(controller.hasActiveBoard, isTrue);
  });

  test(
    'item edits and deletion regenerate the active board timeline',
    () async {
      final boardPath = _tempPath('edit.md');
      store.save(
        filePath: boardPath,
        columns: <BoardColumn>[
          BoardColumn(
            title: 'Doing',
            items: <BoardItem>[
              _datedItem(
                id: 'dated-card',
                title: 'Initial title',
                due: '2026-06-06',
              ),
            ],
          ),
        ],
      );
      final controller = BoardSessionController(
        logger: logger,
        markdownBoardStore: store,
      );
      await controller.openBoard(boardPath);

      controller.replaceItem(
        _datedItem(id: 'dated-card', title: 'Updated title', due: '2026-06-09'),
      );
      await controller.persistBoard();

      var markdown = File(boardPath).readAsStringSync();
      expect(markdown, contains('Doing / Updated title'));
      expect(markdown, contains('2026-06-09, 1d'));
      expect(markdown, isNot(contains('Doing / Initial title')));

      await controller.persistBoard();
      expect(File(boardPath).readAsStringSync(), markdown);

      controller.deleteItem('dated-card');
      await controller.persistBoard();

      markdown = File(boardPath).readAsStringSync();
      expect(markdown, isNot(contains('section Dated cards')));
      expect(markdown, isNot(contains('Updated title')));
    },
  );

  test('cross-board copy and move refresh both affected timelines', () async {
    final sourcePath = _tempPath('source.md');
    final targetPath = _tempPath('target.md');
    store.save(
      filePath: sourcePath,
      columns: <BoardColumn>[
        BoardColumn(
          title: 'Doing',
          items: <BoardItem>[
            _datedItem(
              id: 'source-card',
              title: 'Source card',
              due: '2026-06-10',
            ),
          ],
        ),
      ],
    );
    store.save(
      filePath: targetPath,
      columns: <BoardColumn>[BoardColumn(title: 'Inbox')],
    );
    final controller = BoardSessionController(
      logger: logger,
      markdownBoardStore: store,
    );
    await controller.openBoard(sourcePath);

    await controller.copyItemToBoard('source-card', targetPath);
    await controller.moveItemToBoard('source-card', targetPath);
    await controller.persistBoard();

    final sourceMarkdown = File(sourcePath).readAsStringSync();
    final targetMarkdown = File(targetPath).readAsStringSync();
    expect(sourceMarkdown, isNot(contains('Source card :card_')));
    expect('Inbox / Source card'.allMatches(targetMarkdown), hasLength(2));
    expect('2026-06-10, 1d'.allMatches(targetMarkdown), hasLength(2));
  });

  test('JSON import creates a board with generated Mermaid', () async {
    final jsonPath = _tempPath('import.json');
    final boardPath = _tempPath('import.md');
    File(jsonPath).writeAsStringSync('''
{
  "columns": [
    {
      "title": "Imported",
      "items": [
        {
          "id": "imported-card",
          "title": "Imported dated card",
          "dueDate": "2026-06-11"
        }
      ]
    }
  ]
}
''');
    final controller = BoardSessionController(logger: logger);

    await controller.importJsonBoard(jsonPath: jsonPath, boardPath: boardPath);

    final markdown = File(boardPath).readAsStringSync();
    expect(controller.lastError, isNull);
    expect(markdown, contains('Imported / Imported dated card'));
    expect(markdown, contains('2026-06-11, 1d'));
  });
}

BoardItem _datedItem({
  required String id,
  required String title,
  required String due,
}) {
  return BoardItem(
    id: id,
    title: title,
    dueDate: TodoDateFormatter.tryParse(due),
  );
}

String _tempPath(String name) {
  final directory = Directory.systemTemp.createTempSync(
    'kanoli_mermaid_integration_',
  );
  return '${directory.path}${Platform.pathSeparator}$name';
}
