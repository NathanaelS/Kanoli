// Widget coverage for the board-wide timeline view.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/core/theme/app_theme.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';
import 'package:kanoli_flutter/features/board/presentation/board_gantt_styles.dart';
import 'package:kanoli_flutter/features/board/presentation/board_gantt_view.dart';

void main() {
  testWidgets('shows empty state when the board has no cards', (
    WidgetTester tester,
  ) async {
    await _pumpTimeline(tester, columns: <BoardColumn>[], onOpenItem: (_) {});

    expect(find.text('No cards to show on the timeline.'), findsOneWidget);
  });

  testWidgets('shows no-dated-card state and still lists undated cards', (
    WidgetTester tester,
  ) async {
    await _pumpTimeline(
      tester,
      columns: <BoardColumn>[
        BoardColumn(
          id: 'backlog',
          title: 'Backlog',
          items: <BoardItem>[
            BoardItem(id: 'alpha', title: 'Alpha'),
            BoardItem(id: 'beta', title: 'Beta'),
          ],
        ),
      ],
      onOpenItem: (_) {},
    );

    expect(
      find.text('No dated cards to place on the timeline yet.'),
      findsOneWidget,
    );
    expect(find.text('No due date'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('renders dated cards, undated cards, and opens selected items', (
    WidgetTester tester,
  ) async {
    String? openedItemId;

    await _pumpTimeline(
      tester,
      columns: <BoardColumn>[
        BoardColumn(
          id: 'doing',
          title: 'Doing',
          items: <BoardItem>[
            BoardItem(
              id: 'alpha',
              title: 'Alpha',
              dueDate: TodoDateFormatter.tryParse('2026-06-10'),
            ),
            BoardItem(id: 'beta', title: 'Beta'),
          ],
        ),
        BoardColumn(
          id: 'done',
          title: 'Done',
          items: <BoardItem>[
            BoardItem(
              id: 'gamma',
              title: 'Gamma',
              dueDate: TodoDateFormatter.tryParse('2026-06-12'),
            ),
          ],
        ),
      ],
      onOpenItem: (String itemId) {
        openedItemId = itemId;
      },
    );

    expect(find.text('Doing'), findsWidgets);
    expect(find.text('Done'), findsWidgets);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('No due date'), findsOneWidget);
    expect(find.text('2026-06-10'), findsOneWidget);
    expect(find.text('2026-06-11'), findsOneWidget);
    expect(find.text('2026-06-12'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('marker-alpha')));
    await tester.pump();

    expect(openedItemId, 'alpha');
  });

  testWidgets('uses the same style for cards from the same column', (
    WidgetTester tester,
  ) async {
    await _pumpTimeline(
      tester,
      columns: <BoardColumn>[
        BoardColumn(
          id: 'doing',
          title: 'Doing',
          items: <BoardItem>[
            BoardItem(
              id: 'alpha',
              title: 'Alpha',
              dueDate: TodoDateFormatter.tryParse('2026-06-10'),
            ),
            BoardItem(
              id: 'beta',
              title: 'Beta',
              dueDate: TodoDateFormatter.tryParse('2026-06-11'),
            ),
          ],
        ),
      ],
      onOpenItem: (_) {},
    );

    final firstMarker = tester.widget<BoardGanttMarker>(
      find.byKey(const ValueKey<String>('marker-alpha')),
    );
    final secondMarker = tester.widget<BoardGanttMarker>(
      find.byKey(const ValueKey<String>('marker-beta')),
    );

    expect(secondMarker.style.styleKey, firstMarker.style.styleKey);
  });

  testWidgets('uses different theme colors for different columns before wrap', (
    WidgetTester tester,
  ) async {
    await _pumpTimeline(
      tester,
      columns: <BoardColumn>[
        BoardColumn(
          id: 'doing',
          title: 'Doing',
          items: <BoardItem>[
            BoardItem(
              id: 'alpha',
              title: 'Alpha',
              dueDate: TodoDateFormatter.tryParse('2026-06-10'),
            ),
          ],
        ),
        BoardColumn(
          id: 'done',
          title: 'Done',
          items: <BoardItem>[
            BoardItem(
              id: 'gamma',
              title: 'Gamma',
              dueDate: TodoDateFormatter.tryParse('2026-06-11'),
            ),
          ],
        ),
      ],
      onOpenItem: (_) {},
    );

    final firstMarker = tester.widget<BoardGanttMarker>(
      find.byKey(const ValueKey<String>('marker-alpha')),
    );
    final secondMarker = tester.widget<BoardGanttMarker>(
      find.byKey(const ValueKey<String>('marker-gamma')),
    );

    expect(firstMarker.style.color, AppTheme.primary);
    expect(secondMarker.style.color, AppTheme.secondary);
    expect(secondMarker.style.styleKey, isNot(firstMarker.style.styleKey));
  });

  testWidgets('reuses theme colors with distinct patterns after palette wrap', (
    WidgetTester tester,
  ) async {
    await _pumpTimeline(
      tester,
      columns: List<BoardColumn>.generate(7, (int index) {
        return BoardColumn(
          id: 'column-$index',
          title: 'Column $index',
          items: <BoardItem>[
            BoardItem(
              id: 'item-$index',
              title: 'Item $index',
              dueDate: TodoDateFormatter.tryParse(
                '2026-06-${(10 + index).toString().padLeft(2, '0')}',
              ),
            ),
          ],
        );
      }),
      onOpenItem: (_) {},
    );

    final firstMarker = tester.widget<BoardGanttMarker>(
      find.byKey(const ValueKey<String>('marker-item-0')),
    );
    final wrappedMarker = tester.widget<BoardGanttMarker>(
      find.byKey(const ValueKey<String>('marker-item-6')),
    );
    final legendSwatch = tester.widget<BoardGanttSwatch>(
      find.byKey(const ValueKey<String>('legend-swatch-column-6')),
    );

    expect(firstMarker.style.color, AppTheme.primary);
    expect(firstMarker.style.pattern, BoardGanttPattern.solid);
    expect(wrappedMarker.style.color, firstMarker.style.color);
    expect(wrappedMarker.style.pattern, BoardGanttPattern.diagonalStripe);
    expect(legendSwatch.style.styleKey, wrappedMarker.style.styleKey);
  });

  testWidgets('pattern-wrapped markers remain selectable', (
    WidgetTester tester,
  ) async {
    String? openedItemId;

    await _pumpTimeline(
      tester,
      columns: List<BoardColumn>.generate(7, (int index) {
        return BoardColumn(
          id: 'column-$index',
          title: 'Column $index',
          items: <BoardItem>[
            BoardItem(
              id: 'item-$index',
              title: 'Item $index',
              dueDate: TodoDateFormatter.tryParse(
                '2026-06-${(10 + index).toString().padLeft(2, '0')}',
              ),
            ),
          ],
        );
      }),
      onOpenItem: (String itemId) {
        openedItemId = itemId;
      },
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('marker-item-6')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('marker-item-6')));
    await tester.pump();

    expect(openedItemId, 'item-6');
  });

  testWidgets('timeline stays horizontally scrollable on narrow layouts', (
    WidgetTester tester,
  ) async {
    String? openedItemId;

    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpTimeline(
      tester,
      columns: <BoardColumn>[
        BoardColumn(
          id: 'doing',
          title: 'Doing',
          items: <BoardItem>[
            BoardItem(
              id: 'alpha',
              title: 'Alpha',
              dueDate: TodoDateFormatter.tryParse('2026-06-10'),
            ),
            BoardItem(
              id: 'beta',
              title: 'Beta',
              dueDate: TodoDateFormatter.tryParse('2026-06-18'),
            ),
          ],
        ),
      ],
      onOpenItem: (String itemId) {
        openedItemId = itemId;
      },
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('marker-beta')));
    await tester.pump();

    expect(openedItemId, 'beta');
  });
}

Future<void> _pumpTimeline(
  WidgetTester tester, {
  required List<BoardColumn> columns,
  required ValueChanged<String> onOpenItem,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkAura,
      home: Scaffold(
        body: BoardGanttView(columns: columns, onOpenItem: onOpenItem),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
