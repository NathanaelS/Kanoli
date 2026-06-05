// Verifies Flutter timeline ordering stays aligned with Mermaid generation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/core/theme/app_theme.dart';
import 'package:kanoli_flutter/data/board/markdown_board_mermaid_formatter.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';
import 'package:kanoli_flutter/features/board/presentation/board_gantt_view.dart';

void main() {
  testWidgets('uses the same dated ordering and undated exclusion as Mermaid', (
    WidgetTester tester,
  ) async {
    final columns = <BoardColumn>[
      BoardColumn(
        title: 'Doing',
        items: <BoardItem>[
          _datedItem(
            id: 'later',
            title: 'Later',
            dueDate: DateTime(2026, 6, 8, 8),
          ),
          BoardItem(id: 'undated', title: 'Undated'),
          _datedItem(
            id: 'same-first',
            title: 'Same first',
            dueDate: DateTime(2026, 6, 6, 18),
          ),
        ],
      ),
      BoardColumn(
        title: 'Done',
        items: <BoardItem>[
          _datedItem(
            id: 'same-second',
            title: 'Same second',
            dueDate: DateTime(2026, 6, 6, 8),
          ),
        ],
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkAura,
        home: Scaffold(
          body: BoardGanttView(columns: columns, onOpenItem: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstY = tester.getCenter(find.text('Same first')).dy;
    final secondY = tester.getCenter(find.text('Same second')).dy;
    final laterY = tester.getCenter(find.text('Later')).dy;
    final mermaid = MarkdownBoardMermaidFormatter().format(columns);

    expect(firstY, lessThan(secondY));
    expect(secondY, lessThan(laterY));
    expect(
      mermaid.indexOf('Doing / Same first'),
      lessThan(mermaid.indexOf('Done / Same second')),
    );
    expect(
      mermaid.indexOf('Done / Same second'),
      lessThan(mermaid.indexOf('Doing / Later')),
    );
    expect(find.text('Undated'), findsOneWidget);
    expect(mermaid, isNot(contains('Undated')));
  });
}

BoardItem _datedItem({
  required String id,
  required String title,
  required DateTime dueDate,
}) {
  return BoardItem(id: id, title: title, dueDate: dueDate);
}
