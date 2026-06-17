// Covers command-palette card search matching over active-board content.
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli/domain/board/board_entities.dart';
import 'package:kanoli/features/board/application/card_search.dart';

void main() {
  test('matches card title, labels, notes, checklists, and todo text', () {
    final columns = <BoardColumn>[
      BoardColumn(
        title: 'Doing',
        items: <BoardItem>[
          BoardItem(id: 'title', title: 'Ship fast search'),
          BoardItem(
            id: 'label',
            title: 'Color code cards',
            labels: <String>['Design'],
          ),
          BoardItem(
            id: 'date',
            title: 'Schedule release',
            dueDate: TodoDateFormatter.tryParse('2026-06-14'),
          ),
          BoardItem(
            id: 'note',
            title: 'Write notes',
            bodyMarkdown: 'Remember the palette behavior.',
            notes: <BoardNote>[BoardNote(text: 'Document keyboard flow')],
          ),
          BoardItem(
            id: 'checklist',
            title: 'Release prep',
            checklists: <BoardChecklist>[
              BoardChecklist(
                title: 'Launch',
                items: <BoardChecklistItem>[
                  BoardChecklistItem(text: 'Validate shortcut'),
                ],
              ),
            ],
          ),
          BoardItem(id: 'todo', title: 'Sidecar work'),
        ],
      ),
    ];
    final todoTextByCardId = <String, List<String>>{
      'todo': <String>['Sweep todo integration'],
    };

    expect(_ids(searchBoardCards(columns: columns, query: 'ship')), <String>[
      'title',
    ]);
    expect(_ids(searchBoardCards(columns: columns, query: 'design')), <String>[
      'label',
    ]);
    expect(_ids(searchBoardCards(columns: columns, query: '+design')), <String>[
      'label',
    ]);
    expect(
      _ids(searchBoardCards(columns: columns, query: 'due:2026-06-14')),
      <String>['date'],
    );
    expect(
      _ids(searchBoardCards(columns: columns, query: 'keyboard')),
      <String>['note'],
    );
    expect(
      _ids(searchBoardCards(columns: columns, query: 'shortcut')),
      <String>['checklist'],
    );
    expect(
      _ids(
        searchBoardCards(
          columns: columns,
          query: 'integration',
          todoTextByCardId: todoTextByCardId,
        ),
      ),
      <String>['todo'],
    );
  });

  test(
    'returns one result with ordered match kinds for multiple field matches',
    () {
      final columns = <BoardColumn>[
        BoardColumn(
          title: 'Inbox',
          items: <BoardItem>[
            BoardItem(
              id: 'multi',
              title: 'Palette polish',
              bodyMarkdown: 'Palette note',
              labels: <String>['palette'],
            ),
          ],
        ),
      ];

      final results = searchBoardCards(columns: columns, query: 'palette');

      expect(results, hasLength(1));
      expect(results.single.itemId, 'multi');
      expect(results.single.matchKinds, <CardSearchMatchKind>[
        CardSearchMatchKind.title,
        CardSearchMatchKind.label,
        CardSearchMatchKind.note,
      ]);
    },
  );

  test('returns no results for blank queries', () {
    final columns = <BoardColumn>[
      BoardColumn(
        title: 'Inbox',
        items: <BoardItem>[BoardItem(id: 'one', title: 'One')],
      ),
    ];

    expect(searchBoardCards(columns: columns, query: '   '), isEmpty);
  });

  test('searches all open board inputs with board context', () {
    final results = searchOpenBoardCards(
      boards: <CardSearchBoard>[
        CardSearchBoard(
          title: 'Roadmap',
          tabId: 'tab-a',
          columns: <BoardColumn>[
            BoardColumn(
              title: 'Doing',
              items: <BoardItem>[BoardItem(id: 'a', title: 'Alpha task')],
            ),
          ],
        ),
        CardSearchBoard(
          title: 'Launch',
          tabId: 'tab-b',
          columns: <BoardColumn>[
            BoardColumn(
              title: 'Next',
              items: <BoardItem>[BoardItem(id: 'b', title: 'Beta task')],
            ),
          ],
        ),
      ],
      query: 'task',
    );

    expect(results.map((CardSearchResult result) => result.itemId), <String>[
      'a',
      'b',
    ]);
    expect(results.last.boardTitle, 'Launch');
    expect(results.last.boardTabId, 'tab-b');
  });
}

List<String> _ids(List<CardSearchResult> results) {
  return results.map((CardSearchResult result) => result.itemId).toList();
}
