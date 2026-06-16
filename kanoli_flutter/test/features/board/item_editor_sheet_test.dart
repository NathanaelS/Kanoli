import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/core/theme/app_theme.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';
import 'package:kanoli_flutter/features/board/presentation/item_editor_sheet.dart';

void main() {
  test('note markdown timestamp format remains unchanged', () {
    final timestamp = DateTime.parse('2026-06-16T17:37:30-04:00');

    expect(NoteDateFormatter.format(timestamp), '2026-06-16T17:37:30-04:00');
    expect(
      NoteDateFormatter.formatForDisplay(timestamp),
      'June 16, 2026 5:37 PM',
    );
  });

  testWidgets('enter posts while shift-enter inserts a newline', (
    WidgetTester tester,
  ) async {
    BoardItem? savedItem;
    final noteTimestamp = DateTime.parse('2026-06-16T17:37:30-04:00');
    final composerFinder = find.byKey(
      const ValueKey<String>('new-note-composer'),
    );

    await _pumpEditor(
      tester,
      item: BoardItem(
        id: 'alpha',
        title: 'Alpha',
        notes: <BoardNote>[
          BoardNote(
            text: 'Existing note',
            createdAt: noteTimestamp.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      onSave: (BoardItem item) {
        savedItem = item;
      },
    );

    await tester.enterText(
      composerFinder,
      'Document the local-first constraint',
    );
    final composerController = tester
        .widget<TextField>(composerFinder)
        .controller!;
    composerController.selection = TextSelection.collapsed(
      offset: composerController.text.length,
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(savedItem, isNull);
    expect(
      tester.widget<TextField>(composerFinder).controller!.text,
      'Document the local-first constraint\n',
    );

    await tester.enterText(
      composerFinder,
      'Document the local-first constraint\nKeep serialization readable',
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    final createdNote = savedItem?.notes.last;

    expect(createdNote, isNotNull);
    expect(
      createdNote?.text,
      'Document the local-first constraint\nKeep serialization readable',
    );
    expect(savedItem?.notes, hasLength(2));
    expect(tester.widget<TextField>(composerFinder).controller!.text, isEmpty);
    expect(
      find.text(
        NoteDateFormatter.formatForDisplay(
          noteTimestamp.subtract(const Duration(hours: 1)),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText &&
            widget.text.toPlainText() ==
                'Document the local-first constraint\nKeep serialization readable',
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(
        EditableText,
        'Document the local-first constraint\nKeep serialization readable',
      ),
      findsNothing,
    );
    expect(
      NoteDateFormatter.format(createdNote!.createdAt).contains('T'),
      isTrue,
    );
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required BoardItem item,
  required ValueChanged<BoardItem> onSave,
}) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkAura,
      home: Scaffold(
        body: ItemEditorSheet(
          item: item,
          boardFilePath: null,
          columnTitle: 'Doing',
          allColumns: <BoardColumn>[
            BoardColumn(title: 'Doing', items: <BoardItem>[item]),
          ],
          onOpenItem: (_) {},
          onSave: onSave,
          onTodoPathChanged: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
