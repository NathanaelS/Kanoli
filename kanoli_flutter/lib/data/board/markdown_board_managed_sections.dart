// Extracts and emits Kanoli-managed board-level Markdown sections.
class MarkdownBoardManagedSections {
  static const timelineStart = '<!-- kanoli:timeline:start -->';
  static const timelineEnd = '<!-- kanoli:timeline:end -->';

  ManagedMarkdownSections extract(String markdown) {
    final startIndexes = _allIndexes(markdown, timelineStart);
    final endIndexes = _allIndexes(markdown, timelineEnd);

    if (startIndexes.isEmpty && endIndexes.isEmpty) {
      return ManagedMarkdownSections(boardMarkdown: markdown);
    }
    if (startIndexes.length != 1 || endIndexes.length != 1) {
      throw const FormatException(
        'Expected exactly one managed Kanoli timeline section.',
      );
    }

    final start = startIndexes.single;
    final end = endIndexes.single;
    if (end < start) {
      throw const FormatException(
        'Managed Kanoli timeline section ends before it starts.',
      );
    }

    final sectionStart = start + timelineStart.length;
    final rawSection = markdown.substring(sectionStart, end).trim();
    final mermaid = _parseMermaidFence(rawSection);
    final before = markdown.substring(0, start).trimRight();
    final after = markdown.substring(end + timelineEnd.length).trimLeft();
    final boardMarkdown = <String>[
      if (before.isNotEmpty) before,
      if (after.isNotEmpty) after,
    ].join('\n\n');

    return ManagedMarkdownSections(
      boardMarkdown: boardMarkdown,
      timelineMermaid: mermaid,
    );
  }

  String appendTimeline(String boardMarkdown, String mermaid) {
    final normalizedBoard = boardMarkdown.trimRight();
    if (mermaid.trim().isEmpty) {
      throw const FormatException(
        'Managed Kanoli timeline Mermaid content cannot be empty.',
      );
    }

    final section =
        '''
$timelineStart
```mermaid
$mermaid
```
$timelineEnd''';
    if (normalizedBoard.isEmpty) {
      return '$section\n';
    }
    return '$normalizedBoard\n\n$section\n';
  }

  String _parseMermaidFence(String section) {
    const openingFence = '```mermaid';
    const closingFence = '```';
    if (!section.startsWith('$openingFence\n') ||
        !section.endsWith('\n$closingFence')) {
      throw const FormatException(
        'Managed Kanoli timeline section must contain one Mermaid fence.',
      );
    }

    final content = section.substring(
      openingFence.length + 1,
      section.length - closingFence.length - 1,
    );
    if (content.trim().isEmpty || content.contains('\n```\n')) {
      throw const FormatException(
        'Managed Kanoli timeline section must contain one non-empty fence.',
      );
    }
    return content;
  }

  List<int> _allIndexes(String value, String pattern) {
    final indexes = <int>[];
    var start = 0;
    while (true) {
      final index = value.indexOf(pattern, start);
      if (index < 0) {
        return indexes;
      }
      indexes.add(index);
      start = index + pattern.length;
    }
  }
}

class ManagedMarkdownSections {
  ManagedMarkdownSections({required this.boardMarkdown, this.timelineMermaid});

  final String boardMarkdown;
  final String? timelineMermaid;
}
