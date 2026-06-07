// Generates the managed Mermaid Gantt diagram from authoritative board state.
import '../../domain/board/board_entities.dart';
import '../../domain/board/board_timeline.dart';

class MarkdownBoardMermaidFormatter {
  String format(List<BoardColumn> columns) {
    final entries = BoardTimeline.fromColumns(columns).datedEntries;

    final lines = <String>[
      'gantt',
      '  title Board timeline',
      '  dateFormat YYYY-MM-DD',
      '  axisFormat %Y-%m-%d',
    ];
    if (entries.isNotEmpty) {
      lines.add('  section Dated cards');
    }
    for (final entry in entries) {
      lines.add(
        '  ${_taskLabel(entry)} :${_taskId(entry.item.id)}, '
        '${TodoDateFormatter.format(entry.effectiveStartDate!)}, '
        '${entry.effectiveDurationInDays}d',
      );
    }
    return lines.join('\n');
  }

  String _taskLabel(BoardTimelineEntry entry) {
    final column = _singleLine(entry.columnTitle);
    final item = _singleLine(entry.item.displayTitle);
    return '$column / $item';
  }

  String _taskId(String itemId) {
    final encoded = itemId.codeUnits
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'card_$encoded';
  }

  String _singleLine(String value) {
    return value
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(':', ' -')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
