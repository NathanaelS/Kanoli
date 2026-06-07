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
        if (entry.effectiveStartDate == null) {
          undated.add(entry);
        } else {
          dated.add(entry);
        }
        boardOrder++;
      }
    }

    dated.sort((left, right) {
      final startComparison = _dateOnly(
        left.effectiveStartDate!,
      ).compareTo(_dateOnly(right.effectiveStartDate!));
      if (startComparison != 0) {
        return startComparison;
      }

      final endComparison = _dateOnly(
        left.effectiveEndDate!,
      ).compareTo(_dateOnly(right.effectiveEndDate!));
      return endComparison != 0
          ? endComparison
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

  DateTime? get startDate => item.startDate;
  DateTime? get dueDate => item.dueDate;

  DateTime? get effectiveStartDate {
    final range = _effectiveRange();
    return range.$1;
  }

  DateTime? get effectiveEndDate {
    final range = _effectiveRange();
    return range.$2;
  }

  int? get effectiveDurationInDays {
    final start = effectiveStartDate;
    final end = effectiveEndDate;
    if (start == null || end == null) {
      return null;
    }
    return BoardTimeline._dateOnly(
          end,
        ).difference(BoardTimeline._dateOnly(start)).inDays +
        1;
  }

  (DateTime?, DateTime?) _effectiveRange() {
    final start = startDate;
    final due = dueDate;
    if (start != null && due != null) {
      final normalizedStart = BoardTimeline._dateOnly(start);
      final normalizedDue = BoardTimeline._dateOnly(due);
      if (normalizedStart.isAfter(normalizedDue)) {
        throw ArgumentError(
          'Board item ${item.id} has startDate after dueDate.',
        );
      }
      return (start, due);
    }
    if (due != null) {
      return (due, due);
    }
    if (start != null) {
      return (start, start);
    }
    return (null, null);
  }
}
