// Represents Kanoli board data plus managed board-level Markdown sections.
import '../../domain/board/board_entities.dart';

class MarkdownBoardDocument {
  MarkdownBoardDocument({required this.columns, this.managedTimelineMermaid});

  final List<BoardColumn> columns;
  final String? managedTimelineMermaid;
}
