// Covers Markdown v2.1 card body parsing, serialization, and roadmap loading.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/data/board/markdown_board_store.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';

void main() {
  group('MarkdownBoardStore bodyMarkdown', () {
    test('serializes body prose before notes and checklists', () {
      final store = MarkdownBoardStore();
      final noteDate = DateTime.parse('2026-05-10T12:00:00-07:00');
      final formattedNoteDate = NoteDateFormatter.format(noteDate);
      final columns = <BoardColumn>[
        BoardColumn(
          title: 'Next Up',
          items: <BoardItem>[
            BoardItem(
              id: '11111111-1111-1111-1111-111111111111',
              title: 'Readable card',
              bodyMarkdown:
                  '_Summary: Make board files pleasant._\n\n'
                  '**Status:** In progress  \n'
                  '**Decision:** Keep body prose human-only.',
              notes: <BoardNote>[
                BoardNote(
                  createdAt: noteDate,
                  text: '**Context:** Compact files were noisy.',
                ),
              ],
              checklists: <BoardChecklist>[
                BoardChecklist(
                  id: '22222222-2222-2222-2222-222222222222',
                  title: 'Validation',
                  items: <BoardChecklistItem>[
                    BoardChecklistItem(text: 'Write tests', isDone: true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ];

      expect(store.serialize(columns), '''
# Next Up

## Readable card
> kanoli:id 11111111-1111-1111-1111-111111111111

_Summary: Make board files pleasant._

**Status:** In progress  
**Decision:** Keep body prose human-only.

### Notes

#### $formattedNoteDate
**Context:** Compact files were noisy.

### Validation
> kanoli:checklist 22222222-2222-2222-2222-222222222222
- [x] Write tests
''');
    });

    test('parses and preserves markdown emphasis in body prose', () {
      final store = MarkdownBoardStore();
      final columns = store.parse('''
# Next Up

## Readable card
> kanoli:id 11111111-1111-1111-1111-111111111111
> kanoli:labels markdown, readability

_Summary: Make board files pleasant._

**Status:** In progress  
**Decision:** Keep body prose human-only.  
<u>Important:</u> Preserve [links](https://example.com).
> Body blockquotes stay body prose.

### Notes

#### 2026-05-10T12:00:00-07:00
Note text
''');

      final item = columns.single.items.single;

      expect(item.labels, <String>['markdown', 'readability']);
      expect(
        item.bodyMarkdown,
        '_Summary: Make board files pleasant._\n\n'
        '**Status:** In progress  \n'
        '**Decision:** Keep body prose human-only.  \n'
        '<u>Important:</u> Preserve [links](https://example.com).\n'
        '> Body blockquotes stay body prose.',
      );
      expect(item.notes.single.text, 'Note text');
    });

    test('legacy migration does not invent body prose', () {
      final store = MarkdownBoardStore();
      final columns = store.parse('''
# Doing
## Legacy id:11111111-1111-1111-1111-111111111111
> note:2026-05-10T12:00:00-07:00 Legacy note
''');

      final item = columns.single.items.single;

      expect(item.bodyMarkdown, isEmpty);
      expect(store.serialize(columns), isNot(contains('_Summary:')));
    });

    test('parses roadmap board with v2.1 body prose', () {
      final store = MarkdownBoardStore();
      final boardMarkdown = File(
        '../Kanoli_Roadmap_Board.md',
      ).readAsStringSync();
      final columns = store.parse(boardMarkdown);
      final v21Item = columns
          .expand((BoardColumn column) => column.items)
          .firstWhere(
            (BoardItem item) =>
                item.title ==
                'Implement human-readable Markdown v2.1 card bodies',
          );

      expect(v21Item.bodyMarkdown, contains('_Summary:'));
      expect(v21Item.bodyMarkdown, contains('**Decision:**'));
      expect(v21Item.checklists.single.items.length, 4);
    });
  });
}
