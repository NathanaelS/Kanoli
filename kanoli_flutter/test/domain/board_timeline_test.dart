// Covers the shared card ordering used by Mermaid and Flutter timelines.
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';
import 'package:kanoli_flutter/domain/board/board_timeline.dart';

void main() {
  test('builds effective ranges and sorts by start, end, then board order', () {
    final timeline = BoardTimeline.fromColumns(<BoardColumn>[
      BoardColumn(
        title: '',
        items: <BoardItem>[
          _item(id: 'later-range', start: '2026-06-08', due: '2026-06-09'),
          BoardItem(id: 'undated-first', title: 'Undated first'),
          _item(id: 'due-only', due: '2026-06-06'),
        ],
      ),
      BoardColumn(
        title: 'Done',
        items: <BoardItem>[
          _item(id: 'start-only', start: '2026-06-05'),
          _item(id: 'same-start-short', start: '2026-06-07', due: '2026-06-07'),
          _item(id: 'same-start-long', start: '2026-06-07', due: '2026-06-08'),
          BoardItem(id: 'undated-second', title: 'Undated second'),
        ],
      ),
    ]);

    expect(timeline.datedEntries.map((entry) => entry.item.id), <String>[
      'start-only',
      'due-only',
      'same-start-short',
      'same-start-long',
      'later-range',
    ]);
    expect(timeline.undatedEntries.map((entry) => entry.item.id), <String>[
      'undated-first',
      'undated-second',
    ]);
    expect(timeline.datedEntries.first.columnTitle, 'Done');
    expect(timeline.datedEntries.last.columnIndex, 0);
    expect(
      TodoDateFormatter.format(timeline.datedEntries[0].effectiveStartDate!),
      '2026-06-05',
    );
    expect(
      TodoDateFormatter.format(timeline.datedEntries[0].effectiveEndDate!),
      '2026-06-05',
    );
    expect(timeline.datedEntries[3].effectiveDurationInDays, 2);
  });

  test('duplicated cards preserve start and due dates', () {
    final original = BoardItem(
      id: 'original',
      title: 'Original',
      startDate: TodoDateFormatter.tryParse('2026-06-01'),
      dueDate: TodoDateFormatter.tryParse('2026-06-06'),
    );

    final duplicate = original.duplicatedWithNewIds();

    expect(duplicate.id, isNot(original.id));
    expect(
      TodoDateFormatter.format(duplicate.startDate!),
      TodoDateFormatter.format(original.startDate!),
    );
    expect(
      TodoDateFormatter.format(duplicate.dueDate!),
      TodoDateFormatter.format(original.dueDate!),
    );
  });

  test('rejects start dates later than due dates', () {
    expect(
      () => BoardTimeline.fromColumns(<BoardColumn>[
        BoardColumn(
          title: 'Doing',
          items: <BoardItem>[
            _item(id: 'invalid', start: '2026-06-09', due: '2026-06-08'),
          ],
        ),
      ]),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('startDate after dueDate'),
        ),
      ),
    );
  });
}

BoardItem _item({required String id, String? start, String? due}) {
  return BoardItem(
    id: id,
    title: id,
    startDate: start == null ? null : TodoDateFormatter.tryParse(start),
    dueDate: due == null ? null : TodoDateFormatter.tryParse(due),
  );
}
