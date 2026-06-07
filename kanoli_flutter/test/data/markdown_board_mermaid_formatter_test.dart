// Covers deterministic Mermaid Gantt generation from board card state.
import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/data/board/markdown_board_mermaid_formatter.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';

void main() {
  group('MarkdownBoardMermaidFormatter', () {
    test('emits a valid header-only Gantt for boards without dated cards', () {
      final formatter = MarkdownBoardMermaidFormatter();

      expect(formatter.format(<BoardColumn>[]), '''
gantt
  title Board timeline
  dateFormat YYYY-MM-DD
  axisFormat %Y-%m-%d''');
      expect(
        formatter.format(<BoardColumn>[
          BoardColumn(
            title: 'Doing',
            items: <BoardItem>[BoardItem(title: 'Undated')],
          ),
        ]),
        isNot(contains('Undated')),
      );
    });

    test('sorts dated cards by effective range and emits durations', () {
      final formatter = MarkdownBoardMermaidFormatter();
      final columns = <BoardColumn>[
        BoardColumn(
          title: 'Doing',
          items: <BoardItem>[
            _datedItem(id: 'later', title: 'Later', start: '2026-06-08'),
            _datedItem(
              id: 'range',
              title: 'Range',
              start: '2026-06-06',
              due: '2026-06-08',
            ),
          ],
        ),
        BoardColumn(
          title: 'Done',
          items: <BoardItem>[
            _datedItem(
              id: 'same-start-short',
              title: 'Same start short',
              start: '2026-06-06',
              due: '2026-06-06',
            ),
          ],
        ),
      ];

      final mermaid = formatter.format(columns);

      expect(
        mermaid.indexOf('Done / Same start short'),
        lessThan(mermaid.indexOf('Doing / Range')),
      );
      expect(
        mermaid.indexOf('Doing / Range'),
        lessThan(mermaid.indexOf('Doing / Later')),
      );
      expect(mermaid, contains('Done / Same start short'));
      expect(mermaid, contains('2026-06-06, 1d'));
      expect(mermaid, contains('Doing / Range'));
      expect(mermaid, contains('2026-06-06, 3d'));
    });

    test('emits safe stable IDs and single-line task labels', () {
      final formatter = MarkdownBoardMermaidFormatter();
      final mermaid = formatter.format(<BoardColumn>[
        BoardColumn(
          title: 'Doing:\nNow',
          items: <BoardItem>[
            _datedItem(
              id: 'id with punctuation:/',
              title: 'Card:\nTitle',
              due: '2026-06-06',
            ),
          ],
        ),
      ]);

      expect(mermaid, contains('Doing - Now / Card - Title'));
      expect(
        mermaid,
        contains(':card_696420776974682070756e6374756174696f6e3a2f'),
      );
      expect(mermaid, isNot(contains('id with punctuation:/')));
    });
  });
}

BoardItem _datedItem({
  required String id,
  required String title,
  String? start,
  String? due,
}) {
  return BoardItem(
    id: id,
    title: title,
    startDate: start == null ? null : TodoDateFormatter.tryParse(start),
    dueDate: due == null ? null : TodoDateFormatter.tryParse(due),
  );
}
