import 'package:flutter_test/flutter_test.dart';
import 'package:kanoli_flutter/data/board/json_board_store.dart';
import 'package:kanoli_flutter/domain/board/board_entities.dart';

void main() {
  group('JsonBoardStore', () {
    test('decodes Kanoli JSON columns/items/notes/checklists', () {
      const data = '''
{
  "columns": [
    {
      "title": "Backlog",
      "items": [
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "title": "Import JSON",
          "notes": [
            "Plain note",
            {
              "createdAt": "2026-04-13T12:30:00-07:00",
              "text": "Dated note"
            }
          ],
          "dueDate": "2026-04-20",
          "priority": "A",
          "labels": ["import", "json"],
          "checklists": [
            {
              "id": "22222222-2222-2222-2222-222222222222",
              "title": "Steps",
              "items": [
                {
                  "id": "33333333-3333-3333-3333-333333333333",
                  "text": "Choose file",
                  "isDone": true
                },
                {
                  "text": "Save markdown"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
''';

      final store = JsonBoardStore();
      final columns = store.decodeBoard(data);
      final item = columns.first.items.first;
      final checklist = item.checklists.first;

      expect(columns.first.title, 'Backlog');
      expect(item.id, '11111111-1111-1111-1111-111111111111');
      expect(item.title, 'Import JSON');
      expect(item.notes.map((BoardNote note) => note.text), <String>[
        'Plain note',
        'Dated note',
      ]);
      expect(TodoDateFormatter.format(item.dueDate!), '2026-04-20');
      expect(item.priority, 'A');
      expect(item.labels, <String>['import', 'json']);
      expect(checklist.id, '22222222-2222-2222-2222-222222222222');
      expect(
        checklist.items.map(
          (BoardChecklistItem checklistItem) => checklistItem.text,
        ),
        <String>['Choose file', 'Save markdown'],
      );
      expect(
        checklist.items.map(
          (BoardChecklistItem checklistItem) => checklistItem.isDone,
        ),
        <bool>[true, false],
      );
    });

    test('decodes Trello board export', () {
      const data = '''
{
  "lists": [
    {
      "id": "list-doing",
      "name": "Doing",
      "pos": 1
    }
  ],
  "cards": [
    {
      "id": "card-1",
      "idList": "list-doing",
      "name": "Import from Trello",
      "desc": "Bring in existing board",
      "idLabels": ["label-1"],
      "pos": 1,
      "due": "2026-04-20T17:00:00.000Z"
    }
  ],
  "checklists": [
    {
      "id": "checklist-1",
      "idCard": "card-1",
      "name": "Steps",
      "pos": 1,
      "checkItems": [
        {
          "name": "Map lists",
          "pos": 1,
          "state": "incomplete"
        },
        {
          "name": "Map cards",
          "pos": 2,
          "state": "complete"
        }
      ]
    }
  ],
  "labels": [
    {
      "id": "label-1",
      "name": "import"
    }
  ],
  "actions": [
    {
      "type": "commentCard",
      "date": "2026-04-12T12:00:00.000Z",
      "data": {
        "text": "Comment note",
        "card": {
          "id": "card-1"
        }
      }
    }
  ]
}
''';

      final store = JsonBoardStore();
      final columns = store.decodeBoard(data);
      final item = columns.first.items.first;
      final checklist = item.checklists.first;

      expect(columns.first.title, 'Doing');
      expect(item.title, 'Import from Trello');
      expect(item.notes.map((BoardNote note) => note.text), <String>[
        'Bring in existing board',
        'Comment note',
      ]);
      expect(item.labels, <String>['import']);
      expect(TodoDateFormatter.format(item.dueDate!), '2026-04-20');
      expect(checklist.title, 'Steps');
      expect(
        checklist.items.map(
          (BoardChecklistItem checklistItem) => checklistItem.text,
        ),
        <String>['Map lists', 'Map cards'],
      );
      expect(
        checklist.items.map(
          (BoardChecklistItem checklistItem) => checklistItem.isDone,
        ),
        <bool>[false, true],
      );
    });

    test('rejects invalid imported due date format', () {
      const data = '''
{
  "columns": [
    {
      "title": "Backlog",
      "items": [
        {
          "title": "Bad date",
          "dueDate": "04/21/2026"
        }
      ]
    }
  ]
}
''';

      final store = JsonBoardStore();

      expect(
        () => store.decodeBoard(data),
        throwsA(isA<JsonBoardImportException>()),
      );
    });
  });
}
