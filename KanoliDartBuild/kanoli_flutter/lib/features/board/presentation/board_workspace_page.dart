import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/board/board_entities.dart';
import '../application/board_session_controller.dart';
import 'item_editor_sheet.dart';

class BoardWorkspacePage extends StatefulWidget {
  const BoardWorkspacePage({
    super.key,
    required this.environment,
    required this.controller,
  });

  final AppEnvironment environment;
  final BoardSessionController controller;

  @override
  State<BoardWorkspacePage> createState() => _BoardWorkspacePageState();
}

class _BoardWorkspacePageState extends State<BoardWorkspacePage> {
  static const MethodChannel _nativeDialogs = MethodChannel(
    'kanoli/native_dialogs',
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? child) {
        _showErrorIfNeeded(context);

        final scaffold = Scaffold(
          appBar: AppBar(
            title: const Text('Kanoli (Flutter Port)'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Create Board',
                onPressed: _createBoard,
                icon: const Icon(Icons.note_add_outlined),
              ),
              IconButton(
                tooltip: 'Open Board',
                onPressed: _openBoard,
                icon: const Icon(Icons.folder_open),
              ),
              IconButton(
                tooltip: 'Import Trello JSON',
                onPressed: _importBoard,
                icon: const Icon(Icons.download),
              ),
              IconButton(
                tooltip: widget.controller.isFilterActive
                    ? 'Edit Filter'
                    : 'Filter',
                onPressed: widget.controller.hasActiveBoard
                    ? _editFilter
                    : null,
                icon: Icon(
                  widget.controller.isFilterActive
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
              ),
              if (widget.controller.archiveColumnExists)
                IconButton(
                  tooltip: widget.controller.showArchiveOnly
                      ? 'Show Active Columns'
                      : 'Show Archive Only',
                  onPressed: widget.controller.hasActiveBoard
                      ? widget.controller.toggleArchiveVisibility
                      : null,
                  icon: Icon(
                    widget.controller.showArchiveOnly
                        ? Icons.archive
                        : Icons.archive_outlined,
                  ),
                ),
              IconButton(
                tooltip: 'Close Active Board',
                onPressed: widget.controller.hasActiveBoard
                    ? _closeSelectedTab
                    : null,
                icon: const Icon(Icons.close),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppTheme.workspaceGradient),
            child: widget.controller.hasActiveBoard
                ? _boardView(context)
                : _startupView(context),
          ),
        );

        if (!(Platform.isMacOS && defaultTargetPlatform == TargetPlatform.macOS)) {
          return scaffold;
        }

        return PlatformMenuBar(
          menus: <PlatformMenuItem>[
            PlatformMenu(
              label: 'Kanoli',
              menus: <PlatformMenuItem>[
                PlatformMenuItemGroup(
                  members: <PlatformMenuItem>[
                    if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.about,
                    ))
                      const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.about,
                      ),
                    if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.servicesSubmenu,
                    ))
                      const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.servicesSubmenu,
                      ),
                    if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.hide,
                    ))
                      const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.hide,
                      ),
                    if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.hideOtherApplications,
                    ))
                      const PlatformProvidedMenuItem(
                        type:
                            PlatformProvidedMenuItemType.hideOtherApplications,
                      ),
                    if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.showAllApplications,
                    ))
                      const PlatformProvidedMenuItem(
                        type:
                            PlatformProvidedMenuItemType.showAllApplications,
                      ),
                    if (PlatformProvidedMenuItem.hasMenu(
                      PlatformProvidedMenuItemType.quit,
                    ))
                      const PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.quit,
                      ),
                  ],
                ),
              ],
            ),
            PlatformMenu(
              label: 'File',
              menus: <PlatformMenuItem>[
                PlatformMenuItemGroup(
                  members: <PlatformMenuItem>[
                    PlatformMenuItem(
                      label: 'Create Board',
                      onSelected: () => unawaited(_createBoard()),
                    ),
                    PlatformMenuItem(
                      label: 'Open Board',
                      onSelected: () => unawaited(_openBoard()),
                    ),
                    PlatformMenuItem(
                      label: 'Import Trello JSON',
                      onSelected: () => unawaited(_importBoard()),
                    ),
                    PlatformMenuItem(
                      label: 'Close Active Board',
                      onSelected: widget.controller.hasActiveBoard
                          ? () => unawaited(_closeSelectedTab())
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            PlatformMenu(
              label: 'Edit',
              menus: <PlatformMenuItem>[
                PlatformMenuItemGroup(
                  members: <PlatformMenuItem>[
                    PlatformMenuItem(
                      label: 'Undo',
                      shortcut: const SingleActivator(
                        LogicalKeyboardKey.keyZ,
                        meta: true,
                      ),
                      onSelected: () => Actions.invoke(
                        context,
                        const UndoTextIntent(SelectionChangedCause.keyboard),
                      ),
                    ),
                    PlatformMenuItem(
                      label: 'Redo',
                      shortcut: const SingleActivator(
                        LogicalKeyboardKey.keyZ,
                        shift: true,
                        meta: true,
                      ),
                      onSelected: () => Actions.invoke(
                        context,
                        const RedoTextIntent(SelectionChangedCause.keyboard),
                      ),
                    ),
                    PlatformMenuItem(
                      label: 'Cut',
                      shortcut: const SingleActivator(
                        LogicalKeyboardKey.keyX,
                        meta: true,
                      ),
                      onSelected: () => Actions.invoke(
                        context,
                        const CopySelectionTextIntent.cut(
                          SelectionChangedCause.keyboard,
                        ),
                      ),
                    ),
                    PlatformMenuItem(
                      label: 'Copy',
                      shortcut: const SingleActivator(
                        LogicalKeyboardKey.keyC,
                        meta: true,
                      ),
                      onSelected: () => Actions.invoke(
                        context,
                        CopySelectionTextIntent.copy,
                      ),
                    ),
                    PlatformMenuItem(
                      label: 'Paste',
                      shortcut: const SingleActivator(
                        LogicalKeyboardKey.keyV,
                        meta: true,
                      ),
                      onSelected: () => Actions.invoke(
                        context,
                        const PasteTextIntent(SelectionChangedCause.keyboard),
                      ),
                    ),
                    PlatformMenuItem(
                      label: 'Select All',
                      shortcut: const SingleActivator(
                        LogicalKeyboardKey.keyA,
                        meta: true,
                      ),
                      onSelected: () => Actions.invoke(
                        context,
                        const SelectAllTextIntent(SelectionChangedCause.keyboard),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          child: scaffold,
        );
      },
    );
  }

  Widget _startupView(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.startupPanelGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x6615141B),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Card(
            color: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'No board open',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _createBoard,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.background,
                        ),
                        icon: const Icon(Icons.note_add_outlined),
                        label: const Text('Create File'),
                      ),
                      FilledButton.icon(
                        onPressed: _openBoard,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: AppTheme.background,
                        ),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Open File'),
                      ),
                      FilledButton.icon(
                        onPressed: _importBoard,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.quinary,
                          foregroundColor: AppTheme.background,
                        ),
                        icon: const Icon(Icons.download),
                        label: const Text('Import Trello Board'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boardView(BuildContext context) {
    final tabs = widget.controller.boardTabs;
    final selectedTabId = widget.controller.selectedTabId;
    final columns = widget.controller.isFilterActive
        ? widget.controller.filteredResultsColumns()
        : widget.controller.visibleColumns;

    return Column(
      children: <Widget>[
        if (tabs.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: tabs.map((BoardTabState tab) {
                final isSelected = tab.id == selectedTabId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab.title),
                    selected: isSelected,
                    onSelected: (_) => widget.controller.selectBoardTab(tab.id),
                  ),
                );
              }).toList(),
            ),
          ),
        if (widget.controller.isFilterActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: <Widget>[
                const Icon(Icons.filter_alt, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Filtered results (${columns.length} columns)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.controller.clearBoardFilter,
                  child: const Text('Clear Filter'),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (columns.isEmpty)
                  const SizedBox(
                    width: 320,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No columns to show for the current view.'),
                      ),
                    ),
                  ),
                ...columns.map((BoardColumn column) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _columnCard(context, column),
                  );
                }),
                if (!widget.controller.isFilterActive)
                  SizedBox(
                    width: 240,
                    child: OutlinedButton.icon(
                      onPressed: _addColumn,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Column'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _columnCard(BuildContext context, BoardColumn column) {
    return Card(
      child: SizedBox(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      column.title.trim().isEmpty ? 'New column' : column.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!widget.controller.isFilterActive) ...<Widget>[
                    IconButton(
                      tooltip: 'Rename column',
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _renameColumn(column),
                    ),
                    IconButton(
                      tooltip: 'Delete column',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () =>
                          widget.controller.deleteColumn(column.id),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: <Widget>[
                  if (!widget.controller.isFilterActive)
                    _columnDropTarget(column: column, destinationItemId: null),
                  ...column.items.map((BoardItem item) {
                    return Column(
                      children: <Widget>[
                        _itemTile(item: item, sourceColumn: column),
                        if (!widget.controller.isFilterActive)
                          _columnDropTarget(
                            column: column,
                            destinationItemId: item.id,
                          ),
                      ],
                    );
                  }),
                ],
              ),
              if (!widget.controller.isFilterActive) ...<Widget>[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => _addItem(column),
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemTile({
    required BoardItem item,
    required BoardColumn sourceColumn,
  }) {
    final tile = Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outline),
      ),
      child: ListTile(
        dense: true,
        title: Text(item.displayTitle),
        subtitle: item.metadataSummary.isEmpty
            ? null
            : Text(item.metadataSummary),
        onTap: () => _openItemEditor(item.id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!widget.controller.isFilterActive)
              IconButton(
                tooltip: 'Open item editor',
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: () => _openItemEditor(item.id),
              ),
            IconButton(
              tooltip: 'Item actions',
              icon: const Icon(Icons.more_horiz, size: 18),
              onPressed: () =>
                  _showItemActions(item: item, sourceColumn: sourceColumn),
            ),
          ],
        ),
      ),
    );

    if (widget.controller.isFilterActive) {
      return Padding(padding: const EdgeInsets.only(bottom: 8), child: tile);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LongPressDraggable<_DragItemPayload>(
        data: _DragItemPayload(
          itemId: item.id,
          sourceColumnId: sourceColumn.id,
        ),
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: 280, child: tile),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: tile),
        child: tile,
      ),
    );
  }

  Widget _columnDropTarget({
    required BoardColumn column,
    required String? destinationItemId,
  }) {
    return DragTarget<_DragItemPayload>(
      onWillAcceptWithDetails: (DragTargetDetails<_DragItemPayload> details) {
        return details.data.itemId.isNotEmpty;
      },
      onAcceptWithDetails: (DragTargetDetails<_DragItemPayload> details) {
        widget.controller.moveItemBefore(
          itemId: details.data.itemId,
          destinationColumnId: column.id,
          destinationItemId: destinationItemId,
        );
      },
      builder:
          (
            BuildContext context,
            List<_DragItemPayload?> candidateData,
            List<dynamic> rejectedData,
          ) {
            final isActive = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 8),
              height: isActive ? 16 : 8,
              decoration: BoxDecoration(
                color: isActive ? const Color(0x6654C59F) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isActive
                    ? Border.all(color: const Color(0xAA54C59F))
                    : null,
              ),
            );
          },
    );
  }

  Future<void> _openItemEditor(String itemId) async {
    final item = widget.controller.itemById(itemId);
    if (item == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return ItemEditorSheet(
          item: item,
          boardFilePath: widget.controller.activeBoardPath,
          columnTitle: widget.controller.columnTitleForItem(item.id),
          allColumns: widget.controller.columns.toList(),
          onOpenItem: (String nextItemId) {
            _openItemEditor(nextItemId);
          },
          onSave: (BoardItem updated) {
            widget.controller.replaceItem(updated);
          },
        );
      },
    );
  }

  Future<void> _showItemActions({
    required BoardItem item,
    required BoardColumn sourceColumn,
  }) async {
    final destinationColumns = widget.controller.columns
        .where((BoardColumn column) => column.id != sourceColumn.id)
        .toList();
    final destinationTabs = widget.controller.boardTabs
        .where((BoardTabState tab) => tab.id != widget.controller.selectedTabId)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: <Widget>[
              ListTile(
                title: Text(item.displayTitle),
                subtitle: const Text('Item actions'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.controller.archiveItem(item.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.controller.deleteItem(item.id);
                },
              ),
              if (destinationColumns.isNotEmpty) ...<Widget>[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Move to Column'),
                ),
                ...destinationColumns.map(
                  (BoardColumn column) => ListTile(
                    leading: const Icon(Icons.arrow_right_alt),
                    title: Text(column.menuTitle),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.controller.moveItemToColumn(item.id, column.id);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Copy to Column'),
                ),
                ...destinationColumns.map(
                  (BoardColumn column) => ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(column.menuTitle),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.controller.copyItemToColumn(item.id, column.id);
                    },
                  ),
                ),
              ],
              if (destinationTabs.isNotEmpty) ...<Widget>[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Move to Other Board'),
                ),
                ...destinationTabs.map(
                  (BoardTabState tab) => ListTile(
                    leading: const Icon(Icons.arrow_right_alt),
                    title: Text(tab.title),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.controller.moveItemToBoard(item.id, tab.path);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Copy to Other Board'),
                ),
                ...destinationTabs.map(
                  (BoardTabState tab) => ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(tab.title),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.controller.copyItemToBoard(item.id, tab.path);
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openBoard() async {
    if (Platform.isMacOS) {
      final nativePath = await _nativeOpenBoardPath();
      if (nativePath != null && nativePath.isNotEmpty) {
        await widget.controller.openBoard(nativePath);
        return;
      }
    }

    try {
      final file = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(
            label: 'Board Files',
            extensions: <String>['md', 'txt'],
          ),
        ],
      );

      if (file == null) {
        return;
      }

      await widget.controller.openBoard(file.path);
    } on MissingPluginException {
      await _openBoardViaPathPrompt();
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        'openBoardUiFailure',
        error: error,
        stackTrace: stackTrace,
      );
      await _openBoardViaPathPrompt();
    }
  }

  Future<void> _createBoard() async {
    if (Platform.isMacOS) {
      final nativePath = await _nativeSaveBoardPath('KanoliBoard.md');
      if (nativePath != null && nativePath.isNotEmpty) {
        await widget.controller.createBoard(_normalizeMarkdownPath(nativePath));
        return;
      }
    }

    try {
      const defaultName = 'KanoliBoard.md';
      final path = await _resolveCreatePath(defaultName);
      if (path == null) {
        return;
      }

      await widget.controller.createBoard(path);
    } on MissingPluginException {
      await _createBoardViaPathPrompt('KanoliBoard.md');
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        'createBoardUiFailure',
        error: error,
        stackTrace: stackTrace,
      );
      await _createBoardViaPathPrompt('KanoliBoard.md');
    }
  }

  Future<void> _importBoard() async {
    if (Platform.isMacOS) {
      final jsonPath = await _nativeOpenJsonPath();
      if (jsonPath != null && jsonPath.isNotEmpty) {
        final suggested =
            '${_baseNameWithoutExtension(jsonPath.split(Platform.pathSeparator).last)}.md';
        final boardPath = await _nativeSaveBoardPath(suggested);
        if (boardPath != null && boardPath.isNotEmpty) {
          await widget.controller.importJsonBoard(
            jsonPath: jsonPath,
            boardPath: _normalizeMarkdownPath(boardPath),
          );
          return;
        }
      }
    }

    try {
      final jsonFile = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(label: 'JSON', extensions: <String>['json']),
        ],
      );

      if (jsonFile == null) {
        return;
      }

      final suggested = '${_baseNameWithoutExtension(jsonFile.name)}.md';
      final boardPath = await _resolveCreatePath(suggested);
      if (boardPath == null) {
        return;
      }

      await widget.controller.importJsonBoard(
        jsonPath: jsonFile.path,
        boardPath: boardPath,
      );
    } on MissingPluginException {
      await _importBoardViaPathPrompt();
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        'importBoardUiFailure',
        error: error,
        stackTrace: stackTrace,
      );
      await _importBoardViaPathPrompt();
    }
  }

  Future<void> _closeSelectedTab() async {
    await widget.controller.closeSelectedBoardTab();
  }

  Future<void> _editFilter() async {
    final current = widget.controller.boardFilter;
    final labelsController = TextEditingController(
      text: current.labels.join(', '),
    );
    DueDateRule selectedRule = current.dueDateRule;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final availableLabels = widget.controller
                .availableLabelsAcrossOpenTabs();

            return AlertDialog(
              title: const Text('Filter Cards'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<DueDateRule>(
                      initialValue: selectedRule,
                      decoration: const InputDecoration(labelText: 'Due date'),
                      items: DueDateRule.values
                          .map(
                            (DueDateRule rule) => DropdownMenuItem<DueDateRule>(
                              value: rule,
                              child: Text(_dueDateLabel(rule)),
                            ),
                          )
                          .toList(),
                      onChanged: (DueDateRule? value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedRule = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: labelsController,
                      decoration: const InputDecoration(
                        labelText: 'Labels',
                        hintText: 'comma-separated',
                      ),
                    ),
                    if (availableLabels.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Existing labels: ${availableLabels.join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    widget.controller.clearBoardFilter();
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Clear'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final labels = labelsController.text
        .split(',')
        .map((String value) => _normalizeTag(value))
        .where((String value) => value.isNotEmpty)
        .toList();

    widget.controller.setBoardFilter(dueDateRule: selectedRule, labels: labels);
  }

  Future<void> _addColumn() async {
    final column = widget.controller.addColumn();
    final title = await _promptText(
      context,
      title: 'Column title',
      initialValue: '',
      hintText: 'New column',
      submitLabel: 'Save',
    );

    if (title == null) {
      return;
    }

    widget.controller.updateColumnTitle(column.id, title);
  }

  Future<void> _renameColumn(BoardColumn column) async {
    final title = await _promptText(
      context,
      title: 'Rename column',
      initialValue: column.title,
      hintText: 'Column title',
      submitLabel: 'Save',
    );

    if (title == null) {
      return;
    }

    widget.controller.updateColumnTitle(column.id, title);
  }

  Future<void> _addItem(BoardColumn column) async {
    final item = widget.controller.addItem(column.id);
    if (item == null) {
      return;
    }

    final title = await _promptText(
      context,
      title: 'Item title',
      initialValue: '',
      hintText: 'New item',
      submitLabel: 'Save',
    );

    if (title == null || title.trim().isEmpty) {
      widget.controller.deleteItem(item.id);
      return;
    }

    widget.controller.updateItemTitle(item.id, title);
  }

  void _showErrorIfNeeded(BuildContext context) {
    final message = widget.controller.lastError;
    if (message == null || !mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
      widget.controller.consumeError();
    });
  }

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String hintText,
    required String submitLabel,
  }) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
            onSubmitted: (_) => Navigator.of(context).pop(controller.text),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(submitLabel),
            ),
          ],
        );
      },
    );
  }

  String _baseNameWithoutExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot > 0 ? filename.substring(0, dot) : filename;
  }

  String _normalizeTag(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .join('-');
  }

  String _dueDateLabel(DueDateRule rule) {
    switch (rule) {
      case DueDateRule.any:
        return 'Any due date';
      case DueDateRule.hasDueDate:
        return 'Has due date';
      case DueDateRule.noDueDate:
        return 'No due date';
      case DueDateRule.dueToday:
        return 'Due today';
      case DueDateRule.overdue:
        return 'Overdue';
    }
  }

  Future<String?> _resolveCreatePath(String suggestedName) async {
    try {
      final saveLocation = await getSaveLocation(suggestedName: suggestedName);
      if (saveLocation != null) {
        return _normalizeMarkdownPath(saveLocation.path);
      }
    } on MissingPluginException {
      // Fallback handled below.
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final fallbackPath =
          '${directory.path}${Platform.pathSeparator}$suggestedName';
      return _normalizeMarkdownPath(fallbackPath);
    }

    return null;
  }

  Future<String?> _nativeOpenBoardPath() async {
    try {
      return await _nativeDialogs.invokeMethod<String>('openBoard');
    } on Object {
      return null;
    }
  }

  Future<String?> _nativeOpenJsonPath() async {
    try {
      return await _nativeDialogs.invokeMethod<String>('openJson');
    } on Object {
      return null;
    }
  }

  Future<String?> _nativeSaveBoardPath(String suggestedName) async {
    try {
      return await _nativeDialogs.invokeMethod<String>('saveBoard', <String, Object?>{
        'suggestedName': suggestedName,
      });
    } on Object {
      return null;
    }
  }

  Future<void> _openBoardViaPathPrompt() async {
    final selectedPath = await _promptText(
      context,
      title: 'Open Board',
      initialValue: '',
      hintText: '/path/to/board.md',
      submitLabel: 'Open',
    );
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }
    await widget.controller.openBoard(selectedPath.trim());
  }

  Future<void> _createBoardViaPathPrompt(String suggestedName) async {
    final createPath = await _promptText(
      context,
      title: 'Create Board',
      initialValue: suggestedName,
      hintText: '/path/to/$suggestedName',
      submitLabel: 'Create',
    );
    if (createPath == null || createPath.trim().isEmpty) {
      return;
    }
    await widget.controller.createBoard(createPath.trim());
  }

  Future<void> _importBoardViaPathPrompt() async {
    final jsonPath = await _promptText(
      context,
      title: 'Import Trello JSON',
      initialValue: '',
      hintText: '/path/to/board.json',
      submitLabel: 'Next',
    );
    if (jsonPath == null || jsonPath.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    final boardPath = await _promptText(
      context,
      title: 'Save Imported Board',
      initialValue: 'ImportedBoard.md',
      hintText: '/path/to/ImportedBoard.md',
      submitLabel: 'Import',
    );
    if (boardPath == null || boardPath.trim().isEmpty) {
      return;
    }

    await widget.controller.importJsonBoard(
      jsonPath: jsonPath.trim(),
      boardPath: boardPath.trim(),
    );
  }

  String _normalizeMarkdownPath(String path) {
    if (path.toLowerCase().endsWith('.md')) {
      return path;
    }

    return '$path.md';
  }
}

class _DragItemPayload {
  _DragItemPayload({required this.itemId, required this.sourceColumnId});

  final String itemId;
  final String sourceColumnId;
}
