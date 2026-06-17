// Widget coverage for workspace-level shortcuts and palette routing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/core/config/app_environment.dart';
import 'package:kanoli_flutter/core/files/board_file_access_service.dart';
import 'package:kanoli_flutter/core/logging/app_logger.dart';
import 'package:kanoli_flutter/data/board/markdown_board_store.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';
import 'package:kanoli_flutter/features/board/application/board_session_controller.dart';
import 'package:kanoli_flutter/features/board/presentation/board_workspace_page.dart';
import 'package:kanoli_flutter/features/board/presentation/card_search_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Windows key and P opens quick card search', (
    WidgetTester tester,
  ) async {
    final boardPath = _tempPath('.md');
    final markdownStore = MarkdownBoardStore();
    markdownStore.save(
      filePath: boardPath,
      columns: <BoardColumn>[
        BoardColumn(
          title: 'Backlog',
          items: <BoardItem>[BoardItem(id: 'alpha', title: 'Alpha task')],
        ),
      ],
    );
    final controller = BoardSessionController(
      logger: AppLogger(environment: AppEnvironment.dev),
      markdownBoardStore: markdownStore,
    );
    await controller.openBoard(boardPath);

    await tester.pumpWidget(
      MaterialApp(
        home: BoardWorkspacePage(
          environment: AppEnvironment.dev,
          controller: controller,
          fileAccessService: _NoopBoardFileAccessService(),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(find.byType(CardSearchPalette), findsOneWidget);
  });

  testWidgets('card tile renders cached todo progress from controller state', (
    WidgetTester tester,
  ) async {
    final boardPath = _tempPath('_counts.md');
    final todoPath = _tempPath('.todo.txt');
    final markdownStore = MarkdownBoardStore();
    markdownStore.save(
      filePath: boardPath,
      columns: <BoardColumn>[
        BoardColumn(
          title: 'Doing',
          items: <BoardItem>[BoardItem(id: 'alpha', title: 'Alpha task')],
        ),
      ],
    );
    File(todoPath).writeAsStringSync(
      'First task card:alpha @Doing\n'
      'x 2026-06-16 Done task card:alpha @Doing\n',
    );

    final controller = BoardSessionController(
      logger: AppLogger(environment: AppEnvironment.dev),
      markdownBoardStore: markdownStore,
    );
    await controller.openBoard(boardPath);
    await tester.runAsync(() async {
      controller.setActiveTodoPath(todoPath);
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    expect(controller.activeTodoCountsByCardId['alpha']?.total, 2);
    expect(controller.activeTodoCountsByCardId['alpha']?.completed, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: BoardWorkspacePage(
          environment: AppEnvironment.dev,
          controller: controller,
          fileAccessService: _NoopBoardFileAccessService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('board tab row stays hidden by default after opening a board', (
    WidgetTester tester,
  ) async {
    final boardPath = _tempPath('_hidden_tabs.md');
    final markdownStore = MarkdownBoardStore();
    markdownStore.save(
      filePath: boardPath,
      columns: <BoardColumn>[
        BoardColumn(
          title: 'Backlog',
          items: <BoardItem>[BoardItem(id: 'alpha', title: 'Alpha task')],
        ),
      ],
    );
    final controller = BoardSessionController(
      logger: AppLogger(environment: AppEnvironment.dev),
      markdownBoardStore: markdownStore,
    );
    await controller.openBoard(boardPath);

    await tester.pumpWidget(
      MaterialApp(
        home: BoardWorkspacePage(
          environment: AppEnvironment.dev,
          controller: controller,
          fileAccessService: _NoopBoardFileAccessService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Board'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets(
    'Board and Timeline toggle is right aligned in workspace header',
    (WidgetTester tester) async {
      final boardPath = _tempPath('_alignment.md');
      final markdownStore = MarkdownBoardStore();
      markdownStore.save(
        filePath: boardPath,
        columns: <BoardColumn>[
          BoardColumn(
            title: 'Backlog',
            items: <BoardItem>[BoardItem(id: 'a', title: 'Alpha')],
          ),
        ],
      );
      final controller = BoardSessionController(
        logger: AppLogger(environment: AppEnvironment.dev),
        markdownBoardStore: markdownStore,
      );
      await controller.openBoard(boardPath);

      await tester.pumpWidget(
        MaterialApp(
          home: BoardWorkspacePage(
            environment: AppEnvironment.dev,
            controller: controller,
            fileAccessService: _NoopBoardFileAccessService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldRect = tester.getRect(find.byType(Scaffold));
      final toggleRect = tester.getRect(
        find.byWidgetPredicate(
          (Widget widget) => widget is SegmentedButton<bool>,
        ),
      );

      expect(
        toggleRect.right,
        moreOrLessEquals(scaffoldRect.right - 16, epsilon: 1),
      );
    },
  );
}

String _tempPath(String extension) {
  final dir = Directory.systemTemp.createTempSync('kanoli_workspace_test_');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return '${dir.path}${Platform.pathSeparator}Board$extension';
}

class _NoopBoardFileAccessService implements BoardFileAccessService {
  @override
  Future<String?> pickCreateBoardPath({required String suggestedName}) async {
    return null;
  }

  @override
  Future<BoardImportSelection?> pickImportBoardSelection({
    required String suggestedBoardName,
  }) async {
    return null;
  }

  @override
  Future<String?> pickOpenBoardPath() async {
    return null;
  }
}
