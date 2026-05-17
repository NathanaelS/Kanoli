// Persistence contract for board stores that load columns from a file path.
import '../../domain/board/board_entities.dart';

abstract interface class BoardRepository {
  Future<List<BoardColumn>> loadBoard(String path);
  Future<void> saveBoard(String path, List<BoardColumn> columns);
}
