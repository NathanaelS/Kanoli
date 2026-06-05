// Facade for reading and writing Kanoli Markdown board files.
import 'dart:io';

import '../../domain/board/board_entities.dart';
import 'markdown_board_document.dart';
import 'markdown_board_mermaid_formatter.dart';
import 'markdown_board_parser.dart';
import 'markdown_board_serializer.dart';
import 'safe_file_store.dart';

class MarkdownBoardStore {
  MarkdownBoardStore({
    SafeFileStore? safeFileStore,
    MarkdownBoardMermaidFormatter? mermaidFormatter,
    MarkdownBoardParser? parser,
    MarkdownBoardSerializer? serializer,
  }) : _safeFileStore = safeFileStore ?? SafeFileStore(),
       _mermaidFormatter = mermaidFormatter ?? MarkdownBoardMermaidFormatter(),
       _parser = parser ?? MarkdownBoardParser(),
       _serializer = serializer ?? MarkdownBoardSerializer();

  final SafeFileStore _safeFileStore;
  final MarkdownBoardMermaidFormatter _mermaidFormatter;
  final MarkdownBoardParser _parser;
  final MarkdownBoardSerializer _serializer;

  BoardLoadResult loadBoard(String filePath) {
    final file = File(filePath);

    if (!file.existsSync()) {
      return BoardLoadResult(
        columns: <BoardColumn>[],
        errorMessage: 'File not found.',
      );
    }

    try {
      final document = parseDocument(file.readAsStringSync());
      return BoardLoadResult(columns: document.columns);
    } on FileSystemException catch (error) {
      return BoardLoadResult(
        columns: <BoardColumn>[],
        errorMessage: error.message,
      );
    } on FormatException catch (error) {
      return BoardLoadResult(
        columns: <BoardColumn>[],
        errorMessage: error.message,
      );
    }
  }

  void save({required List<BoardColumn> columns, required String filePath}) {
    _validateExistingTimeline(filePath);
    _safeFileStore.writeTextAtomic(
      targetPath: filePath,
      content: serializeDocument(
        MarkdownBoardDocument(
          columns: columns,
          managedTimelineMermaid: _mermaidFormatter.format(columns),
        ),
      ),
    );
  }

  List<BoardColumn> parse(String markdown) => _parser.parse(markdown);

  MarkdownBoardDocument parseDocument(String markdown) =>
      _parser.parseDocument(markdown);

  String serialize(List<BoardColumn> columns) => _serializer.serialize(columns);

  String serializeDocument(MarkdownBoardDocument document) =>
      _serializer.serializeDocument(document);

  void _validateExistingTimeline(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return;
    }
    parseDocument(file.readAsStringSync());
  }
}
