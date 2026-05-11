import 'dart:io';

import '../../domain/board/board_entities.dart';
import 'markdown_board_parser.dart';
import 'markdown_board_serializer.dart';
import 'safe_file_store.dart';

class MarkdownBoardStore {
  MarkdownBoardStore({
    SafeFileStore? safeFileStore,
    MarkdownBoardParser? parser,
    MarkdownBoardSerializer? serializer,
  }) : _safeFileStore = safeFileStore ?? SafeFileStore(),
       _parser = parser ?? MarkdownBoardParser(),
       _serializer = serializer ?? MarkdownBoardSerializer();

  final SafeFileStore _safeFileStore;
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
      return BoardLoadResult(columns: parse(file.readAsStringSync()));
    } on FileSystemException catch (error) {
      return BoardLoadResult(
        columns: <BoardColumn>[],
        errorMessage: error.message,
      );
    }
  }

  void save({required List<BoardColumn> columns, required String filePath}) {
    _safeFileStore.writeTextAtomic(
      targetPath: filePath,
      content: serialize(columns),
    );
  }

  List<BoardColumn> parse(String markdown) => _parser.parse(markdown);

  String serialize(List<BoardColumn> columns) => _serializer.serialize(columns);
}
