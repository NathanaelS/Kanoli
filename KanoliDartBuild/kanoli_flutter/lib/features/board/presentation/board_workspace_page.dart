import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final AuraIntensity _auraIntensity = AuraIntensity.subtle;
  static const MethodChannel _nativeDialogsChannel = MethodChannel(
    'kanoli/native_dialogs',
  );
  String? _pendingNewColumnId;
  String? _pendingNewItemId;
  final TextEditingController _newColumnTitleController =
      TextEditingController();
  final TextEditingController _newItemTitleController = TextEditingController();
  final FocusNode _newColumnTitleFocusNode = FocusNode();
  final FocusNode _newItemTitleFocusNode = FocusNode();
  bool _dialogInProgress = false;

  @override
  void dispose() {
    _newColumnTitleController.dispose();
    _newItemTitleController.dispose();
    _newColumnTitleFocusNode.dispose();
    _newItemTitleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = AppTheme.visuals(_auraIntensity);
    final body = ListenableBuilder(
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
            decoration: BoxDecoration(gradient: visuals.workspaceGradient),
            child: Stack(
              children: <Widget>[
                if (_auraIntensity == AuraIntensity.vivid)
                  Positioned(
                    left: -140,
                    top: -120,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              visuals.primaryGlow,
                              const Color(0x008464C6),
                            ],
                            radius: 0.9,
                          ),
                        ),
                        child: const SizedBox(width: 360, height: 360),
                      ),
                    ),
                  ),
                if (_auraIntensity == AuraIntensity.vivid)
                  Positioned(
                    right: -110,
                    bottom: -90,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              visuals.secondaryGlow,
                              const Color(0x0054C59F),
                            ],
                            radius: 0.9,
                          ),
                        ),
                        child: const SizedBox(width: 320, height: 320),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: widget.controller.hasActiveBoard
                      ? _boardView(context, visuals)
                      : _startupView(context, visuals),
                ),
              ],
            ),
          ),
        );

        return scaffold;
      },
    );

    if (!(Platform.isMacOS && defaultTargetPlatform == TargetPlatform.macOS)) {
      return body;
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
                    type: PlatformProvidedMenuItemType.hideOtherApplications,
                  ),
                if (PlatformProvidedMenuItem.hasMenu(
                  PlatformProvidedMenuItemType.showAllApplications,
                ))
                  const PlatformProvidedMenuItem(
                    type: PlatformProvidedMenuItemType.showAllApplications,
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
                  onSelected: () => unawaited(_closeSelectedTab()),
                ),
                PlatformMenuItem(
                  label: 'Close Window',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyW,
                    meta: true,
                  ),
                  onSelected: () => unawaited(_hideWindowViaNative()),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'View',
          menus: <PlatformMenuItem>[
            PlatformMenuItemGroup(
              members: <PlatformMenuItem>[
                PlatformMenuItem(
                  label: 'Show Kanoli Window',
                  onSelected: () => unawaited(_showWindowViaNative()),
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
                  onSelected: () =>
                      Actions.invoke(context, CopySelectionTextIntent.copy),
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
      child: body,
    );
  }

  Widget _startupView(BuildContext context, AuraVisualProfile visuals) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: visuals.startupPanelGradient,
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

  Widget _boardView(BuildContext context, AuraVisualProfile visuals) {
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
                    backgroundColor: AppTheme.selection,
                    selectedColor: AppTheme.secondary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.background
                          : AppTheme.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(color: AppTheme.outline),
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
                    child: _columnCard(context, column, visuals),
                  );
                }),
                if (!widget.controller.isFilterActive)
                  SizedBox(
                    width: 240,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: visuals.addColumnButtonGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: OutlinedButton.icon(
                        onPressed: _addColumn,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.foreground,
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Column'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _columnCard(
    BuildContext context,
    BoardColumn column,
    AuraVisualProfile visuals,
  ) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        gradient: visuals.columnPanelGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _pendingNewColumnId == column.id
                      ? TextField(
                          controller: _newColumnTitleController,
                          focusNode: _newColumnTitleFocusNode,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'New column',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _commitPendingNewColumn(),
                          onTapOutside: (_) => _commitPendingNewColumn(),
                        )
                      : Text(
                          column.title.trim().isEmpty
                              ? 'New column'
                              : column.title,
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
                    onPressed: () => widget.controller.deleteColumn(column.id),
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
                      _itemTile(
                        item: item,
                        sourceColumn: column,
                        visuals: visuals,
                      ),
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
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: visuals.addItemButtonGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.background,
                  ),
                  onPressed: () => _addItem(column),
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemTile({
    required BoardItem item,
    required BoardColumn sourceColumn,
    required AuraVisualProfile visuals,
  }) {
    final tile = Container(
      decoration: BoxDecoration(
        gradient: visuals.itemCardGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outline),
      ),
      child: ListTile(
        dense: true,
        title: _pendingNewItemId == item.id
            ? TextField(
                controller: _newItemTitleController,
                focusNode: _newItemTitleFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'New item',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _commitPendingNewItem(),
                onTapOutside: (_) => _commitPendingNewItem(),
              )
            : Text(item.displayTitle),
        subtitle: item.metadataSummary.isEmpty
            ? null
            : Text(item.metadataSummary),
        onTap: _pendingNewItemId == item.id
            ? null
            : () => _openItemEditor(item.id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!widget.controller.isFilterActive)
              IconButton(
                tooltip: 'Open item editor',
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: _pendingNewItemId == item.id
                    ? null
                    : () => _openItemEditor(item.id),
              ),
            IconButton(
              tooltip: 'Item actions',
              icon: const Icon(Icons.more_horiz, size: 18),
              onPressed: _pendingNewItemId == item.id
                  ? null
                  : () => _showItemActions(
                      item: item,
                      sourceColumn: sourceColumn,
                    ),
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
      if (_dialogInProgress) {
        widget.controller.logger.warning('dialogBusy', <String, Object?>{
          'requested': 'openBoard',
        });
        return;
      }
      _dialogInProgress = true;
      widget.controller.logger.info('openBoardUiStart', <String, Object?>{
        'platform': 'macos',
      });
      try {
        final nativePath = await _chooseFileViaNativeDialog(
          method: 'openBoard',
        );
        if (nativePath == null || nativePath.trim().isEmpty) {
          widget.controller.logger.warning(
            'openBoardUiCancelled',
            <String, Object?>{'source': 'native'},
          );
          return;
        }
        widget.controller.logger.info('openBoardUiSelected', <String, Object?>{
          'path': nativePath,
          'source': 'native',
        });
        await widget.controller.openBoard(nativePath);
      } on Object catch (error, stackTrace) {
        widget.controller.logger.error(
          'openBoardUiFailure',
          error: error,
          stackTrace: stackTrace,
          metadata: <String, Object?>{'platform': 'macos'},
        );
      } finally {
        _dialogInProgress = false;
      }
      return;
    }

    try {
      final file = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(label: 'Board Files', extensions: <String>['md', 'txt']),
        ],
      ).timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (file == null) {
        await _openBoardViaPathPrompt();
        return;
      }
      await widget.controller.openBoard(file.path);
    } on Object catch (error, stackTrace) {
      widget.controller.logger.error(
        'openBoardUiFailure',
        error: error,
        stackTrace: stackTrace,
      );
      await _openBoardViaPathPrompt();
    }
  }

  Future<void> _hideWindowViaNative() async {
    if (!Platform.isMacOS) {
      return;
    }

    try {
      await _nativeDialogsChannel.invokeMethod<void>('hideWindow');
    } on PlatformException {
      // Ignore on unsupported hosts.
    }
  }

  Future<void> _showWindowViaNative() async {
    if (!Platform.isMacOS) {
      return;
    }

    try {
      await _nativeDialogsChannel.invokeMethod<void>('showWindow');
    } on PlatformException {
      // Ignore on unsupported hosts.
    }
  }

  Future<void> _createBoard() async {
    if (Platform.isMacOS) {
      if (_dialogInProgress) {
        widget.controller.logger.warning('dialogBusy', <String, Object?>{
          'requested': 'createBoard',
        });
        return;
      }
      _dialogInProgress = true;
      widget.controller.logger.info('createBoardUiStart', <String, Object?>{
        'platform': 'macos',
      });
      try {
        final nativePath = await _chooseSaveViaNativeDialog(
          suggestedName: 'KanoliBoard.md',
        );
        if (nativePath != null && nativePath.trim().isNotEmpty) {
          widget.controller.logger.info(
            'createBoardUiSelected',
            <String, Object?>{'path': nativePath, 'source': 'native'},
          );
          await widget.controller.createBoard(
            _normalizeMarkdownPath(nativePath),
          );
          return;
        }

        widget.controller.logger.warning(
          'createBoardUiCancelled',
          <String, Object?>{'source': 'native'},
        );
      } finally {
        _dialogInProgress = false;
      }
      return;
    }

    try {
      final saveLocation = await getSaveLocation(
        suggestedName: 'KanoliBoard.md',
      ).timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (saveLocation == null) {
        await _createBoardViaPathPrompt('KanoliBoard.md');
        return;
      }

      await widget.controller.createBoard(
        _normalizeMarkdownPath(saveLocation.path),
      );
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
      if (_dialogInProgress) {
        widget.controller.logger.warning('dialogBusy', <String, Object?>{
          'requested': 'importBoard',
        });
        return;
      }
      _dialogInProgress = true;
      widget.controller.logger.info('importBoardUiStart', <String, Object?>{
        'platform': 'macos',
      });
      try {
        final jsonPath = await _chooseFileViaNativeDialog(method: 'openJson');
        if (jsonPath == null || jsonPath.trim().isEmpty) {
          widget.controller.logger.warning(
            'importBoardUiCancelled',
            <String, Object?>{'source': 'native_open'},
          );
          return;
        }
        if (!_isJsonPath(jsonPath)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a .json file to import.'),
              ),
            );
          }
          widget.controller.logger.warning(
            'importBoardInvalidType',
            <String, Object?>{'path': jsonPath},
          );
          return;
        }
        final jsonFile = XFile(jsonPath);

        widget.controller.logger.info(
          'importBoardUiSelectedJson',
          <String, Object?>{'path': jsonFile.path, 'source': 'native_open'},
        );
        final suggested = '${_baseNameWithoutExtension(jsonFile.name)}.md';
        final savePath = await _chooseSaveViaNativeDialog(
          suggestedName: suggested,
        );
        if (savePath == null || savePath.trim().isEmpty) {
          widget.controller.logger.warning(
            'importBoardUiCancelled',
            <String, Object?>{'source': 'native_save'},
          );
          return;
        }
        widget.controller.logger.info(
          'importBoardUiSelectedSavePath',
          <String, Object?>{'path': savePath},
        );
        await widget.controller.importJsonBoard(
          jsonPath: jsonFile.path,
          boardPath: _normalizeMarkdownPath(savePath),
        );
      } on Object catch (error, stackTrace) {
        widget.controller.logger.error(
          'importBoardUiFailure',
          error: error,
          stackTrace: stackTrace,
          metadata: <String, Object?>{'platform': 'macos'},
        );
      } finally {
        _dialogInProgress = false;
      }
      return;
    }

    try {
      final jsonFile = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(
            label: 'JSON',
            extensions: <String>['json'],
            mimeTypes: <String>['application/json', 'text/json'],
            uniformTypeIdentifiers: <String>['public.json'],
          ),
        ],
      ).timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (jsonFile == null) {
        await _importBoardViaPathPrompt();
        return;
      }

      final suggested = '${_baseNameWithoutExtension(jsonFile.name)}.md';
      final saveLocation = await getSaveLocation(
        suggestedName: suggested,
      ).timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (saveLocation == null) {
        await _importBoardViaPathPrompt();
        return;
      }

      await widget.controller.importJsonBoard(
        jsonPath: jsonFile.path,
        boardPath: _normalizeMarkdownPath(saveLocation.path),
      );
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
    _newColumnTitleController.clear();
    if (mounted) {
      setState(() {
        _pendingNewColumnId = column.id;
      });
    } else {
      _pendingNewColumnId = column.id;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingNewColumnId != column.id) {
        return;
      }
      _newColumnTitleFocusNode.requestFocus();
    });
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

    _newItemTitleController.clear();
    if (mounted) {
      setState(() {
        _pendingNewItemId = item.id;
      });
    } else {
      _pendingNewItemId = item.id;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingNewItemId != item.id) {
        return;
      }
      _newItemTitleFocusNode.requestFocus();
    });
  }

  void _commitPendingNewColumn() {
    final columnId = _pendingNewColumnId;
    if (columnId == null) {
      return;
    }
    final title = _newColumnTitleController.text.trim();
    widget.controller.updateColumnTitle(columnId, title);
    if (!mounted) {
      _pendingNewColumnId = null;
      _newColumnTitleController.clear();
      return;
    }
    setState(() {
      _pendingNewColumnId = null;
      _newColumnTitleController.clear();
    });
  }

  void _commitPendingNewItem() {
    final itemId = _pendingNewItemId;
    if (itemId == null) {
      return;
    }
    final title = _newItemTitleController.text.trim();
    if (title.isEmpty) {
      widget.controller.deleteItem(itemId);
    } else {
      widget.controller.updateItemTitle(itemId, title);
    }

    if (!mounted) {
      _pendingNewItemId = null;
      _newItemTitleController.clear();
      return;
    }
    setState(() {
      _pendingNewItemId = null;
      _newItemTitleController.clear();
    });
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

  String _baseNameWithoutExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot > 0 ? filename.substring(0, dot) : filename;
  }

  String _normalizeMarkdownPath(String path) {
    if (path.toLowerCase().endsWith('.md')) {
      return path;
    }
    return '$path.md';
  }

  bool _isJsonPath(String path) {
    return path.toLowerCase().endsWith('.json');
  }

  Future<String?> _chooseSaveViaNativeDialog({
    required String suggestedName,
  }) async {
    try {
      final path = await _nativeDialogsChannel
          .invokeMethod<String>('saveBoard', <String, Object?>{
            'suggestedName': suggestedName,
          })
          .timeout(const Duration(seconds: 30), onTimeout: () => null);
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      return path.trim();
    } on PlatformException {
      return null;
    }
  }

  Future<String?> _chooseFileViaNativeDialog({required String method}) async {
    try {
      final path = await _nativeDialogsChannel
          .invokeMethod<String>(method)
          .timeout(const Duration(seconds: 30), onTimeout: () => null);
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      return path.trim();
    } on PlatformException {
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
}

class _DragItemPayload {
  _DragItemPayload({required this.itemId, required this.sourceColumnId});

  final String itemId;
  final String sourceColumnId;
}
