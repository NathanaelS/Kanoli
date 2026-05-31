// Widget coverage for the command-palette card search UI.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';
import 'package:kanoli_flutter/features/board/application/card_search.dart';
import 'package:kanoli_flutter/features/board/presentation/card_search_palette.dart';

void main() {
  testWidgets('filters results as the user types', (WidgetTester tester) async {
    CardSearchResult? selected;

    await _pumpPalette(
      tester,
      columns: _columns(),
      onSelected: (CardSearchResult result) {
        selected = result;
      },
    );

    expect(find.text('Start typing to search cards.'), findsOneWidget);
    expect(find.text('title text'), findsOneWidget);
    expect(find.text('+urgent'), findsOneWidget);
    expect(find.text('due:2026-06-14'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pump();

    expect(find.text('Alpha task'), findsOneWidget);
    expect(find.text('Beta task'), findsNothing);
    expect(selected, isNull);
  });

  testWidgets('arrow keys and enter select the highlighted result', (
    WidgetTester tester,
  ) async {
    CardSearchResult? selected;

    await _pumpPalette(
      tester,
      columns: _columns(),
      onSelected: (CardSearchResult result) {
        selected = result;
      },
    );

    await tester.enterText(find.byType(TextField), 'task');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected?.itemId, 'beta');
    expect(find.byType(CardSearchPalette), findsNothing);
  });

  testWidgets('escape closes without selecting a result', (
    WidgetTester tester,
  ) async {
    CardSearchResult? selected;

    await _pumpPalette(
      tester,
      columns: _columns(),
      onSelected: (CardSearchResult result) {
        selected = result;
      },
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(find.byType(CardSearchPalette), findsNothing);
  });
}

Future<void> _pumpPalette(
  WidgetTester tester, {
  required List<BoardColumn> columns,
  required ValueChanged<CardSearchResult> onSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return CardSearchPalette(
                  columns: columns,
                  todoTextByCardId: const <String, List<String>>{},
                  onSelected: onSelected,
                );
              },
            );
          });
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<BoardColumn> _columns() {
  return <BoardColumn>[
    BoardColumn(
      title: 'Doing',
      items: <BoardItem>[
        BoardItem(id: 'alpha', title: 'Alpha task'),
        BoardItem(id: 'beta', title: 'Beta task'),
      ],
    ),
  ];
}
