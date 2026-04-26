import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../../../data/board/json_board_store.dart';
import '../../../data/board/markdown_board_store.dart';
import '../../../domain/board/board_entities.dart';

class BoardTabState {
  BoardTabState({required this.id, required this.path});

  final String id;
  final String path;

  String get normalizedPath => File(path).absolute.path;

  String get title {
    final base = path.split(Platform.pathSeparator).last;
    final dot = base.lastIndexOf('.');
    return dot > 0 ? base.substring(0, dot) : base;
  }
}

class OpenBoardSnapshot {
  OpenBoardSnapshot({required this.boardTitle, required this.columns});

  final String boardTitle;
  final List<BoardColumn> columns;
}

class BoardSessionController extends ChangeNotifier {
  BoardSessionController({
    required this.logger,
    MarkdownBoardStore? markdownBoardStore,
    JsonBoardStore? jsonBoardStore,
  }) : _markdownBoardStore = markdownBoardStore ?? MarkdownBoardStore(),
       _jsonBoardStore = jsonBoardStore ?? JsonBoardStore();

  final AppLogger logger;
  final MarkdownBoardStore _markdownBoardStore;
  final JsonBoardStore _jsonBoardStore;

  final List<BoardTabState> _boardTabs = <BoardTabState>[];
  List<BoardColumn> _columns = <BoardColumn>[];
  String? _selectedTabId;
  String? _lastError;

  BoardFilter _boardFilter = BoardFilter();
  bool _showArchiveOnly = false;
  bool _rememberSessionOnLaunch = true;
  SharedPreferences? _prefs;
  static const String _sessionKey = 'kanoli.session.v1';
  static const String _rememberSessionKey = 'kanoli.session.remember.v1';
  static const String _rememberSessionTouchedKey =
      'kanoli.session.remember.touched.v1';

  UnmodifiableListView<BoardTabState> get boardTabs =>
      UnmodifiableListView<BoardTabState>(_boardTabs);
  UnmodifiableListView<BoardColumn> get columns =>
      UnmodifiableListView<BoardColumn>(_columns);

  String? get selectedTabId => _selectedTabId;
  String? get lastError => _lastError;

  BoardFilter get boardFilter => _boardFilter;
  bool get showArchiveOnly => _showArchiveOnly;
  bool get rememberSessionOnLaunch => _rememberSessionOnLaunch;

  bool get hasActiveBoard => activeBoardPath != null;
  bool get isFilterActive => _boardFilter.isActive;

  bool get archiveColumnExists {
    return _columns.any(_isArchiveColumn);
  }

  Future<void> restoreSessionIfAvailable() async {
    _prefs ??= await SharedPreferences.getInstance();
    final rememberTouched =
        _prefs!.getBool(_rememberSessionTouchedKey) ?? false;
    final storedRemember = _prefs!.getBool(_rememberSessionKey);
    if (!rememberTouched && storedRemember == false) {
      _rememberSessionOnLaunch = true;
      await _prefs!.setBool(_rememberSessionKey, true);
      logger.warning(
        'rememberSessionPreferenceMigrated',
        <String, Object?>{'from': false, 'to': true},
      );
    } else {
      _rememberSessionOnLaunch = storedRemember ?? true;
    }

    if (!_rememberSessionOnLaunch) {
      return;
    }

    final raw = _prefs!.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        return;
      }

      final tabPaths = (map['tabs'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic value) => value.toString())
          .where((String path) => File(path).existsSync())
          .toList();
      final selectedPath = map['selectedPath']?.toString();

      if (tabPaths.isEmpty) {
        return;
      }

      final loadByPath = <String, BoardLoadResult>{};
      for (final path in tabPaths) {
        final loadResult = _markdownBoardStore.loadBoard(path);
        if (loadResult.errorMessage == null) {
          loadByPath[path] = loadResult;
        }
      }

      if (loadByPath.isEmpty) {
        _boardTabs.clear();
        _columns = <BoardColumn>[];
        _selectedTabId = null;
        await _prefs!.remove(_sessionKey);
        return;
      }

      _boardTabs.clear();
      for (final path in loadByPath.keys) {
        _boardTabs.add(BoardTabState(id: IdGenerator.uuid(), path: path));
      }

