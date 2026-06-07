// Projects board cards into the shared ordering used by timeline outputs.
import 'board_entities.dart';

class BoardTimeline {
  BoardTimeline._({required this.datedEntries, required this.undatedEntries});

  factory BoardTimeline.fromColumns(List<BoardColumn> columns) {
    final dated = <BoardTimelineEntry>[];
    final undated = <BoardTimelineEntry>[];
    var boardOrder = 0;

    for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
      final column = columns[columnIndex];
      for (final item in column.items) {
        final entry = BoardTimelineEntry(
          item: item,
          columnIndex: columnIndex,
          columnTitle: column.menuTitle,
          boardOrder: boardOrder,
        );
        if (item.dueDate == null) {
          undated.add(entry);
        } else {
          dated.add(entry);
        }
        boardOrder++;
      }
    }

    dated.sort((left, right) {
      final dueComparison = _dateOnly(
        left.dueDate!,
      ).compareTo(_dateOnly(right.dueDate!));
      return dueComparison != 0
          ? dueComparison
          : left.boardOrder.compareTo(right.boardOrder);
    });
    return BoardTimeline._(datedEntries: dated, undatedEntries: undated);
  }

  final List<BoardTimelineEntry> datedEntries;
  final List<BoardTimelineEntry> undatedEntries;

  bool get isEmpty => datedEntries.isEmpty && undatedEntries.isEmpty;

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class BoardTimelineEntry {
  const BoardTimelineEntry({
    required this.item,
    required this.columnIndex,
    required this.columnTitle,
    required this.boardOrder,
  });

  final BoardItem item;
  final int columnIndex;
  final String columnTitle;
  final int boardOrder;

  DateTime? get dueDate => item.dueDate;
}
