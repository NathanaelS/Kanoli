// Covers the managed board-level Mermaid timeline persistence contract.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/data/board/markdown_board_document.dart';
import 'package:kanoli_flutter/data/board/markdown_board_store.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';

void main() {
  group('managed Mermaid timeline section', () {
    test('existing board without Mermaid keeps existing serialization', () {
      final store = MarkdownBoardStore();
      const markdown = '''
# Doing

## Existing card
> kanoli:id 11111111-1111-1111-1111-111111111111
''';

      final document = store.parseDocument(markdown);

      expect(document.managedTimelineMermaid, isNull);
      expect(store.serializeDocument(document), markdown);
    });

    test('round-trips one managed Mermaid block at the document end', () {
      final store = MarkdownBoardStore();
      const markdown = '''
# Doing

## Dated card
> kanoli:id 11111111-1111-1111-1111-111111111111
> kanoli:due 2026-06-04

<!-- kanoli:timeline:start -->
```mermaid
gantt
  title Board timeline
  Dated card :11111111, 2026-06-04, 1d
```
<!-- kanoli:timeline:end -->
''';

      final document = store.parseDocument(markdown);

      expect(document.columns.single.items.single.title, 'Dated card');
      expect(document.managedTimelineMermaid, '''
gantt
  title Board timeline
  Dated card :11111111, 2026-06-04, 1d''');
      expect(store.serializeDocument(document), markdown);
    });

    test('legacy column-only API does not silently consume managed blocks', () {
      final store = MarkdownBoardStore();
      const markdown = '''
# Doing

## Dated card
> kanoli:id 11111111-1111-1111-1111-111111111111

<!-- kanoli:timeline:start -->
```mermaid
gantt
  title Board timeline
```
<!-- kanoli:timeline:end -->
''';

      final columns = store.parse(markdown);

      expect(
        columns.single.items.single.bodyMarkdown,
        contains('<!-- kanoli:timeline:start -->'),
      );
      expect(
        store.serialize(columns),
        contains('<!-- kanoli:timeline:end -->'),
      );
    });

    test(
      'load and save regenerate managed timeline without making it card body',
      () {
        final store = MarkdownBoardStore();
        final file = _tempMarkdownFile('''
# Doing

## Dated card
> kanoli:id 11111111-1111-1111-1111-111111111111
> kanoli:due 2026-06-04

<!-- kanoli:timeline:start -->
```mermaid
gantt
  title Board timeline
  Dated card :11111111, 2026-06-04, 1d
```
<!-- kanoli:timeline:end -->
''');

        final loaded = store.loadBoard(file.path);
        loaded.columns.single.items.single.title = 'Renamed card';
        store.save(columns: loaded.columns, filePath: file.path);

        final saved = file.readAsStringSync();
        expect(loaded.errorMessage, isNull);
        expect(loaded.columns.single.items.single.bodyMarkdown, isEmpty);
        expect(saved, contains('## Renamed card'));
        expect(saved, contains('Doing / Renamed card :card_'));
        expect(saved, contains(', 2026-06-04, 1d'));
        expect(saved, isNot(contains('Dated card :11111111')));
        expect(
          '<!-- kanoli:timeline:start -->'.allMatches(saved),
          hasLength(1),
        );
      },
    );

    test('load and save replace managed Mermaid payload canonically', () {
      final store = MarkdownBoardStore();
      final file = _tempMarkdownFile('''
# Doing

<!-- kanoli:timeline:start -->
```mermaid
gantt

  title Board timeline  
```
<!-- kanoli:timeline:end -->
''');

      final loaded = store.loadBoard(file.path);
      store.save(columns: loaded.columns, filePath: file.path);

      expect(
        file.readAsStringSync(),
        contains('''```mermaid
gantt
  title Board timeline
  dateFormat YYYY-MM-DD
  axisFormat %Y-%m-%d
```'''),
      );
      expect(file.readAsStringSync(), isNot(contains('Board timeline  ')));
    });

    test('save preserves unrelated fenced card body with managed timeline', () {
      final store = MarkdownBoardStore();
      final file = _tempMarkdownFile('''
# Doing

## Document syntax
> kanoli:id 11111111-1111-1111-1111-111111111111

```dart
final value = 1;
```

<!-- kanoli:timeline:start -->
```mermaid
gantt
  title Board timeline
```
<!-- kanoli:timeline:end -->
''');

      final loaded = store.loadBoard(file.path);
      store.save(columns: loaded.columns, filePath: file.path);

      expect(
        file.readAsStringSync(),
        contains('''
```dart
final value = 1;
```'''),
      );
      expect(file.readAsStringSync(), contains('```mermaid\ngantt'));
    });

    test('malformed managed timeline blocks load and save explicitly', () {
      final store = MarkdownBoardStore();
      final file = _tempMarkdownFile('''
# Doing

<!-- kanoli:timeline:start -->
```text
gantt
```
<!-- kanoli:timeline:end -->
''');
      final original = file.readAsStringSync();

      final loaded = store.loadBoard(file.path);

      expect(loaded.columns, isEmpty);
      expect(loaded.errorMessage, contains('must contain one Mermaid fence'));
      expect(
        () => store.save(columns: <BoardColumn>[], filePath: file.path),
        throwsFormatException,
      );
      expect(file.readAsStringSync(), original);
    });

    test('preserves unrelated fenced content as card body Markdown', () {
      final store = MarkdownBoardStore();
      const markdown = '''
# Doing

## Document syntax
> kanoli:id 11111111-1111-1111-1111-111111111111

```dart
final value = 1;
```

<!-- kanoli:timeline:start -->
```mermaid
gantt
  title Board timeline
```
<!-- kanoli:timeline:end -->
''';

      final document = store.parseDocument(markdown);

      expect(
        document.columns.single.items.single.bodyMarkdown,
        '```dart\nfinal value = 1;\n```',
      );
      expect(store.serializeDocument(document), markdown);
    });

    test('rejects duplicate or malformed managed timeline sections', () {
      final store = MarkdownBoardStore();

      expect(
        () => store.parseDocument('''
<!-- kanoli:timeline:start -->
```mermaid
gantt
```
<!-- kanoli:timeline:end -->
<!-- kanoli:timeline:start -->
```mermaid
gantt
```
<!-- kanoli:timeline:end -->
'''),
        throwsFormatException,
      );
      expect(
        () => store.parseDocument('''
<!-- kanoli:timeline:start -->
```text
gantt
```
<!-- kanoli:timeline:end -->
'''),
        throwsFormatException,
      );
    });

    test('serializes a document with a managed timeline deterministically', () {
      final store = MarkdownBoardStore();
      final document = MarkdownBoardDocument(
        columns: <BoardColumn>[
          BoardColumn(
            title: 'Doing',
            items: <BoardItem>[
              BoardItem(
                id: '11111111-1111-1111-1111-111111111111',
                title: 'Dated card',
              ),
            ],
          ),
        ],
        managedTimelineMermaid: 'gantt\n  title Board timeline',
      );

      final first = store.serializeDocument(document);
      final second = store.serializeDocument(store.parseDocument(first));

      expect(second, first);
      expect(first, endsWith('<!-- kanoli:timeline:end -->\n'));
    });
  });
}

File _tempMarkdownFile(String contents) {
  final directory = Directory.systemTemp.createTempSync('kanoli_mermaid_test_');
  return File('${directory.path}/board.md')..writeAsStringSync(contents);
}
