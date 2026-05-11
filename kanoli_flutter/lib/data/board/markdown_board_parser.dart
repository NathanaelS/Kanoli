// Parses legacy compact Markdown, readable v2 Markdown, and v2.1 card bodies
// into board columns.
import '../../domain/board/board_entities.dart';
import 'markdown_board_parser_helpers.dart';

class MarkdownBoardParser {
  List<BoardColumn> parse(String markdown) {
    // Parser state tracks the current card plus the active readable section.
    // Unsectioned card text becomes bodyMarkdown.
    final parsedColumns = <BoardColumn>[];
    BoardColumn? currentColumn;
    int? currentItemIndex;
    String? currentChecklistId;
    _ReadableSection currentSection = _ReadableSection.none;
    int? currentNoteIndex;

    void trimCurrentNote() {
      if (currentColumn == null ||
          currentItemIndex == null ||
          currentNoteIndex == null) {
        return;
      }

      final note =
          currentColumn.items[currentItemIndex].notes[currentNoteIndex];
      currentColumn.items[currentItemIndex].notes[currentNoteIndex] = BoardNote(
        id: note.id,
        createdAt: note.createdAt,
        text: note.text.trimRight(),
      );
    }

    void appendBodyLine(String rawLine, String trimmedLine) {
      if (currentColumn == null || currentItemIndex == null) {
        return;
      }

      final item = currentColumn.items[currentItemIndex];
      if (trimmedLine.isEmpty && item.bodyMarkdown.isEmpty) {
        return;
      }
      item.bodyMarkdown = item.bodyMarkdown.isEmpty
          ? rawLine
          : '${item.bodyMarkdown}\n$rawLine';
    }

    for (final rawLine in markdown.split('\n')) {
      final line = rawLine.trim();

      // Card and column headings reset nested note/checklist state.
      final itemTitle = headerContent(line, 2);
      if (itemTitle != null) {
        trimCurrentNote();
        if (currentColumn == null) {
          continue;
        }

        final item = parseLegacyCardHeading(itemTitle);
        currentColumn.items.add(item);
        currentItemIndex = currentColumn.items.length - 1;
        currentChecklistId = null;
        currentSection = _ReadableSection.none;
        currentNoteIndex = null;
        continue;
      }

      final columnTitle = headerContent(line, 1);
      if (columnTitle != null) {
        trimCurrentNote();
        if (currentColumn != null) {
          parsedColumns.add(currentColumn);
        }

        currentColumn = BoardColumn(title: columnTitle);
        currentItemIndex = null;
        currentChecklistId = null;
        currentSection = _ReadableSection.none;
        currentNoteIndex = null;
        continue;
      }

      final sectionTitle = headerContent(line, 3);
      if (currentColumn != null &&
          currentItemIndex != null &&
          sectionTitle != null) {
        trimCurrentNote();
        if (sectionTitle.toLowerCase() == 'notes') {
          currentSection = _ReadableSection.notes;
          currentChecklistId = null;
          currentNoteIndex = null;
          continue;
        }

        final checklist = BoardChecklist(title: sectionTitle);
        currentColumn.items[currentItemIndex].checklists.add(checklist);
        currentChecklistId = checklist.id;
        currentSection = _ReadableSection.checklist;
        currentNoteIndex = null;
        continue;
      }

      final noteTitle = headerContent(line, 4);
      if (currentColumn != null &&
          currentItemIndex != null &&
          currentSection == _ReadableSection.notes &&
          noteTitle != null) {
        trimCurrentNote();
        currentColumn.items[currentItemIndex].notes.add(
          BoardNote(text: '', createdAt: NoteDateFormatter.tryParse(noteTitle)),
        );
        currentNoteIndex =
            currentColumn.items[currentItemIndex].notes.length - 1;
        continue;
      }

      final noteLine = noteContent(line);
      if (currentItemIndex != null &&
          noteLine != null &&
          currentColumn != null) {
        // Blockquote lines can be v2 metadata, legacy notes/checklists, or
        // normal Markdown body blockquotes.
        final kanoliMetadata = parseKanoliMetadata(noteLine);
        if (kanoliMetadata != null) {
          if (kanoliMetadata.key == 'checklist') {
            currentChecklistId = setCurrentChecklistId(
              column: currentColumn,
              itemIndex: currentItemIndex,
              currentChecklistId: currentChecklistId,
              newChecklistId: kanoliMetadata.value,
            );
            continue;
          }

          applyItemMetadata(
            key: kanoliMetadata.key,
            value: kanoliMetadata.value,
            column: currentColumn,
            itemIndex: currentItemIndex,
          );
          continue;
        }

        final checklist = parseLegacyChecklist(noteLine);
        if (checklist != null) {
          currentColumn.items[currentItemIndex].checklists.add(checklist);
          currentChecklistId = checklist.id;
          currentSection = _ReadableSection.checklist;
          currentNoteIndex = null;
          continue;
        }

        final checklistItem = parseLegacyChecklistItem(noteLine);
        if (checklistItem != null) {
          currentChecklistId = appendChecklistItem(
            checklistItem: checklistItem,
            column: currentColumn,
            itemIndex: currentItemIndex,
            checklistId: currentChecklistId,
          );
          currentSection = _ReadableSection.checklist;
          currentNoteIndex = null;
          continue;
        }

        final legacyNote = parseLegacyNote(noteLine);
        if (legacyNote != null) {
          currentColumn.items[currentItemIndex].notes.add(legacyNote);
          currentSection = _ReadableSection.none;
          currentNoteIndex = null;
          continue;
        }
      }

      if (currentColumn != null &&
          currentItemIndex != null &&
          currentSection == _ReadableSection.checklist) {
        final readableChecklistItem = parseReadableChecklistItem(line);
        if (readableChecklistItem != null) {
          currentChecklistId = appendChecklistItem(
            checklistItem: readableChecklistItem,
            column: currentColumn,
            itemIndex: currentItemIndex,
            checklistId: currentChecklistId,
          );
          continue;
        }
      }

      if (currentColumn != null &&
          currentItemIndex != null &&
          currentSection == _ReadableSection.notes) {
        // Notes keep their original Markdown line breaks until the next
        // heading starts a different section.
        if (line.isEmpty && currentNoteIndex == null) {
          continue;
        }

        if (currentNoteIndex == null) {
          currentColumn.items[currentItemIndex].notes.add(BoardNote(text: ''));
          currentNoteIndex =
              currentColumn.items[currentItemIndex].notes.length - 1;
        }

        final note =
            currentColumn.items[currentItemIndex].notes[currentNoteIndex];
        final nextText = note.text.isEmpty ? rawLine : '${note.text}\n$rawLine';
        currentColumn.items[currentItemIndex].notes[currentNoteIndex] =
            BoardNote(id: note.id, createdAt: note.createdAt, text: nextText);
        continue;
      }

      if (currentSection == _ReadableSection.none) {
        appendBodyLine(rawLine, line);
      }
    }

    trimCurrentNote();
    if (currentColumn != null) {
      parsedColumns.add(currentColumn);
    }

    for (final column in parsedColumns) {
      for (final item in column.items) {
        item.bodyMarkdown = item.bodyMarkdown.trimRight();
      }
    }
    return parsedColumns;
  }
}

enum _ReadableSection { none, notes, checklist }
