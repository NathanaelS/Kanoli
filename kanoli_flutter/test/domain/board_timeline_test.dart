// Covers the shared card ordering used by Mermaid and Flutter timelines.
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';
import 'package:kanoli_flutter/domain/board/board_timeline.dart';

void main() {
  test('separates undated cards and sorts dated ties by board order', () {
    final timeline = BoardTimeline.fromColumns(<BoardColumn>[
      BoardColumn(
        title: '',
        items: <BoardItem>[
          _item(id: 'later', due: '2026-06-08'),
          BoardItem(id: 'undated-first', title: 'Undated first'),
          _item(id: 'same-first', due: '2026-06-06'),
        ],
      ),
      BoardColumn(
        title: 'Done',
        items: <BoardItem>[
          _item(id: 'same-second', due: '2026-06-06'),
          BoardItem(id: 'undated-second', title: 'Undated second'),
        ],
      ),
    ]);

    expect(timeline.datedEntries.map((entry) => entry.item.id), <String>[
      'same-first',
      'same-second',
      'later',
    ]);
    expect(timeline.undatedEntries.map((entry) => entry.item.id), <String>[
      'undated-first',
      'undated-second',
    ]);
    expect(timeline.datedEntries.first.columnTitle, 'Untitled column');
    expect(timeline.datedEntries.last.columnIndex, 0);
  });
}

BoardItem _item({required String id, required String due}) {
  return BoardItem(id: id, title: id, dueDate: TodoDateFormatter.tryParse(due));
}