      final selectedTab =
          _boardTabs
              .where((BoardTabState tab) => tab.path == selectedPath)
              .firstOrNull ??
          _boardTabs.first;
      _selectedTabId = selectedTab.id;

      _columns = loadByPath[selectedTab.path]!.columns;
      if (loadByPath.length != tabPaths.length) {
        unawaited(_persistSessionState());
      }
      notifyListeners();
    } on Object catch (error, stackTrace) {
      logger.error(
        'restoreSessionFailed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? get activeBoardPath {
    if (_selectedTabId == null) {
      return null;
    }

    final tab = _boardTabs
        .where((BoardTabState tab) => tab.id == _selectedTabId)
        .firstOrNull;
    return tab?.path;
  }

  List<BoardColumn> get visibleColumns {
    if (_showArchiveOnly) {
      return _columns.where(_isArchiveColumn).toList();
    }

    return _columns
        .where((BoardColumn column) => !_isArchiveColumn(column))
        .toList();
  }

  List<BoardColumn> filteredResultsColumns() {
    if (!_boardFilter.isActive) {
      return <BoardColumn>[];
    }

    final snapshots = openBoardSnapshots();
    final results = <BoardColumn>[];

    for (final snapshot in snapshots) {
      for (final column in snapshot.columns) {
        final matching = column.items.where(_boardFilter.matches).toList();
        if (matching.isEmpty) {
          continue;
        }

        results.add(
          BoardColumn(
            title: '${snapshot.boardTitle} / ${column.title}',
            items: matching,
          ),
        );
      }
    }

    return results;
  }

  List<String> availableLabelsAcrossOpenTabs() {
    final labels = <String>{};

    for (final item in _columns.expand((BoardColumn column) => column.items)) {
      labels.addAll(item.labels);
    }

    for (final tab in _boardTabs.where(
      (BoardTabState tab) => tab.id != _selectedTabId,
    )) {
      final loadResult = _markdownBoardStore.loadBoard(tab.path);
      if (loadResult.errorMessage != null) {
        continue;
      }

      for (final item in loadResult.columns.expand(
        (BoardColumn column) => column.items,
      )) {
        labels.addAll(item.labels);
      }
    }

    final sorted = labels.toList();
    sorted.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return sorted;
  }

  OpenBoardSnapshot? activeSnapshot() {
    final tab = _boardTabs
        .where((BoardTabState tab) => tab.id == _selectedTabId)
        .firstOrNull;
    if (tab == null) {
      return null;
    }

    return OpenBoardSnapshot(boardTitle: tab.title, columns: _columns);
  }

  List<OpenBoardSnapshot> openBoardSnapshots() {
    final snapshots = <OpenBoardSnapshot>[];

    for (final tab in _boardTabs) {
      if (tab.id == _selectedTabId) {
        snapshots.add(
          OpenBoardSnapshot(boardTitle: tab.title, columns: _columns),
        );
        continue;
      }

      final loadResult = _markdownBoardStore.loadBoard(tab.path);
      if (loadResult.errorMessage != null) {
        continue;
      }

      snapshots.add(
        OpenBoardSnapshot(boardTitle: tab.title, columns: loadResult.columns),
      );
    }

    return snapshots;
  }

  void setBoardFilter({
    required DueDateRule dueDateRule,
    required List<String> labels,
  }) {
    _boardFilter = BoardFilter(dueDateRule: dueDateRule, labels: labels);
    notifyListeners();
  }

  void clearBoardFilter() {
    _boardFilter = BoardFilter();
    notifyListeners();
  }

  void toggleArchiveVisibility() {
    _showArchiveOnly = !_showArchiveOnly;
    notifyListeners();
  }

  Future<void> openBoard(String path) async {
    final normalizedPath = File(path).absolute.path;
    final loadResult = _markdownBoardStore.loadBoard(normalizedPath);

    if (loadResult.errorMessage != null) {
      _setError(loadResult.errorMessage!);
      notifyListeners();
      return;
    }

    _clearError();
    _columns = loadResult.columns;
    _upsertTab(normalizedPath);
    await _persistSessionState();
    logger.info('openBoard', <String, Object?>{'path': normalizedPath});
    notifyListeners();
  }

  Future<void> createBoard(String path) async {
    final normalizedPath = File(path).absolute.path;
    final file = File(normalizedPath);

    if (!file.existsSync()) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('');
    }

    await openBoard(normalizedPath);
  }

  Future<void> importJsonBoard({
    required String jsonPath,
    required String boardPath,
  }) async {
    final normalizedJsonPath = File(jsonPath).absolute.path;
    final normalizedBoardPath = File(boardPath).absolute.path;

    try {
      _jsonBoardStore.importBoard(
        jsonPath: normalizedJsonPath,
        boardPath: normalizedBoardPath,
      );
      await openBoard(normalizedBoardPath);
      logger.info('importJsonBoard', <String, Object?>{
        'jsonPath': normalizedJsonPath,
        'boardPath': normalizedBoardPath,
      });
    } on JsonBoardImportException catch (error, stackTrace) {
      _setError(error.message);
      logger.error(
        'importJsonBoardFailed',
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
    } on Object catch (error, stackTrace) {
      _setError(error.toString());
      logger.error(
        'importJsonBoardFailed',
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }

  Future<void> selectBoardTab(String tabId) async {
    if (_selectedTabId == tabId) {
      return;
    }

    final tab = _boardTabs
        .where((BoardTabState tab) => tab.id == tabId)
        .firstOrNull;
    if (tab == null) {
      return;
    }

    await persistBoard(notify: false);
    await openBoard(tab.path);
  }

  Future<void> closeSelectedBoardTab() async {
    if (_selectedTabId == null) {
      clearSession();
      return;
    }

    await persistBoard(notify: false);

    final closingTabId = _selectedTabId!;
    _boardTabs.removeWhere((BoardTabState tab) => tab.id == closingTabId);

    if (_boardTabs.isEmpty) {
      clearSession();
      return;
    }

    final nextTab = _boardTabs.first;
    unawaited(_persistSessionState());
    await openBoard(nextTab.path);
  }

  Future<void> persistBoard({bool notify = true}) async {
    final activePath = activeBoardPath;
    if (activePath == null) {
      return;
    }

    try {
      _markdownBoardStore.save(columns: _columns, filePath: activePath);
      _clearError();
    } on Object catch (error, stackTrace) {
      _setError(error.toString());
      logger.error('persistBoardFailed', error: error, stackTrace: stackTrace);
    }

    if (notify) {
      notifyListeners();
    }
  }

  BoardColumn addColumn() {
    final column = BoardColumn(title: '');
    _columns = <BoardColumn>[..._columns, column];
    _persistWithoutAwait();
    notifyListeners();
    return column;
  }

  void updateColumnTitle(String columnId, String title) {
    final index = _columns.indexWhere(
      (BoardColumn column) => column.id == columnId,
    );
    if (index < 0) {
      return;
    }

    _columns[index].title = _singleLine(title, limit: 25);
    _persistWithoutAwait();
    notifyListeners();
  }

  void deleteColumn(String columnId) {
    _columns = _columns
        .where((BoardColumn column) => column.id != columnId)
        .toList();
    _persistWithoutAwait();
    notifyListeners();
  }

  BoardItem? addItem(String columnId) {
    final columnIndex = _columns.indexWhere(
      (BoardColumn column) => column.id == columnId,
    );
    if (columnIndex < 0) {
      return null;
    }

    final item = BoardItem(title: '');
    _columns[columnIndex].items = <BoardItem>[
      ..._columns[columnIndex].items,
      item,
    ];
    _persistWithoutAwait();
    notifyListeners();
    return item;
  }

  void reorderItemWithinColumn(String columnId, int oldIndex, int newIndex) {
    final columnIndex = _columns.indexWhere(
      (BoardColumn column) => column.id == columnId,
    );
    if (columnIndex < 0) {
      return;
    }

    final items = _columns[columnIndex].items;
    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        newIndex < 0 ||
        newIndex > items.length) {
      return;
    }

    final adjusted = oldIndex < newIndex ? newIndex - 1 : newIndex;
    final item = items.removeAt(oldIndex);
    items.insert(adjusted, item);
    _persistWithoutAwait();
    notifyListeners();
  }

  void moveItemBefore({
    required String itemId,
    required String destinationColumnId,
    String? destinationItemId,
  }) {
    final source = _itemLocation(itemId);
    final destinationColumnIndex = _columns.indexWhere(
      (BoardColumn column) => column.id == destinationColumnId,
    );
    if (source == null || destinationColumnIndex < 0) {
      return;
    }

    if (destinationItemId == itemId) {
      return;
    }

    final destinationItems = _columns[destinationColumnIndex].items;

    final item = _columns[source.columnIndex].items.removeAt(source.itemIndex);

    int insertionIndex;
    if (destinationItemId == null) {
      insertionIndex = destinationItems.length;
    } else {
      final targetIndex = destinationItems.indexWhere(
        (BoardItem item) => item.id == destinationItemId,
      );
      if (targetIndex < 0) {
        insertionIndex = destinationItems.length;
      } else {
        insertionIndex = targetIndex;
      }
    }

    if (insertionIndex < 0) {
      insertionIndex = 0;
    }
    if (insertionIndex > destinationItems.length) {
      insertionIndex = destinationItems.length;
    }

    destinationItems.insert(insertionIndex, item);
    _persistWithoutAwait();
    notifyListeners();
  }

  void updateItemTitle(String itemId, String title) {
    final location = _itemLocation(itemId);
    if (location == null) {
      return;
    }

    _columns[location.columnIndex].items[location.itemIndex].title =
        _singleLine(title, limit: 80);
    _persistWithoutAwait();
    notifyListeners();
  }

  BoardItem? itemById(String itemId) {
    return _itemById(itemId);
  }

  String? columnTitleForItem(String itemId) {
    final location = _itemLocation(itemId);
    if (location == null) {
      return null;
    }

    return _columns[location.columnIndex].title;
  }

  void replaceItem(BoardItem item) {
    final location = _itemLocation(item.id);
    if (location == null) {
      return;
    }

    _columns[location.columnIndex].items[location.itemIndex] = item;
    _persistWithoutAwait();
    notifyListeners();
  }

  void deleteItem(String itemId) {
    final location = _itemLocation(itemId);
    if (location == null) {
      return;
    }

    _columns[location.columnIndex].items.removeAt(location.itemIndex);
    _persistWithoutAwait();
    notifyListeners();
  }

  void moveItemToColumn(String itemId, String destinationColumnId) {
    final source = _itemLocation(itemId);
    final destinationColumnIndex = _columns.indexWhere(
      (BoardColumn column) => column.id == destinationColumnId,
    );
    if (source == null || destinationColumnIndex < 0) {
      return;
    }

    if (_columns[source.columnIndex].id == destinationColumnId) {
      return;
    }

    final item = _columns[source.columnIndex].items.removeAt(source.itemIndex);
    _columns[destinationColumnIndex].items.add(item);
    _persistWithoutAwait();
    notifyListeners();
  }

  void copyItemToColumn(String itemId, String destinationColumnId) {
    final item = _itemById(itemId);
    final destinationColumnIndex = _columns.indexWhere(
      (BoardColumn column) => column.id == destinationColumnId,
    );
    if (item == null || destinationColumnIndex < 0) {
      return;
    }

    _columns[destinationColumnIndex].items.add(item.duplicatedWithNewIds());
    _persistWithoutAwait();
    notifyListeners();
  }

  Future<void> moveItemToBoard(String itemId, String boardPath) async {
    final item = _itemById(itemId);
    if (item == null) {
      return;
    }

    try {
      _appendItemToBoard(item: item, boardPath: boardPath);
      deleteItem(itemId);
    } on Object catch (error, stackTrace) {
      _setError(error.toString());
      logger.error(
        'moveItemToBoardFailed',
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }

  Future<void> copyItemToBoard(String itemId, String boardPath) async {
    final item = _itemById(itemId);
    if (item == null) {
      return;
    }

    try {
      _appendItemToBoard(
        item: item.duplicatedWithNewIds(),
        boardPath: boardPath,
      );
      notifyListeners();
    } on Object catch (error, stackTrace) {
      _setError(error.toString());
      logger.error(
        'copyItemToBoardFailed',
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }

  void archiveItem(String itemId) {
    String? archiveColumnId;
    final existingArchive = _columns.where(_isArchiveColumn).firstOrNull;

    if (existingArchive != null) {
      archiveColumnId = existingArchive.id;
    } else {
      final archiveColumn = BoardColumn(title: 'Archive');
      _columns = <BoardColumn>[..._columns, archiveColumn];
      archiveColumnId = archiveColumn.id;
    }

    moveItemToColumn(itemId, archiveColumnId);
  }

  void clearSession() {
    _columns = <BoardColumn>[];
    _boardTabs.clear();
    _selectedTabId = null;
    _boardFilter = BoardFilter();
    _showArchiveOnly = false;
    _clearError();
    unawaited(_persistSessionState());
    logger.info('clearSession');
    notifyListeners();
  }

  Future<void> setRememberSessionOnLaunch(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    _rememberSessionOnLaunch = value;
    await _prefs!.setBool(_rememberSessionKey, value);
    await _prefs!.setBool(_rememberSessionTouchedKey, true);
    if (!value) {
      await _prefs!.remove(_sessionKey);
    } else {
      await _persistSessionState();
    }
    logger.info('setRememberSessionOnLaunch', <String, Object?>{
      'enabled': value,
    });
    notifyListeners();
  }

  Future<void> clearRememberedSessionData() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_sessionKey);
    logger.info('clearRememberedSessionData');
    notifyListeners();
  }

  void clearError() {
    if (_lastError == null) {
      return;
    }

    _clearError();
    notifyListeners();
  }

  void consumeError() {
    _clearError();
  }

  void _appendItemToBoard({
    required BoardItem item,
    required String boardPath,
  }) {
    final normalizedPath = File(boardPath).absolute.path;
    final loadResult = _markdownBoardStore.loadBoard(normalizedPath);

    if (loadResult.errorMessage != null && File(normalizedPath).existsSync()) {
      throw StateError(loadResult.errorMessage!);
    }

    final targetColumns = loadResult.columns;
    if (targetColumns.isEmpty) {
      targetColumns.add(BoardColumn(title: 'Inbox'));
    }

    targetColumns.first.items.add(item);
    _markdownBoardStore.save(columns: targetColumns, filePath: normalizedPath);
  }

  void _upsertTab(String normalizedPath) {
    final existing = _boardTabs
        .where((BoardTabState tab) => tab.normalizedPath == normalizedPath)
        .firstOrNull;

    if (existing != null) {
      _selectedTabId = existing.id;
      return;
    }

    final tab = BoardTabState(id: IdGenerator.uuid(), path: normalizedPath);
    _boardTabs.add(tab);
    _selectedTabId = tab.id;
  }

  void _setError(String message) {
    _lastError = message;
  }

  void _clearError() {
    _lastError = null;
  }

  _ItemLocation? _itemLocation(String itemId) {
    for (var columnIndex = 0; columnIndex < _columns.length; columnIndex++) {
      final itemIndex = _columns[columnIndex].items.indexWhere(
        (BoardItem item) => item.id == itemId,
      );
      if (itemIndex >= 0) {
        return _ItemLocation(columnIndex: columnIndex, itemIndex: itemIndex);
      }
    }

    return null;
  }

  BoardItem? _itemById(String itemId) {
    final location = _itemLocation(itemId);
    if (location == null) {
      return null;
    }

    return _columns[location.columnIndex].items[location.itemIndex];
  }

  bool _isArchiveColumn(BoardColumn column) {
    return column.title.trim().toLowerCase() == 'archive';
  }

  String _singleLine(String value, {required int limit}) {
    final singleLine = value.replaceAll('\r', ' ').replaceAll('\n', ' ');
    return singleLine.length > limit
        ? singleLine.substring(0, limit)
        : singleLine;
  }

  void _persistWithoutAwait() {
    persistBoard(notify: false);
  }

  Future<void> _persistSessionState() async {
    _prefs ??= await SharedPreferences.getInstance();

    if (!_rememberSessionOnLaunch) {
      await _prefs!.remove(_sessionKey);
      return;
    }

    final payload = <String, Object?>{
      'tabs': _boardTabs.map((BoardTabState tab) => tab.path).toList(),
      'selectedPath': activeBoardPath,
    };

    await _prefs!.setString(_sessionKey, jsonEncode(payload));
  }
}

class _ItemLocation {
  _ItemLocation({required this.columnIndex, required this.itemIndex});

  final int columnIndex;
  final int itemIndex;
}
