// Main board workspace UI: app toolbar, board tabs, columns, cards, drag/drop,
// dialogs, import/export prompts, filtering, diagnostics, and recovery flows.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/diagnostics/diagnostics_store.dart';
import '../../../core/files/board_file_access_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/board/todo_board_store.dart';
import '../../../domain/board/board_entities.dart';
import '../application/board_session_controller.dart';
import '../application/card_search.dart';
import 'card_search_palette.dart';
import 'item_editor_sheet.dart';

class BoardWorkspacePage extends StatefulWidget {
  const BoardWorkspacePage({
    super.key,
    required this.environment,
    required this.controller,
    required this.fileAccessService,
  });

  final AppEnvironment environment;
  final BoardSessionController controller;
  final BoardFileAccessService fileAccessService;

  @override
  State<BoardWorkspacePage> createState() => _BoardWorkspacePageState();
}

class _BoardWorkspacePageState extends State<BoardWorkspacePage> {
  final AuraIntensity _auraIntensity = AuraIntensity.subtle;
  final TodoBoardStore _todoBoardStore = TodoBoardStore();
  final FocusNode _shortcutFocusNode = FocusNode(
    debugLabel: 'WorkspaceShortcuts',
  );
  // Flutter maps meta to Command on macOS and the Windows key on Windows.
  static const SingleActivator _cardSearchShortcut = SingleActivator(
    LogicalKeyboardKey.keyP,
    meta: true,
  );
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
  final FocusNode _boardTabRowFocusNode = FocusNode();
  bool _dialogInProgress = false;
  bool _cardSearchPaletteVisible = false;
  bool _missingSessionPromptVisible = false;
  static const String _confirmDeleteColumnPrefKey =
      'kanoli.confirm.deleteColumn.v2';
  static const String _confirmDeleteCardPrefKey =
      'kanoli.confirm.deleteCard.v2';
  static const String _confirmImportOverwritePrefKey =
      'kanoli.confirm.importOverwrite.v2';

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _nativeDialogsChannel.setMethodCallHandler(_handleWindowsMenuAction);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_syncWindowsMenuState());
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_shortcutFocusNode.hasFocus) {
        _shortcutFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _nativeDialogsChannel.setMethodCallHandler(null);
    }
    _shortcutFocusNode.dispose();
    _newColumnTitleController.dispose();
    _newItemTitleController.dispose();
    _newColumnTitleFocusNode.dispose();
    _newItemTitleFocusNode.dispose();
    _boardTabRowFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The workspace listens to the session controller and redraws around the
    // latest active board state.
    final visuals = AppTheme.visuals(_auraIntensity);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? child) {
        _showErrorIfNeeded(context);
        _promptMissingSessionRecoveryIfNeeded(context);

        final scaffold = Scaffold(
          appBar: AppBar(
            title: const Text('Kanoli'),
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
              IconButton(
                tooltip: 'Board Path Options',
                onPressed: widget.controller.hasActiveBoard
                    ? _showActiveBoardPathActions
                    : null,
                icon: const Icon(Icons.more_horiz),
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
        final shortcutScaffold = Focus(
          focusNode: _shortcutFocusNode,
          autofocus: true,
          onKeyEvent: _handleWorkspaceShortcut,
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              _cardSearchShortcut: () => unawaited(_openCardSearchPalette()),
            },
            child: scaffold,
          ),
        );

        if (!(Platform.isMacOS &&
            defaultTargetPlatform == TargetPlatform.macOS)) {
          return shortcutScaffold;
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
                      label: widget.controller.showBoardTabBar
                          ? 'Hide Tab Bar'
                          : 'Show Tab Bar',
                      onSelected: () =>
                          unawaited(_toggleBoardTabBarVisibility()),
                    ),
                  ],
                ),
              ],
            ),
            PlatformMenu(
              label: 'Tools',
              menus: <PlatformMenuItem>[
                PlatformMenuItemGroup(
                  members: <PlatformMenuItem>[
                    PlatformMenuItem(
                      label: 'Privacy Settings',
                      onSelected: () => unawaited(_openPrivacySettings()),
                    ),
                    PlatformMenuItem(
                      label: 'Diagnostics',
                      onSelected: () => unawaited(_openDiagnosticsPanel()),
                    ),
                    PlatformMenuItem(
                      label: 'Reveal Active Board in Finder',
                      onSelected: () => unawaited(_revealActiveBoardInFinder()),
                    ),
                    PlatformMenuItem(
                      label: 'Copy Active Board Path',
                      onSelected: () => unawaited(_copyActiveBoardPath()),
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
                      label: 'Search Cards',
                      shortcut: _cardSearchShortcut,
                      onSelected: () => unawaited(_openCardSearchPalette()),
                    ),
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
                        const SelectAllTextIntent(
                          SelectionChangedCause.keyboard,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          child: shortcutScaffold,
        );
      },
    );
  }

  Widget _startupView(BuildContext context, AuraVisualProfile visuals) {
    // First-run and no-board state: offer the primary file actions only.
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
    // Active board state: tabs, optional filter summary, horizontal columns,
    // and add-column affordance.
    final tabs = widget.controller.boardTabs;
    final selectedTabId = widget.controller.selectedTabId;
    final todoCountsByCardId = _todoCountsByCardId();
    final columns = widget.controller.isFilterActive
        ? widget.controller.filteredResultsColumns()
        : widget.controller.visibleColumns;

    return Column(
      children: <Widget>[
        if (widget.controller.showBoardTabBar && tabs.isNotEmpty)
          Focus(
            focusNode: _boardTabRowFocusNode,
            child: SingleChildScrollView(
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
                      onSelected: (_) =>
                          widget.controller.selectBoardTab(tab.id),
                    ),
                  );
                }).toList(),
              ),
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
                    child: _columnCard(
                      context,
                      column,
                      visuals,
                      todoCountsByCardId,
                    ),
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
    Map<String, TodoBoardItemCounts> todoCountsByCardId,
  ) {
    // Columns own inline rename/new-card state and the drop zones between cards.
    return Container(
      width: 320,
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
                      ? Focus(
                          onKeyEvent: (FocusNode node, KeyEvent event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.escape) {
                              _cancelPendingNewColumn();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _newColumnTitleController,
                            focusNode: _newColumnTitleFocusNode,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'New column',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) =>
                                _commitPendingNewColumnAndCreateFirstItem(),
                            onTapOutside: (_) => _commitPendingNewColumn(),
                          ),
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
                  MenuAnchor(
                    builder:
                        (
                          BuildContext context,
                          MenuController controller,
                          Widget? child,
                        ) {
                          return IconButton(
                            tooltip: 'Column actions',
                            icon: const Icon(Icons.more_horiz, size: 18),
                            onPressed: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                          );
                        },
                    menuChildren: <Widget>[
                      MenuItemButton(
                        onPressed: () => _renameColumn(column),
                        child: const Text('Rename'),
                      ),
                      MenuItemButton(
                        onPressed: () => _deleteColumnWithConfirmation(column),
                        child: const Text('Delete Column'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: (!widget.controller.isFilterActive && column.items.isEmpty)
                  ? Column(
                      children: <Widget>[
                        Expanded(child: _emptyColumnDropTarget(column: column)),
                        const SizedBox(height: 8),
                        _addItemButton(column, visuals),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          if (!widget.controller.isFilterActive)
                            for (
                              var index = 0;
                              index <= column.items.length;
                              index++
                            )
                              Column(
                                children: <Widget>[
                                  _columnDropTarget(
                                    column: column,
                                    destinationItemId:
                                        index < column.items.length
                                        ? column.items[index].id
                                        : null,
                                  ),
                                  if (index < column.items.length)
                                    _itemDropTarget(
                                      column: column,
                                      destinationItemId: column.items[index].id,
                                      child: _itemTile(
                                        item: column.items[index],
                                        sourceColumn: column,
                                        todoCounts:
                                            todoCountsByCardId[column
                                                .items[index]
                                                .id],
                                        visuals: visuals,
                                      ),
                                    ),
                                ],
                              )
                          else
                            ...column.items.map((BoardItem item) {
                              return _itemTile(
                                item: item,
                                sourceColumn: column,
                                todoCounts: todoCountsByCardId[item.id],
                                visuals: visuals,
                              );
                            }),
                          if (!widget.controller.isFilterActive) ...<Widget>[
                            const SizedBox(height: 8),
                            _addItemButton(column, visuals),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addItemButton(BoardColumn column, AuraVisualProfile visuals) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: visuals.addItemButtonGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: AppTheme.background),
        onPressed: () => _addItem(column),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
    );
  }

  Widget _itemTile({
    required BoardItem item,
    required BoardColumn sourceColumn,
    required TodoBoardItemCounts? todoCounts,
    required AuraVisualProfile visuals,
  }) {
    // Card tiles are draggable outside filtered views and open the editor on
    // tap for full details.
    final tile = Container(
      decoration: BoxDecoration(
        gradient: visuals.itemCardGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outline),
      ),
      child: ListTile(
        dense: true,
        title: _pendingNewItemId == item.id
            ? Focus(
                onKeyEvent: (FocusNode node, KeyEvent event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    _cancelPendingNewItem();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _newItemTitleController,
                  focusNode: _newItemTitleFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'New item',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) =>
                      _commitPendingNewItemAndCreateNextItem(sourceColumn),
                  onTapOutside: (_) => _commitPendingNewItem(),
                ),
              )
            : Text(
                item.displayTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
        subtitle: _itemSubtitle(item: item, todoCounts: todoCounts),
        onTap: _pendingNewItemId == item.id
            ? null
            : () => _openItemEditor(item.id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MenuAnchor(
              builder:
                  (
                    BuildContext context,
                    MenuController controller,
                    Widget? child,
                  ) {
                    return IconButton(
                      tooltip: 'Item actions',
                      icon: const Icon(Icons.more_horiz, size: 18),
                      onPressed: _pendingNewItemId == item.id
                          ? null
                          : () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                    );
                  },
              menuChildren: _buildItemActionMenuChildren(
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

    final payload = _DragItemPayload(
      itemId: item.id,
      sourceColumnId: sourceColumn.id,
    );
    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(width: 280, child: tile),
    );
    final useImmediateDesktopDrag =
        Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: useImmediateDesktopDrag
          ? Draggable<_DragItemPayload>(
              data: payload,
              feedback: feedback,
              maxSimultaneousDrags: 1,
              childWhenDragging: Opacity(opacity: 0.35, child: tile),
              child: tile,
            )
          : LongPressDraggable<_DragItemPayload>(
              data: payload,
              feedback: feedback,
              maxSimultaneousDrags: 1,
              childWhenDragging: Opacity(opacity: 0.35, child: tile),
              child: tile,
            ),
    );
  }

  Widget? _itemSubtitle({
    required BoardItem item,
    required TodoBoardItemCounts? todoCounts,
  }) {
    final children = <Widget>[];
    final metadataParts = <String>[
      if (item.priority != null && item.priority!.isNotEmpty)
        '(${item.priority!})',
      ...item.labels.map((String label) => '+$label'),
    ];

    if (metadataParts.isNotEmpty) {
      children.add(Text(metadataParts.join(' ')));
    }

    final dueAndOverdueRow = _itemInfoRow(
      left: item.dueDate != null
          ? _itemCountBadge(
              icon: Icons.schedule_outlined,
              countText: TodoDateFormatter.format(item.dueDate!),
            )
          : null,
      right: item.isOverdue
          ? _itemAlertBadge(
              icon: Icons.notifications_active_outlined,
              text: 'Overdue',
            )
          : null,
      leftFlex: 5,
      rightFlex: 4,
    );

    if (dueAndOverdueRow != null) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 6));
      }
      children.add(dueAndOverdueRow);
    }

    final countsRow = _itemInfoRow(
      left: item.checklistItemCount > 0
          ? _itemCountBadge(
              icon: Icons.checklist_rounded,
              countText:
                  '${item.completedChecklistItemCount}/${item.checklistItemCount}',
            )
          : null,
      right: todoCounts != null && todoCounts.total > 0
          ? _itemCountBadge(
              icon: Icons.check_box_outlined,
              countText: todoCounts.overdue > 0
                  ? '${todoCounts.completed}/${todoCounts.total} · ${todoCounts.overdue} late'
                  : '${todoCounts.completed}/${todoCounts.total}',
              isAlert: todoCounts.overdue > 0,
            )
          : null,
      leftFlex: 4,
      rightFlex: 5,
    );

    if (countsRow != null) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 6));
      }
      children.add(countsRow);
    }

    if (children.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget? _itemInfoRow({
    Widget? left,
    Widget? right,
    int leftFlex = 1,
    int rightFlex = 1,
  }) {
    if (left == null && right == null) {
      return null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: leftFlex, child: left ?? const SizedBox.shrink()),
        const SizedBox(width: 12),
        Expanded(flex: rightFlex, child: right ?? const SizedBox.shrink()),
      ],
    );
  }

  Widget _itemCountBadge({
    required IconData icon,
    required String countText,
    bool isAlert = false,
  }) {
    final color = isAlert ? Theme.of(context).colorScheme.error : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            countText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(color: color, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _itemAlertBadge({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  KeyEventResult _handleWorkspaceShortcut(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyP &&
        HardwareKeyboard.instance.isMetaPressed) {
      unawaited(_openCardSearchPalette());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Map<String, TodoBoardItemCounts> _todoCountsByCardId() {
    final path = widget.controller.activeTodoPath;
    if (path == null || path.trim().isEmpty) {
      return const <String, TodoBoardItemCounts>{};
    }

    try {
      final todoFile = File(path);
      if (!todoFile.existsSync()) {
        return const <String, TodoBoardItemCounts>{};
      }
      return _todoBoardStore.countsByCardId(text: todoFile.readAsStringSync());
    } on FileSystemException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'kanoli',
          context: ErrorDescription('while reading todo counts for card tiles'),
        ),
      );
      return const <String, TodoBoardItemCounts>{};
    }
  }

  Future<void> _openCardSearchPalette() async {
    if (!widget.controller.hasActiveBoard || _cardSearchPaletteVisible) {
      return;
    }

    _cardSearchPaletteVisible = true;
    final snapshots = widget.controller.openBoardSnapshots();
    final activeSnapshot = widget.controller.activeSnapshot();
    if (activeSnapshot == null) {
      _cardSearchPaletteVisible = false;
      return;
    }

    final todoTextByCardId = await _searchableTodoTextByCardId(snapshots);
    if (!mounted) {
      _cardSearchPaletteVisible = false;
      return;
    }

    final openBoards = snapshots.map((OpenBoardSnapshot snapshot) {
      return CardSearchBoard(
        title: snapshot.boardTitle,
        tabId: snapshot.tabId,
        columns: snapshot.columns,
      );
    }).toList();
    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return CardSearchPalette(
            columns: activeSnapshot.columns,
            openBoards: openBoards,
            todoTextByCardId: todoTextByCardId,
            onSelected: (CardSearchResult result) {
              unawaited(_openSearchResult(result));
            },
          );
        },
      );
    } finally {
      _cardSearchPaletteVisible = false;
    }
  }

  Future<Map<String, List<String>>> _searchableTodoTextByCardId(
    List<OpenBoardSnapshot> snapshots,
  ) async {
    final textByCardId = <String, List<String>>{};
    for (final snapshot in snapshots) {
      final path =
          await widget.controller.todoPathForBoard(snapshot.boardPath) ??
          _todoBoardStore.defaultTodoListPath(
            boardFilePath: snapshot.boardPath,
          );
      if (path.trim().isEmpty) {
        continue;
      }
      textByCardId.addAll(_searchableTodoTextAtPath(path));
    }

    return textByCardId;
  }

  Map<String, List<String>> _searchableTodoTextAtPath(String path) {
    try {
      final todoFile = File(path);
      if (!todoFile.existsSync()) {
        return const <String, List<String>>{};
      }
      return _todoBoardStore.searchableTextByCardId(
        text: todoFile.readAsStringSync(),
      );
    } on FileSystemException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'kanoli',
          context: ErrorDescription('while reading todo text for card search'),
        ),
      );
      return const <String, List<String>>{};
    }
  }

  Future<void> _openSearchResult(CardSearchResult result) async {
    final boardTabId = result.boardTabId;
    if (boardTabId != null && boardTabId != widget.controller.selectedTabId) {
      await widget.controller.selectBoardTab(boardTabId);
    }
    await _openItemEditor(result.itemId);
  }

  Widget _columnDropTarget({
    required BoardColumn column,
    required String? destinationItemId,
  }) {
    // Thin drop zones between cards give precise drag targets.
    return DragTarget<_DragItemPayload>(
      onWillAcceptWithDetails: (DragTargetDetails<_DragItemPayload> details) {
        if (details.data.itemId.isEmpty) {
          return false;
        }
        return details.data.itemId != destinationItemId;
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
              height: isActive ? 24 : 12,
              decoration: BoxDecoration(
                color: isActive ? const Color(0x8854C59F) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isActive
                    ? Border.all(color: const Color(0xAA54C59F))
                    : null,
              ),
            );
          },
    );
  }

  Widget _emptyColumnDropTarget({required BoardColumn column}) {
    return DragTarget<_DragItemPayload>(
      onWillAcceptWithDetails: (DragTargetDetails<_DragItemPayload> details) {
        return details.data.itemId.isNotEmpty;
      },
      onAcceptWithDetails: (DragTargetDetails<_DragItemPayload> details) {
        widget.controller.moveItemBefore(
          itemId: details.data.itemId,
          destinationColumnId: column.id,
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
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isActive ? const Color(0x3354C59F) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? const Color(0xCC54C59F)
                      : const Color(0x3354C59F),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Center(
                child: isActive
                    ? Text(
                        'Drop Item Here',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8DE0C8),
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
    );
  }

  Widget _itemDropTarget({
    required BoardColumn column,
    required String destinationItemId,
    required Widget child,
  }) {
    return DragTarget<_DragItemPayload>(
      onWillAcceptWithDetails: (DragTargetDetails<_DragItemPayload> details) {
        return details.data.itemId.isNotEmpty &&
            details.data.itemId != destinationItemId;
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
            return Column(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeInOut,
                  height: isActive ? 8 : 0,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF54C59F),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isActive
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x8854C59F),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeInOut,
                  offset: isActive ? const Offset(0, 0.08) : Offset.zero,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: isActive
                          ? Border.all(color: const Color(0xCC54C59F), width: 2)
                          : null,
                      color: isActive ? const Color(0x2254C59F) : null,
                    ),
                    child: child,
                  ),
                ),
              ],
            );
          },
    );
  }

  Future<void> _openItemEditor(String itemId) async {
    // The editor returns a complete BoardItem draft that replaces the active
    // card through the session controller.
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
          onTodoPathChanged: widget.controller.setActiveTodoPath,
        );
      },
    );
  }

  List<Widget> _buildItemActionMenuChildren({
    required BoardItem item,
    required BoardColumn sourceColumn,
  }) {
    final moveDestinationColumns = widget.controller.columns
        .where((BoardColumn column) => column.id != sourceColumn.id)
        .toList();
    final copyDestinationColumns = widget.controller.columns.toList();
    final destinationTabs = widget.controller.boardTabs
        .where((BoardTabState tab) => tab.id != widget.controller.selectedTabId)
        .toList();

    return <Widget>[
      SubmenuButton(
        menuChildren: <Widget>[
          if (moveDestinationColumns.isEmpty)
            const MenuItemButton(child: Text('No other columns'))
          else
            ...moveDestinationColumns.map(
              (BoardColumn column) => MenuItemButton(
                onPressed: () =>
                    widget.controller.moveItemToColumn(item.id, column.id),
                child: Text(column.menuTitle),
              ),
            ),
          if (destinationTabs.isNotEmpty) ...<Widget>[
            const Divider(height: 1),
            SubmenuButton(
              menuChildren: destinationTabs
                  .map(
                    (BoardTabState tab) => MenuItemButton(
                      onPressed: () =>
                          widget.controller.moveItemToBoard(item.id, tab.path),
                      child: Text(tab.title),
                    ),
                  )
                  .toList(),
              child: const Text('Other Board'),
            ),
          ],
        ],
        child: const Text('Move to'),
      ),
      SubmenuButton(
        menuChildren: <Widget>[
          ...copyDestinationColumns.map(
            (BoardColumn column) => MenuItemButton(
              onPressed: () =>
                  widget.controller.copyItemToColumn(item.id, column.id),
              child: Text(column.menuTitle),
            ),
          ),
          if (destinationTabs.isNotEmpty) ...<Widget>[
            const Divider(height: 1),
            SubmenuButton(
              menuChildren: destinationTabs
                  .map(
                    (BoardTabState tab) => MenuItemButton(
                      onPressed: () =>
                          widget.controller.copyItemToBoard(item.id, tab.path),
                      child: Text(tab.title),
                    ),
                  )
                  .toList(),
              child: const Text('Other Board'),
            ),
          ],
        ],
        child: const Text('Copy to'),
      ),
      const Divider(height: 1),
      MenuItemButton(
        onPressed: () => widget.controller.archiveItem(item.id),
        child: const Text('Archive'),
      ),
      MenuItemButton(
        onPressed: () => _deleteItemWithConfirmation(item),
        child: const Text('Delete Card'),
      ),
    ];
  }

  Future<void> _openBoard() async {
    // Desktop/native paths use platform dialogs first, then fall back to a text
    // prompt when the generic picker is unavailable.
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
        final nativePath = await widget.fileAccessService.pickOpenBoardPath();
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
      final path = await widget.fileAccessService.pickOpenBoardPath();
      if (path == null || path.trim().isEmpty) {
        await _openBoardViaPathPrompt();
        return;
      }
      final normalizedPath = _validatedAbsolutePath(
        path,
        failureEvent: 'openBoardRelativePathRejected',
        snackBarMessage:
            'Open Board requires a full file path. Relative paths are not allowed.',
      );
      if (normalizedPath == null) {
        await _openBoardViaPathPrompt();
        return;
      }
      await widget.controller.openBoard(normalizedPath);
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
    if (Platform.isWindows) {
      await SystemNavigator.pop();
      return;
    }
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

  Future<void> _toggleBoardTabBarVisibility() async {
    final shouldShow = !widget.controller.showBoardTabBar;
    if (shouldShow) {
      await _showWindowViaNative();
    }

    widget.controller.toggleBoardTabBarVisibility();
    await _syncWindowsMenuState();

    if (!shouldShow) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _boardTabRowFocusNode.requestFocus();
    });
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
        final nativePath = await widget.fileAccessService.pickCreateBoardPath(
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
      final savePath = await widget.fileAccessService.pickCreateBoardPath(
        suggestedName: 'KanoliBoard.md',
      );
      if (savePath == null || savePath.trim().isEmpty) {
        await _createBoardViaPathPrompt('KanoliBoard.md');
        return;
      }

      final normalizedPath = _validatedAbsolutePath(
        savePath,
        failureEvent: 'createBoardRelativePathRejected',
        snackBarMessage:
            'Create Board requires a full save path. Relative paths are not allowed.',
      );
      if (normalizedPath == null) {
        await _createBoardViaPathPrompt('KanoliBoard.md');
        return;
      }

      await widget.controller.createBoard(
        _normalizeMarkdownPath(normalizedPath),
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
    // Import starts from a JSON file and saves the converted Markdown board to
    // a user-selected path.
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
        final selection = await widget.fileAccessService
            .pickImportBoardSelection(suggestedBoardName: 'ImportedBoard.md');
        if (selection == null) {
          widget.controller.logger.warning(
            'importBoardUiCancelled',
            <String, Object?>{'source': 'native_open'},
          );
          return;
        }
        final jsonPath = selection.jsonPath;
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
        widget.controller.logger.info(
          'importBoardUiSelectedJson',
          <String, Object?>{'path': jsonPath, 'source': 'native_open'},
        );
        final savePath = selection.boardPath;
        if (File(savePath).existsSync()) {
          final shouldContinue = await _confirmActionWithOptionalPersistence(
            prefKey: _confirmImportOverwritePrefKey,
            title: 'Overwrite Existing Board?',
            message:
                'A file already exists at:\n$savePath\n\n'
                'Import will overwrite its contents.',
            confirmLabel: 'Overwrite',
          );
          if (!shouldContinue) {
            return;
          }
        }
        widget.controller.logger.info(
          'importBoardUiSelectedSavePath',
          <String, Object?>{'path': savePath},
        );
        await widget.controller.importJsonBoard(
          jsonPath: jsonPath,
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
      final selection = await widget.fileAccessService.pickImportBoardSelection(
        suggestedBoardName: 'ImportedBoard.md',
      );
      if (selection == null) {
        await _importBoardViaPathPrompt();
        return;
      }
      final normalizedJsonPath = _validatedAbsolutePath(
        selection.jsonPath,
        failureEvent: 'importBoardJsonRelativePathRejected',
        snackBarMessage:
            'Import Trello JSON requires a full source file path. Relative paths are not allowed.',
      );
      final normalizedBoardPath = _validatedAbsolutePath(
        selection.boardPath,
        failureEvent: 'importBoardSaveRelativePathRejected',
        snackBarMessage:
            'Save Imported Board requires a full destination path. Relative paths are not allowed.',
      );
      if (normalizedJsonPath == null || normalizedBoardPath == null) {
        await _importBoardViaPathPrompt();
        return;
      }
      if (File(normalizedBoardPath).existsSync()) {
        final shouldContinue = await _confirmActionWithOptionalPersistence(
          prefKey: _confirmImportOverwritePrefKey,
          title: 'Overwrite Existing Board?',
          message:
              'A file already exists at:\n$normalizedBoardPath\n\n'
              'Import will overwrite its contents.',
          confirmLabel: 'Overwrite',
        );
        if (!shouldContinue) {
          return;
        }
      }
      await widget.controller.importJsonBoard(
        jsonPath: normalizedJsonPath,
        boardPath: _normalizeMarkdownPath(normalizedBoardPath),
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
    // Filters are applied in the controller so board rendering and result
    // counts share the same state.
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

  Future<void> _openPrivacySettings() async {
    if (!mounted) {
      return;
    }

    var remember = widget.controller.rememberSessionOnLaunch;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Privacy Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SwitchListTile(
                    value: remember,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Remember open boards on launch'),
                    onChanged: (bool value) async {
                      setState(() {
                        remember = value;
                      });
                      await widget.controller.setRememberSessionOnLaunch(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.controller.clearRememberedSessionData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Remembered session data cleared.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Clear Remembered Session Data'),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openDiagnosticsPanel() async {
    // Diagnostics are read-only here except for copying the export text.
    if (!mounted) {
      return;
    }
    final diagnostics = DiagnosticsStore.instance;
    final export = diagnostics.exportText(
      activeBoardPath: widget.controller.activeBoardPath,
      activeTodoPath: widget.controller.activeTodoPath,
    );
    final recentErrors = diagnostics.recentErrors.reversed.take(20).toList();
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Diagnostics'),
          content: SizedBox(
            width: 560,
            height: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Active board: ${widget.controller.activeBoardPath ?? "<none>"}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Active todo: ${widget.controller.activeTodoPath ?? "<none>"}',
                  ),
                  const SizedBox(height: 6),
                  Text('Log file: ${diagnostics.logFilePath ?? "<none>"}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Recent Errors',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (recentErrors.isEmpty)
                    const Text('No recent warnings/errors.')
                  else
                    ...recentErrors.map(
                      (String entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          entry,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: export));
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Diagnostics copied to clipboard.'),
                  ),
                );
              },
              child: const Text('Copy Diagnostics'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addColumn() async {
    // New columns start as inline drafts and are committed on submit or focus
    // loss.
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
    // New cards use the same inline draft pattern as columns.
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

  void _commitPendingNewColumnAndCreateFirstItem() {
    final columnId = _pendingNewColumnId;
    _commitPendingNewColumn();
    if (columnId == null) {
      return;
    }

    final column = widget.controller.columns
        .where((BoardColumn value) => value.id == columnId)
        .firstOrNull;
    if (column == null) {
      return;
    }

    _addItem(column);
  }

  void _cancelPendingNewColumn() {
    final columnId = _pendingNewColumnId;
    if (columnId == null) {
      return;
    }
    widget.controller.deleteColumn(columnId);
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

  void _commitPendingNewItemAndCreateNextItem(BoardColumn column) {
    final pendingId = _pendingNewItemId;
    final pendingTitle = _newItemTitleController.text.trim();
    _commitPendingNewItem();

    // Preserve existing behavior: empty pending item is removed and does not
    // auto-chain into more empty items.
    if (pendingId == null || pendingTitle.isEmpty) {
      return;
    }

    _addItem(column);
  }

  void _cancelPendingNewItem() {
    final itemId = _pendingNewItemId;
    if (itemId == null) {
      return;
    }
    widget.controller.deleteItem(itemId);
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
    // Snackbars are scheduled after build to avoid mutating Scaffold state
    // during widget construction.
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

  void _promptMissingSessionRecoveryIfNeeded(BuildContext context) {
    // Missing remembered boards are handled one at a time so each path has a
    // clear remove-or-replace decision.
    final missingPaths = widget.controller.missingSessionPaths;
    if (!mounted || _missingSessionPromptVisible || missingPaths.isEmpty) {
      return;
    }
    _missingSessionPromptVisible = true;
    final missingPath = missingPaths.first;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _missingSessionPromptVisible = false;
        return;
      }

      final action = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Missing Remembered Board'),
            content: Text(
              'Kanoli could not find this remembered board:\n$missingPath\n\n'
              'Remove it from remembered boards or select a replacement file.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop('later'),
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('remove'),
                child: const Text('Remove'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop('replace'),
                child: const Text('Replace'),
              ),
            ],
          );
        },
      );

      if (action == 'remove') {
        await widget.controller.removeMissingSessionPath(missingPath);
      } else if (action == 'replace') {
        final replacement = await widget.fileAccessService.pickOpenBoardPath();
        if (replacement != null && replacement.trim().isNotEmpty) {
          await widget.controller.replaceMissingSessionPath(
            oldPath: missingPath,
            newPath: replacement.trim(),
          );
        }
      }
      _missingSessionPromptVisible = false;
    });
  }

  Future<void> _showActiveBoardPathActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Reveal in Finder'),
                onTap: () => Navigator.of(context).pop('reveal'),
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy board path'),
                onTap: () => Navigator.of(context).pop('copy'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'reveal') {
      await _revealActiveBoardInFinder();
    } else if (action == 'copy') {
      await _copyActiveBoardPath();
    }
  }

  Future<void> _revealActiveBoardInFinder() async {
    final boardPath = widget.controller.activeBoardPath;
    if (boardPath == null || !(Platform.isMacOS || Platform.isWindows)) {
      return;
    }

    try {
      await _nativeDialogsChannel.invokeMethod<void>(
        'revealInFinder',
        <String, Object?>{'path': boardPath},
      );
    } on PlatformException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reveal file in Finder.')),
      );
    }
  }

  Future<void> _copyActiveBoardPath() async {
    final boardPath = widget.controller.activeBoardPath;
    if (boardPath == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: boardPath));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Board path copied.')));
  }

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String hintText,
    required String submitLabel,
  }) async {
    // Small text prompt used as a fallback when native file pickers cannot
    // provide a path.
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

  Future<void> _syncWindowsMenuState() async {
    if (!Platform.isWindows) {
      return;
    }

    try {
      await _nativeDialogsChannel.invokeMethod<void>(
        'setWindowsMenuState',
        <String, Object?>{'showBoardTabBar': widget.controller.showBoardTabBar},
      );
    } on PlatformException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'kanoli',
          context: ErrorDescription('while syncing Windows menu state'),
        ),
      );
    }
  }

  Future<void> _handleWindowsMenuAction(MethodCall call) async {
    if (!Platform.isWindows || call.method != 'menuAction') {
      throw MissingPluginException();
    }

    final action = call.arguments;
    if (action is! String) {
      throw ArgumentError.value(
        action,
        'arguments',
        'Expected a string action',
      );
    }

    switch (action) {
      case 'createBoard':
        await _createBoard();
        return;
      case 'openBoard':
        await _openBoard();
        return;
      case 'importBoard':
        await _importBoard();
        return;
      case 'closeActiveBoard':
        await _closeSelectedTab();
        return;
      case 'closeWindow':
        await _hideWindowViaNative();
        return;
      case 'toggleBoardTabBar':
        await _toggleBoardTabBarVisibility();
        return;
      case 'openPrivacySettings':
        await _openPrivacySettings();
        return;
      case 'openDiagnostics':
        await _openDiagnosticsPanel();
        return;
      case 'revealActiveBoard':
        await _revealActiveBoardInFinder();
        return;
      case 'copyActiveBoardPath':
        await _copyActiveBoardPath();
        return;
      case 'searchCards':
        await _openCardSearchPalette();
        return;
      case 'undo':
        Actions.invoke(
          context,
          const UndoTextIntent(SelectionChangedCause.keyboard),
        );
        return;
      case 'redo':
        Actions.invoke(
          context,
          const RedoTextIntent(SelectionChangedCause.keyboard),
        );
        return;
      case 'cut':
        Actions.invoke(
          context,
          const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
        );
        return;
      case 'copy':
        Actions.invoke(context, CopySelectionTextIntent.copy);
        return;
      case 'paste':
        Actions.invoke(
          context,
          const PasteTextIntent(SelectionChangedCause.keyboard),
        );
        return;
      case 'selectAll':
        Actions.invoke(
          context,
          const SelectAllTextIntent(SelectionChangedCause.keyboard),
        );
        return;
      default:
        throw UnsupportedError('Unknown Windows menu action: $action');
    }
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

  String _normalizeMarkdownPath(String path) {
    if (path.toLowerCase().endsWith('.md')) {
      return path;
    }
    return '$path.md';
  }

  String? _validatedAbsolutePath(
    String rawPath, {
    required String failureEvent,
    required String snackBarMessage,
  }) {
    final trimmedPath = rawPath.trim();
    if (trimmedPath.isEmpty) {
      return null;
    }

    if (!_isAbsolutePath(trimmedPath)) {
      widget.controller.logger.warning(failureEvent, <String, Object?>{
        'path': trimmedPath,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackBarMessage)));
      }
      return null;
    }

    return File(trimmedPath).absolute.path;
  }

  bool _isAbsolutePath(String path) {
    if (path.isEmpty) {
      return false;
    }

    if (Platform.isWindows) {
      return path.startsWith(r'\\') ||
          RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path);
    }

    return path.startsWith('/');
  }

  bool _isJsonPath(String path) {
    return path.toLowerCase().endsWith('.json');
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
    final normalizedPath = _validatedAbsolutePath(
      selectedPath,
      failureEvent: 'openBoardPromptRelativePathRejected',
      snackBarMessage:
          'Open Board requires a full file path. Relative paths are not allowed.',
    );
    if (normalizedPath == null) {
      return;
    }
    await widget.controller.openBoard(normalizedPath);
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
    final normalizedPath = _validatedAbsolutePath(
      createPath,
      failureEvent: 'createBoardPromptRelativePathRejected',
      snackBarMessage:
          'Create Board requires a full save path. Relative paths are not allowed.',
    );
    if (normalizedPath == null) {
      return;
    }
    await widget.controller.createBoard(_normalizeMarkdownPath(normalizedPath));
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
    final normalizedJsonPath = _validatedAbsolutePath(
      jsonPath,
      failureEvent: 'importBoardJsonPromptRelativePathRejected',
      snackBarMessage:
          'Import Trello JSON requires a full source file path. Relative paths are not allowed.',
    );
    if (normalizedJsonPath == null) {
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
    final normalizedBoardPath = _validatedAbsolutePath(
      boardPath,
      failureEvent: 'importBoardSavePromptRelativePathRejected',
      snackBarMessage:
          'Save Imported Board requires a full destination path. Relative paths are not allowed.',
    );
    if (normalizedBoardPath == null) {
      return;
    }
    if (File(normalizedBoardPath).existsSync()) {
      final shouldContinue = await _confirmActionWithOptionalPersistence(
        prefKey: _confirmImportOverwritePrefKey,
        title: 'Overwrite Existing Board?',
        message:
            'A file already exists at:\n$normalizedBoardPath\n\n'
            'Import will overwrite its contents.',
        confirmLabel: 'Overwrite',
      );
      if (!shouldContinue) {
        return;
      }
    }

    await widget.controller.importJsonBoard(
      jsonPath: normalizedJsonPath,
      boardPath: normalizedBoardPath,
    );
  }

  Future<void> _deleteColumnWithConfirmation(BoardColumn column) async {
    final shouldDelete = await _confirmActionWithOptionalPersistence(
      prefKey: _confirmDeleteColumnPrefKey,
      title: 'Delete Column?',
      message:
          'Delete "${column.menuTitle}" and all cards inside it? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!shouldDelete) {
      return;
    }
    widget.controller.deleteColumn(column.id);
  }

  Future<void> _deleteItemWithConfirmation(BoardItem item) async {
    final shouldDelete = await _confirmActionWithOptionalPersistence(
      prefKey: _confirmDeleteCardPrefKey,
      title: 'Delete Card?',
      message: 'Delete "${item.displayTitle}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!shouldDelete) {
      return;
    }
    widget.controller.deleteItem(item.id);
  }

  Future<bool> _confirmActionWithOptionalPersistence({
    required String prefKey,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    // Destructive confirmations can be disabled per action after the user has
    // seen the warning once.
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return false;
    }
    final shouldPrompt = prefs.getBool(prefKey) ?? true;
    if (!shouldPrompt) {
      return true;
    }

    var dontAskAgain = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(message),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: dontAskAgain,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text("Don't ask again"),
                    onChanged: (bool? value) {
                      setState(() {
                        dontAskAgain = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );

    final didConfirm = confirmed == true;
    if (didConfirm && dontAskAgain) {
      await prefs.setBool(prefKey, false);
    }
    return didConfirm;
  }
}

class _DragItemPayload {
  _DragItemPayload({required this.itemId, required this.sourceColumnId});

  final String itemId;
  final String sourceColumnId;
}
