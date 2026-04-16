//
//  ContentView.swift
//  Kanoli
//
//  Created by Krysilis Productions on 4/9/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    // ContentView owns UI-only state: focus, hover, popovers, and modal routing.
    // BoardSessionStore owns the actual board data and file/session actions.
    @Environment(AppCommandRouter.self) private var commandRouter

    @State private var boardSession = BoardSessionStore()
    @State private var persistenceErrorMessage: String?
    @State private var hoveredColumnID: BoardColumn.ID?
    @State private var renamingColumnID: BoardColumn.ID?
    @State private var draggedItemID: BoardItem.ID?
    @State private var hasAttemptedRestore = false
    @State private var editingItemID: BoardItem.ID?
    @State private var newlyCreatedEditingItemID: BoardItem.ID?
    @State private var itemIDToReopenAfterTodoPanel: BoardItem.ID?
    @State private var boardFilter = BoardFilter()
    @State private var isShowingFilterPopover = false
    @State private var isShowingBoardFileChooser = false
    @State private var isFilteredResultsSelected = false
    @State private var isArchiveColumnVisible = false
    @FocusState private var focusedField: FocusTarget?

    private var columns: [BoardColumn] {
        get { boardSession.columns }
        nonmutating set { boardSession.columns = newValue }
    }

    private var activeBoardFileURL: URL? {
        get { boardSession.activeBoardFileURL }
        nonmutating set { boardSession.activeBoardFileURL = newValue }
    }

    private var boardTabs: [BoardTab] {
        get { boardSession.boardTabs }
        nonmutating set { boardSession.boardTabs = newValue }
    }

    private var selectedBoardTabID: BoardTab.ID? {
        get { boardSession.selectedBoardTabID }
        nonmutating set { boardSession.selectedBoardTabID = newValue }
    }

    var body: some View {
        Group {
            if activeBoardFileURL == nil {
                startupView
            } else {
                boardView
                    .onChange(of: columns) { _, _ in
                        persistBoard()
                    }
                    .alert(
                        "Markdown Storage Error",
                        isPresented: persistenceErrorBinding,
                        actions: {
                            Button("OK", role: .cancel) {
                                persistenceErrorMessage = nil
                            }
                        },
                        message: {
                            Text(persistenceErrorMessage ?? "Unknown error")
                        }
                )
            }
        }
        .onAppear {
            restoreLastOpenedBoardIfNeeded()
            handlePendingFileCommand()
        }
        .onChange(of: commandRouter.pendingCommand) { _, _ in
            handlePendingFileCommand()
        }
        .onChange(of: boardFilter) { _, newValue in
            isFilteredResultsSelected = newValue.isActive
        }
        .onChange(of: focusedField) { _, newValue in
            // Column titles are editable only while the rename/add flow is
            // active; focus leaving that field ends the rename mode.
            if case .column(let columnID) = newValue, columnID == renamingColumnID {
                return
            }

            renamingColumnID = nil
        }
        .popover(isPresented: itemEditorBinding, arrowEdge: .trailing) {
            if let item = editingItem {
                ItemEditorView(
                    item: item,
                    columns: columns,
                    boardFileURL: activeBoardFileURL,
                    onTodoPanelWillOpen: { itemIDToReopenAfterTodoPanel = item.id },
                    onTodoPanelDidClose: reopenItemEditorAfterTodoPanelIfNeeded,
                    onOpenItem: { itemID in editingItemID = itemID },
                    onUpdate: { item in boardSession.replaceItem(item) }
                )
                .id(item.id)
            }
        }
    }

    // Startup has no open board yet, so the only available actions are creating
    // or opening a markdown file.
    private var startupView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AuraPalette.background,
                    AuraPalette.backgroundSoft,
                    AuraPalette.selection
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()

            HStack(spacing: 16) {
                Button("Create File") {
                    presentCreatePanel()
                }
                .buttonStyle(StartActionButtonStyle(fillColor: AuraPalette.primary))

                Button("Open File") {
                    presentOpenPanel()
                }
                .buttonStyle(StartActionButtonStyle(fillColor: AuraPalette.secondary))

                Button("Import Trello Board") {
                    presentImportJSONPanel()
                }
                .buttonStyle(StartActionButtonStyle(fillColor: AuraPalette.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Main board shell: tab bar, horizontal column lane, toolbar actions, and
    // the alternate filtered/archive views that reuse the same column renderer.
    private var boardView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                boardTabBar

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        if isFilteredResultsSelected {
                            let resultColumns = filteredResultsColumns()

                            if resultColumns.isEmpty {
                                emptyFilteredResultsView
                            } else {
                                ForEach(resultColumns.indices, id: \.self) { index in
                                    filteredResultColumnView(resultColumns[index])
                                }
                            }
                        } else if isArchiveColumnVisible {
                            Spacer(minLength: 0)

                            ForEach(visibleColumnIndices, id: \.self) { index in
                                columnView(for: index)
                            }

                            Spacer(minLength: 0)
                        } else {
                            ForEach(visibleColumnIndices, id: \.self) { index in
                                columnView(for: index)
                            }

                            Button(action: addColumn) {
                                Text("Add a column")
                                    .font(.headline)
                                    .foregroundStyle(AuraPalette.foreground)
                                    .frame(width: 220, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .addColumnButtonBackground()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .background(boardBackground)
            .navigationTitle("Kanoli")
            .toolbar {
                ToolbarItem {
                    Button {
                        isShowingFilterPopover.toggle()
                    } label: {
                        Label(boardFilter.isActive ? "Filter Active" : "Filter", systemImage: boardFilter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .popover(isPresented: $isShowingFilterPopover) {
                        FilterEditorView(filter: $boardFilter, availableLabels: availableLabelsAcrossOpenTabs())
                    }
                }

                ToolbarItem {
                    if archiveColumnExists {
                        Button {
                            isArchiveColumnVisible.toggle()
                        } label: {
                            Label(isArchiveColumnVisible ? "Hide Archive" : "Show Archive", systemImage: isArchiveColumnVisible ? "archivebox.fill" : "archivebox")
                        }
                    }
                }

                ToolbarItem {
                    Button {
                        closeSelectedBoardTab()
                    } label: {
                        Label("Close Board", systemImage: "xmark.circle")
                    }
                }
            }
        }
        .tint(AuraPalette.secondary)
        .confirmationDialog("Add Board", isPresented: $isShowingBoardFileChooser) {
            Button("Create File") {
                presentCreatePanel()
            }

            Button("Open File") {
                presentOpenPanel()
            }

            Button("Import Trello Board") {
                presentImportJSONPanel()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Create, open, or import a board.")
        }
    }

    private var boardTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(boardTabs) { tab in
                    Button {
                        isFilteredResultsSelected = false
                        selectBoardTab(tab)
                    } label: {
                        Text(tab.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(!isFilteredResultsSelected && selectedBoardTabID == tab.id ? AuraPalette.background : AuraPalette.foreground)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(!isFilteredResultsSelected && selectedBoardTabID == tab.id ? AuraPalette.secondary : AuraPalette.selection)
                            )
                    }
                    .buttonStyle(.plain)
                }

                if boardFilter.isActive {
                    Button {
                        isFilteredResultsSelected = true
                    } label: {
                        Text("Filtered Results")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isFilteredResultsSelected ? AuraPalette.background : AuraPalette.foreground)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isFilteredResultsSelected ? AuraPalette.secondary : AuraPalette.selection)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isShowingBoardFileChooser = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AuraPalette.foreground)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(AuraPalette.primary.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .help("Open another markdown file in a new tab")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(AuraPalette.background.opacity(0.72))
    }

    private var persistenceErrorBinding: Binding<Bool> {
        Binding(
            get: { persistenceErrorMessage != nil },
            set: { shouldShow in
                if !shouldShow {
                    persistenceErrorMessage = nil
                }
            }
        )
    }

    // File commands can come either from the in-window buttons or from the app
    // menu when the main window is closed. Both flows route into BoardSessionStore.
    private func presentOpenPanel() {
#if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.markdownText, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.directoryURL = defaultDocumentsDirectoryURL

        if panel.runModal() == .OK, let url = panel.url {
            do {
                persistenceErrorMessage = try boardSession.loadBoard(from: url)
            } catch {
                persistenceErrorMessage = error.localizedDescription
            }
        }
#endif
    }

    private func presentCreatePanel() {
#if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.markdownText]
        panel.canCreateDirectories = true
        panel.directoryURL = defaultDocumentsDirectoryURL
        panel.nameFieldStringValue = "KanoliBoard.md"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try Data().write(to: url)
                }

                persistenceErrorMessage = try boardSession.loadBoard(from: url)
            } catch {
                persistenceErrorMessage = error.localizedDescription
            }
        }
#endif
    }

    private func presentImportJSONPanel() {
#if os(macOS)
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.directoryURL = defaultDocumentsDirectoryURL

        guard openPanel.runModal() == .OK, let jsonURL = openPanel.url else {
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.markdownText]
        savePanel.canCreateDirectories = true
        savePanel.directoryURL = jsonURL.deletingLastPathComponent()
        savePanel.nameFieldStringValue = jsonURL
            .deletingPathExtension()
            .appendingPathExtension("md")
            .lastPathComponent

        guard savePanel.runModal() == .OK, let boardURL = savePanel.url else {
            return
        }

        do {
            persistenceErrorMessage = nil
            try boardSession.importJSONBoard(from: jsonURL, to: boardURL)
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
#endif
    }

    private func handlePendingFileCommand() {
        guard let command = commandRouter.pendingCommand else {
            return
        }

        commandRouter.pendingCommand = nil

        switch command {
        case .loadFile(let url):
            do {
                persistenceErrorMessage = try boardSession.loadBoard(from: url)
            } catch {
                persistenceErrorMessage = error.localizedDescription
            }
        }
    }

    private func restoreLastOpenedBoardIfNeeded() {
        guard !hasAttemptedRestore else {
            return
        }

        hasAttemptedRestore = true
        persistenceErrorMessage = boardSession.restoreLastOpenedBoardIfNeeded()
    }

    private func selectBoardTab(_ tab: BoardTab) {
        guard selectedBoardTabID != tab.id else {
            return
        }

        persistBoard()

        do {
            persistenceErrorMessage = try boardSession.selectBoardTab(tab)
        } catch {
            persistenceErrorMessage = boardSession.removeUnavailableTab(tab, error: error)
        }
    }

    private func closeSelectedBoardTab() {
        if isFilteredResultsSelected {
            isFilteredResultsSelected = false
            boardFilter = BoardFilter()
            return
        }

        persistBoard()

        do {
            persistenceErrorMessage = try boardSession.closeSelectedBoardTab()
        } catch {
            clearTransientBoardState()
            persistenceErrorMessage = error.localizedDescription
        }
    }

    private func clearTransientBoardState() {
        boardSession.clearOpenBoards()
        hoveredColumnID = nil
        renamingColumnID = nil
        focusedField = nil
        editingItemID = nil
        newlyCreatedEditingItemID = nil
    }

    // Thin UI wrappers around store mutations. These keep focus and hover state
    // in the view while the board structure itself is mutated by BoardSessionStore.
    private func addColumn() {
        let newColumnID = boardSession.addColumn()
        renamingColumnID = newColumnID

        DispatchQueue.main.async {
            focusedField = .column(newColumnID)
        }
    }

    private func addItem(to columnID: BoardColumn.ID) {
        guard let newItemID = boardSession.addItem(to: columnID) else {
            return
        }

        DispatchQueue.main.async {
            focusedField = .item(newItemID)
        }
    }

    private func renameColumn(_ columnID: BoardColumn.ID) {
        renamingColumnID = columnID

        DispatchQueue.main.async {
            focusedField = .column(columnID)
        }
    }

    private func deleteColumn(_ columnID: BoardColumn.ID) {
        boardSession.deleteColumn(columnID)

        if focusedField == .column(columnID) {
            focusedField = nil
        }

        if renamingColumnID == columnID {
            renamingColumnID = nil
        }
    }

    private func submitColumnTitle(columnID: BoardColumn.ID, title: String) {
        renamingColumnID = nil

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            focusedField = nil
            return
        }

        addItem(to: columnID)
    }

    @ViewBuilder
    private func columnView(for index: Int) -> some View {
        let columnID = columns[index].id
        let titleBinding = Binding(
            get: { columns[index].title },
            set: { newValue in
                boardSession.updateColumnTitle(columnID, title: sanitizedSingleLineText(newValue, limit: 25))
            }
        )
        let isMenuVisible = hoveredColumnID == columnID
        let isRenamingColumn = renamingColumnID == columnID

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                if isRenamingColumn {
                    TextField("New column", text: titleBinding)
                        .font(.headline)
                        .textFieldStyle(.plain)
                        .foregroundStyle(AuraPalette.foreground)
                        .focused($focusedField, equals: .column(columnID))
                        .onSubmit {
                            submitColumnTitle(columnID: columnID, title: titleBinding.wrappedValue)
                        }
                } else {
                    Text(columns[index].title.isEmpty ? "New column" : columns[index].title)
                        .font(.headline)
                        .foregroundStyle(AuraPalette.foreground)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Menu {
                    Button("Rename") {
                        renameColumn(columnID)
                    }

                    Button("Delete Column", role: .destructive) {
                        deleteColumn(columnID)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AuraPalette.muted)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .opacity(isMenuVisible ? 1 : 0)
                .allowsHitTesting(isMenuVisible)
                .animation(.easeInOut(duration: 0.12), value: isMenuVisible)
            }

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(filteredItemIDs(for: index), id: \.self) { itemID in
                        itemRowView(itemID: itemID)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .onDrop(
                    of: [.text],
                    delegate: BoardItemDropDelegate(
                        draggedItemID: $draggedItemID,
                        destinationColumnID: columnID,
                        destinationItemID: nil,
                        moveItem: moveDraggedItem
                    )
                )
            }
            .frame(maxHeight: .infinity)

            Button(action: { addItem(to: columnID) }) {
                Text("Add an item")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AuraPalette.background)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .addItemButtonBackground()
            }
            .buttonStyle(.plain)

        }
        .frame(width: 220, alignment: .topLeading)
        .frame(minHeight: 88, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .columnPanelBackground()
        .contentShape(Rectangle())
        .onHover { isHovered in
            hoveredColumnID = isHovered ? columnID : nil
        }
        .onDrop(
            of: [.text],
            delegate: BoardItemDropDelegate(
                draggedItemID: $draggedItemID,
                destinationColumnID: columnID,
                destinationItemID: nil,
                moveItem: moveDraggedItem
            )
        )
    }

    // Cards are lightweight in the board lane. Empty/focused cards use a text
    // field for rapid entry; populated cards open the full editor on click.
    @ViewBuilder
    private func itemRowView(itemID: BoardItem.ID) -> some View {
        if let itemLocation = boardSession.location(of: itemID) {
            let sourceColumnID = columns[itemLocation.columnIndex].id
            let item = columns[itemLocation.columnIndex].items[itemLocation.itemIndex]
            let titleBinding = Binding(
                get: { boardSession.itemTitle(for: itemID) },
                set: { newValue in
                    boardSession.updateItemTitle(itemID, title: sanitizedSingleLineText(newValue, limit: 80))
                }
            )

            HStack(alignment: .top, spacing: 8) {
                if item.title.isEmpty || focusedField == .item(itemID) {
                    TextField("New item", text: titleBinding)
                        .font(.subheadline.weight(.semibold))
                        .textFieldStyle(.plain)
                        .foregroundStyle(AuraPalette.foreground)
                        .focused($focusedField, equals: .item(itemID))
                        .onSubmit {
                            submitItemTitle(itemID: itemID, columnID: sourceColumnID, title: titleBinding.wrappedValue)
                        }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.displayTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AuraPalette.foreground)

                        if !item.metadataSummary.isEmpty {
                            Text(item.metadataSummary)
                                .font(.caption)
                                .foregroundStyle(AuraPalette.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Menu {
                    itemTransferMenu(itemID: itemID, sourceColumnID: sourceColumnID)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AuraPalette.muted)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .cardBackground()
            .contentShape(Rectangle())
            .onTapGesture {
                guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      focusedField != .item(itemID) else {
                    return
                }

                editingItemID = itemID
                newlyCreatedEditingItemID = nil
            }
            .onDrag {
                draggedItemID = itemID
                return NSItemProvider(object: itemID.uuidString as NSString)
            }
            .onDrop(
                of: [.text],
                delegate: BoardItemDropDelegate(
                    draggedItemID: $draggedItemID,
                    destinationColumnID: sourceColumnID,
                    destinationItemID: itemID,
                    moveItem: moveDraggedItem
                )
            )
        }
    }

    private func submitItemTitle(itemID: BoardItem.ID, columnID: BoardColumn.ID, title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            focusedField = nil
            return
        }

        guard boardSession.location(of: itemID) != nil else {
            return
        }

        addItem(to: columnID)
    }

    private var emptyFilteredResultsView: some View {
        Text("No cards match the active filter.")
            .font(.headline)
            .foregroundStyle(AuraPalette.foreground)
            .frame(width: 260, alignment: .leading)
            .padding(16)
            .columnPanelBackground()
    }

    private func filteredResultColumnView(_ column: BoardColumn) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(column.title)
                .font(.headline)
                .foregroundStyle(AuraPalette.foreground)
                .lineLimit(2)

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(column.items) { item in
                        readOnlyItemRowView(item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 260, alignment: .topLeading)
        .frame(minHeight: 88, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .columnPanelBackground()
    }

    private func readOnlyItemRowView(_ item: BoardItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.displayTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AuraPalette.foreground)

            if !item.metadataSummary.isEmpty {
                Text(item.metadataSummary)
                    .font(.caption)
                    .foregroundStyle(AuraPalette.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .cardBackground()
    }

    // Filtered results are assembled as read-only synthetic columns so matching
    // cards can span every open board tab without creating a new markdown file.
    private func filteredResultsColumns() -> [BoardColumn] {
        guard boardFilter.isActive else {
            return []
        }

        return boardSession.openBoardSnapshots().flatMap { snapshot in
            snapshot.columns.compactMap { column in
                let matchingItems = column.items.filter(boardFilter.matches)

                guard !matchingItems.isEmpty else {
                    return nil
                }

                return BoardColumn(title: "\(snapshot.boardTitle) / \(column.title)", items: matchingItems)
            }
        }
    }

    private var visibleColumnIndices: [Int] {
        columns.indices.filter { index in
            isArchiveColumnVisible == isArchiveColumn(columns[index])
        }
    }

    private var archiveColumnExists: Bool {
        columns.contains(where: isArchiveColumn)
    }

    private func isArchiveColumn(_ column: BoardColumn) -> Bool {
        column.title.caseInsensitiveCompare("Archive") == .orderedSame
    }

    private func filteredItemIDs(for columnIndex: Int) -> [BoardItem.ID] {
        guard columns.indices.contains(columnIndex) else {
            return []
        }

        return columns[columnIndex].items.compactMap { item in
            if boardFilter.matches(item) {
                return item.id
            }

            return nil
        }
    }

    @ViewBuilder
    private func itemTransferMenu(itemID: BoardItem.ID, sourceColumnID: BoardColumn.ID) -> some View {
        let moveDestinations = columns.filter { $0.id != sourceColumnID }
        let otherBoardTabs = boardTabs.filter { $0.id != selectedBoardTabID }

        Menu("Move to") {
            if moveDestinations.isEmpty {
                Text("No other columns")
            } else {
                ForEach(moveDestinations) { column in
                    Button(column.menuTitle) {
                        boardSession.moveItem(itemID, to: column.id)
                    }
                }
            }

            if otherBoardTabs.count > 0 {
                Divider()

                Menu("Other Board") {
                    ForEach(otherBoardTabs) { tab in
                        Button(tab.title) {
                            moveItemToBoard(itemID, boardTab: tab)
                        }
                    }
                }
            }
        }

        Menu("Copy to") {
            ForEach(columns) { column in
                Button(column.menuTitle) {
                    boardSession.copyItem(itemID, to: column.id)
                }
            }

            if otherBoardTabs.count > 0 {
                Divider()

                Menu("Other Board") {
                    ForEach(otherBoardTabs) { tab in
                        Button(tab.title) {
                            copyItemToBoard(itemID, boardTab: tab)
                        }
                    }
                }
            }
        }

        Divider()

        Button("Archive") {
            boardSession.archiveItem(itemID)
        }

        Button("Delete Card", role: .destructive) {
            boardSession.removeItem(itemID)
        }
    }

    private func moveDraggedItem(_ itemID: BoardItem.ID, to destinationColumnID: BoardColumn.ID, before destinationItemID: BoardItem.ID?) {
        boardSession.moveDraggedItem(itemID, to: destinationColumnID, before: destinationItemID)
    }

    private func moveItemToBoard(_ itemID: BoardItem.ID, boardTab: BoardTab) {
        do {
            try boardSession.moveItem(itemID, to: boardTab.fileURL)
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }

    private func copyItemToBoard(_ itemID: BoardItem.ID, boardTab: BoardTab) {
        do {
            try boardSession.copyItem(itemID, to: boardTab.fileURL)
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }

    private func availableLabelsAcrossOpenTabs() -> [String] {
        boardSession.availableLabelsAcrossOpenTabs()
    }

    private func persistBoard() {
        do {
            try boardSession.persistBoard()
            persistenceErrorMessage = nil
        } catch {
            persistenceErrorMessage = error.localizedDescription
        }
    }

    private func sanitizedSingleLineText(_ value: String, limit: Int? = nil) -> String {
        let singleLineValue = value
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")

        if let limit {
            return String(singleLineValue.prefix(limit))
        }

        return singleLineValue
    }

    private var defaultDocumentsDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
    }

    private var boardBackground: some View {
        ZStack {
            AuraPalette.background

            LinearGradient(
                colors: [
                    AuraPalette.primary.opacity(0.18),
                    .clear,
                    AuraPalette.secondary.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AuraPalette.primary.opacity(0.14))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -260, y: -180)

            Circle()
                .fill(AuraPalette.secondary.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 260, y: 220)
        }
        .ignoresSafeArea()
    }

    private func clearFocusIfPopulated(_ value: String) {
        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            focusedField = nil
        }
    }

    private var itemEditorBinding: Binding<Bool> {
        Binding(
            get: { editingItemID != nil },
            set: { isPresented in
                if !isPresented {
                    // macOS save panels temporarily dismiss the popover. This
                    // reopens the same item when the todo file panel closes.
                    if let itemIDToReopenAfterTodoPanel {
                        editingItemID = itemIDToReopenAfterTodoPanel
                        newlyCreatedEditingItemID = nil
                        return
                    }

                    editingItemID = nil
                    newlyCreatedEditingItemID = nil
                }
            }
        )
    }

    private func reopenItemEditorAfterTodoPanelIfNeeded() {
        guard let itemID = itemIDToReopenAfterTodoPanel else {
            return
        }

        itemIDToReopenAfterTodoPanel = nil

        DispatchQueue.main.async {
            editingItemID = itemID
        }
    }

    private var editingItem: BoardItem? {
        guard let editingItemID else {
            return nil
        }

        return boardSession.item(for: editingItemID)
    }

}

private struct StartActionButtonStyle: ButtonStyle {
    let fillColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AuraPalette.background)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fillColor.opacity(configuration.isPressed ? 0.78 : 1))
            )
    }
}

private struct AddColumnButtonBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AuraPalette.primary.opacity(0.34),
                            AuraPalette.secondary.opacity(0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

private struct AddItemButtonBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AuraPalette.secondary, AuraPalette.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

private struct ColumnPanelBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AuraPalette.primary.opacity(0.18),
                                AuraPalette.backgroundSoft,
                                AuraPalette.secondary.opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AuraPalette.primary.opacity(0.55),
                                AuraPalette.secondary.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

private struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AuraPalette.primary.opacity(0.22),
                            AuraPalette.selection,
                            AuraPalette.secondary.opacity(0.16)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

private struct NoteBlockBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AuraPalette.selection)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AuraPalette.primary.opacity(0.35), lineWidth: 1)
            )
    }
}

private struct HyperlinkedText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(attributedText)
    }

    private var attributedText: AttributedString {
        var attributedString = AttributedString(text)

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return attributedString
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        for match in matches {
            guard let url = match.url,
                  let textRange = Range(match.range, in: text),
                  let lowerBound = AttributedString.Index(textRange.lowerBound, within: attributedString),
                  let upperBound = AttributedString.Index(textRange.upperBound, within: attributedString) else {
                continue
            }

            attributedString[lowerBound..<upperBound].link = normalizedURL(url)
        }

        return attributedString
    }

    private func normalizedURL(_ url: URL) -> URL {
        guard url.scheme == nil,
              let urlWithScheme = URL(string: "https://\(url.absoluteString)") else {
            return url
        }

        return urlWithScheme
    }
}

struct OpenBoardSnapshot {
    var boardTitle: String
    var columns: [BoardColumn]
}

private struct BoardItemDropDelegate: DropDelegate {
    @Binding var draggedItemID: BoardItem.ID?
    let destinationColumnID: BoardColumn.ID
    let destinationItemID: BoardItem.ID?
    let moveItem: (BoardItem.ID, BoardColumn.ID, BoardItem.ID?) -> Void

    // SwiftUI calls dropEntered repeatedly while hovering over potential targets;
    // moving there gives live reordering feedback instead of waiting for drop.
    func dropEntered(info: DropInfo) {
        guard let draggedItemID else {
            return
        }

        moveItem(draggedItemID, destinationColumnID, destinationItemID)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItemID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// SwiftUI does not ship a simple wrapping stack for label chips, so this layout
// measures child views into rows and places them left-to-right until wrapping.
private struct WrappingHStack: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? .infinity)
        return CGSize(
            width: rows.map(\.width).max() ?? 0,
            height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * lineSpacing
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for element in row.elements {
                subviews[element.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(element.size)
                )
                x += element.size.width + spacing
            }

            y += row.height + lineSpacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextWidth = currentRow.elements.isEmpty ? size.width : currentRow.width + spacing + size.width

            if nextWidth > maxWidth, !currentRow.elements.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
            }

            currentRow.append(RowElement(index: index, size: size), spacing: spacing)
        }

        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private struct Row {
        var elements: [RowElement] = []
        var width: CGFloat = 0
        var height: CGFloat = 0

        mutating func append(_ element: RowElement, spacing: CGFloat) {
            width += elements.isEmpty ? element.size.width : spacing + element.size.width
            height = max(height, element.size.height)
            elements.append(element)
        }
    }

    private struct RowElement {
        let index: Int
        let size: CGSize
    }
}

private extension View {
    func addColumnButtonBackground() -> some View {
        modifier(AddColumnButtonBackground())
    }

    func addItemButtonBackground() -> some View {
        modifier(AddItemButtonBackground())
    }

    func columnPanelBackground() -> some View {
        modifier(ColumnPanelBackground())
    }

    func cardBackground() -> some View {
        modifier(CardBackground())
    }

    func noteBlockBackground() -> some View {
        modifier(NoteBlockBackground())
    }
}

private struct FilterEditorView: View {
    @Binding var filter: BoardFilter
    let availableLabels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Filter Cards")
                .font(.headline)

            Picker("Due date", selection: $filter.dueDateRule) {
                ForEach(BoardFilter.DueDateRule.allCases) { rule in
                    Text(rule.label).tag(rule)
                }
            }

            TextField("Labels, comma-separated", text: labelsTextBinding)
                .textFieldStyle(.roundedBorder)

            if !availableLabels.isEmpty {
                Menu("Existing Labels") {
                    ForEach(availableLabels, id: \.self) { label in
                        Button(label) {
                            addLabel(label)
                        }
                        .disabled(filter.labels.contains { $0.caseInsensitiveCompare(label) == .orderedSame })
                    }
                }
            }

            HStack {
                Spacer()

                Button("Clear") {
                    filter = BoardFilter()
                }
                .disabled(!filter.isActive)
            }
        }
        .padding(18)
        .frame(width: 320)
    }

    private var labelsTextBinding: Binding<String> {
        Binding(
            get: { filter.labels.joined(separator: ", ") },
            set: { filter.labels = normalizedFilterTerms($0) }
        )
    }

    private func normalizedFilterTerms(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { normalizedTag(String($0)) }
            .filter { !$0.isEmpty }
    }

    private func addLabel(_ label: String) {
        let normalizedLabel = normalizedTag(label)

        guard !normalizedLabel.isEmpty,
              !filter.labels.contains(where: { $0.caseInsensitiveCompare(normalizedLabel) == .orderedSame }) else {
            return
        }

        filter.labels.append(normalizedLabel)
    }

    private func normalizedTag(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: "-")
    }
}

private struct ItemEditorView: View {
    // The editor works with local draft state and publishes changes immediately
    // through onUpdate. Notes/checklists are split out so empty in-progress
    // entries can be ignored until committed.
    @AppStorage("todoListBookmarkStore") private var todoListBookmarkStore = Data()

    @State private var draftItem: BoardItem
    @State private var existingNotes: [BoardNote]
    @State private var newNotes: [BoardNote] = []
    @State private var checklists: [BoardChecklist]
    @State private var hoveredChecklistID: BoardChecklist.ID?
    @State private var todoListURL: URL?
    @State private var todoListItems: [TodoListEntry] = []
    @State private var otherBoardTodoListLines: [String] = []
    @State private var newTodoListItemText = ""
    @State private var todoListStatusMessage: String?
    @State private var expandedTodoListItemID: TodoListEntry.ID?
    @State private var isRenamingTitle = false
    @State private var pendingLabelsText = ""
    @State private var selectedLabelFilter: String?
    @State private var rightPanelScrollTargetID: String?
    @FocusState private var isNameFocused: Bool
    @FocusState private var focusedNoteID: BoardNote.ID?
    @FocusState private var focusedChecklistTitleID: BoardChecklist.ID?
    @FocusState private var focusedChecklistItemID: BoardChecklistItem.ID?
    @FocusState private var focusedTodoListItemID: TodoListEntry.ID?
    @FocusState private var isNewTodoListItemFocused: Bool

    let boardFileURL: URL?
    let columns: [BoardColumn]
    let onTodoPanelWillOpen: () -> Void
    let onTodoPanelDidClose: () -> Void
    let onOpenItem: (BoardItem.ID) -> Void
    let onUpdate: (BoardItem) -> Void

    private let priorities = ["", "A", "B", "C", "D"]

    init(
        item: BoardItem,
        columns: [BoardColumn],
        boardFileURL: URL?,
        onTodoPanelWillOpen: @escaping () -> Void,
        onTodoPanelDidClose: @escaping () -> Void,
        onOpenItem: @escaping (BoardItem.ID) -> Void,
        onUpdate: @escaping (BoardItem) -> Void
    ) {
        // Keep the card's scalar metadata in draftItem, but edit notes and
        // checklists in separate arrays so blank draft rows are not persisted.
        var itemWithoutNotes = item
        itemWithoutNotes.notes = []
        itemWithoutNotes.checklists = []
        _draftItem = State(initialValue: itemWithoutNotes)
        _existingNotes = State(initialValue: item.notes)
        _checklists = State(initialValue: item.checklists)
        self.boardFileURL = boardFileURL
        self.columns = columns
        self.onTodoPanelWillOpen = onTodoPanelWillOpen
        self.onTodoPanelDidClose = onTodoPanelDidClose
        self.onOpenItem = onOpenItem
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    if isRenamingTitle {
                        TextField("Name", text: $draftItem.title)
                            .font(.headline)
                            .textFieldStyle(.plain)
                            .focused($isNameFocused)
                            .onSubmit {
                                isNameFocused = false
                                isRenamingTitle = false
                            }
                    } else {
                        Text(draftItem.displayTitle)
                            .font(.headline)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isRenamingTitle = true
                                DispatchQueue.main.async {
                                    isNameFocused = true
                                }
                            }
                    }

                    Picker("Priority", selection: priorityBinding) {
                        Text("None").tag("")
                        ForEach(priorities.dropFirst(), id: \.self) { priority in
                            Text(priority).tag(priority)
                        }
                    }

                    Toggle("Has due date", isOn: hasDueDateBinding)

                    if draftItem.dueDate != nil {
                        DatePicker("Due date", selection: dueDateBinding, displayedComponents: .date)
                    }

                    Divider()

                    Text("Labels")
                        .font(.headline)

                    if !draftItem.labels.isEmpty {
                        WrappingHStack(spacing: 6, lineSpacing: 6) {
                            ForEach(draftItem.labels, id: \.self) { label in
                                labelChip(label)
                            }
                        }
                    }

                    TextField("Comma-separated labels", text: $pendingLabelsText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            commitPendingLabels()
                        }

                    Text("Saved as todo.txt-style +labels in the markdown heading.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)
                }
                .frame(width: 260, alignment: .topLeading)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selectedLabelFilter.map { "+\($0)" } ?? "Notes")
                            .font(.headline)

                        Spacer()

                        if selectedLabelFilter != nil {
                            Button("Back") {
                                selectedLabelFilter = nil
                            }
                        } else {
                            if todoListURL == nil {
                                Button("Add Todo List") {
                                    createOrOpenTodoList()
                                }
                            }

                            Button("Add Checklist") {
                                addChecklist()
                            }

                            Button("Add note") {
                                let note = BoardNote(text: "")
                                newNotes.append(note)
                                rightPanelScrollTargetID = scrollID(forNewNote: note.id)

                                DispatchQueue.main.async {
                                    focusedNoteID = note.id
                                }
                            }
                        }
                    }

                    if let selectedLabelFilter {
                        labelFilterView(for: selectedLabelFilter)
                    } else {
                        // The right panel can grow with notes, checklists, and
                        // todos. A ScrollViewReader keeps newly added content in view.
                        ScrollViewReader { scrollProxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 12) {
                                    if let todoListStatusMessage {
                                        Text(todoListStatusMessage)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    if todoListURL != nil {
                                        todoListEditor
                                            .id(scrollIDForTodoEditor)
                                    }

                                    if todoListURL == nil && checklists.isEmpty && existingNotes.isEmpty && newNotes.isEmpty {
                                        Text("No notes yet.")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(12)
                                            .noteBlockBackground()
                                            .foregroundStyle(.secondary)
                                    }

                                    if !checklists.isEmpty {
                                        ForEach($checklists) { $checklist in
                                            checklistSection(checklist: $checklist)
                                                .id(scrollID(forChecklist: checklist.id))
                                        }
                                    }

                                    ForEach(existingNotes) { note in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Created \(NoteDateFormatter.displayFormatter.string(from: note.createdAt))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            HyperlinkedText(note.text)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(12)
                                        .noteBlockBackground()
                                        .contextMenu {
                                            Button("Delete Note", role: .destructive) {
                                                deleteExistingNote(note.id)
                                            }
                                        }
                                    }

                                    ForEach($newNotes) { $note in
                                        newNoteEditor(note: $note)
                                            .id(scrollID(forNewNote: note.id))
                                    }
                                }
                                .padding(.trailing, 12)
                            }
                            .onChange(of: rightPanelScrollTargetID) { _, targetID in
                                guard let targetID else {
                                    return
                                }

                                DispatchQueue.main.async {
                                    withAnimation {
                                        scrollProxy.scrollTo(targetID, anchor: .bottom)
                                    }
                                    rightPanelScrollTargetID = nil
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)

        }
        .padding(20)
        .frame(minWidth: 680, idealWidth: 760, minHeight: 460, idealHeight: 520)
        .onAppear {
            isNameFocused = false
            loadAttachedTodoListIfNeeded()
        }
        .onChange(of: draftItem) { _, _ in
            publishDraftChanges()
        }
        .onChange(of: newNotes) { _, _ in
            publishDraftChanges()
        }
        .onChange(of: checklists) { _, _ in
            publishDraftChanges()
        }
        .onChange(of: todoListItems) { _, _ in
            saveTodoListItems()
        }
        .onChange(of: isNameFocused) { _, newValue in
            if !newValue {
                isRenamingTitle = false
            }
        }
    }

    // The todo editor presents one external todo.txt file scoped to this card by
    // card:<UUID> tokens. Detailed fields expand under the selected todo row.
    private var todoListEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let todoListURL {
                Text(todoListURL.lastPathComponent)
                    .font(.subheadline.weight(.semibold))
            }

            if todoListItems.isEmpty {
                Text("No todos yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach($todoListItems) { $item in
                todoListRow(item: $item)
                    .id(scrollID(forTodoItem: item.id))

                if expandedTodoListItemID == item.id {
                    todoListDetailEditor(item: $item)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(AuraPalette.muted)

                TextField("Add todo", text: $newTodoListItemText)
                    .textFieldStyle(.plain)
                    .focused($isNewTodoListItemFocused)
                    .onSubmit {
                        addTodoListItem()
                    }
            }
            .padding(.top, 4)
            .id(scrollIDForTodoAddField)
        }
        .padding(12)
        .noteBlockBackground()
        .contextMenu {
            Button("Delete Todo List", role: .destructive) {
                deleteTodoList()
            }
        }
    }

    private func todoListRow(item: Binding<TodoListEntry>) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(item.wrappedValue.priorityLabel)
                .font(.headline.weight(.bold))
                .foregroundStyle(AuraPalette.background)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(priorityColor(for: item.wrappedValue.priority))
                )
                .opacity(item.wrappedValue.priority == nil ? 0.35 : 1)

            Button {
                toggleTodoListItem(item)
            } label: {
                Image(systemName: item.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.wrappedValue.isCompleted ? AuraPalette.secondary : AuraPalette.muted)
            }
            .buttonStyle(.plain)

            TextField("Todo", text: item.text)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .strikethrough(item.wrappedValue.isCompleted)
                .foregroundStyle(item.wrappedValue.isCompleted ? AuraPalette.muted : AuraPalette.foreground)
                .focused($focusedTodoListItemID, equals: item.wrappedValue.id)
                .onSubmit {
                    focusedTodoListItemID = nil
                }

            ForEach(todoMetadataChips(for: item.wrappedValue), id: \.self) { chip in
                Text(chip)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AuraPalette.selection)
                    )
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            expandedTodoListItemID = expandedTodoListItemID == item.wrappedValue.id ? nil : item.wrappedValue.id
        }
        .contextMenu {
            Button("Delete Todo", role: .destructive) {
                deleteTodoListItem(item.wrappedValue.id)
            }
        }
    }

    private func labelChip(_ label: String) -> some View {
        HStack(spacing: 6) {
            Text("+\(label)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .onTapGesture {
                    selectedLabelFilter = label
                }

            Button {
                removeLabel(label)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(AuraPalette.selection)
        )
        .fixedSize(horizontal: true, vertical: false)
    }

    private func labelFilterView(for label: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                let matchingItems = labelFilterResults(for: label)

                if matchingItems.isEmpty {
                    Text("No other items with +\(label).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .noteBlockBackground()
                } else {
                    ForEach(matchingItems) { result in
                        Button {
                            onOpenItem(result.item.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(result.item.displayTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AuraPalette.foreground)

                                HStack(spacing: 6) {
                                    Text(result.columnTitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if !result.item.metadataSummary.isEmpty {
                                        Text(result.item.metadataSummary)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .noteBlockBackground()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.trailing, 12)
        }
        .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
    }

    private func todoListDetailEditor(item: Binding<TodoListEntry>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Todo text", text: item.text)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 10) {
                Picker("Priority", selection: item.priority) {
                    Text("-").tag(String?.none)
                    ForEach(priorities.dropFirst(), id: \.self) { priority in
                        Text(priority).tag(String?.some(priority))
                    }
                }

                Toggle("Due", isOn: Binding(
                    get: { item.wrappedValue.dueDate != nil },
                    set: { item.wrappedValue.dueDate = $0 ? (item.wrappedValue.dueDate ?? Date()) : nil }
                ))

                if item.wrappedValue.dueDate != nil {
                    DatePicker("Due", selection: Binding(
                        get: { item.wrappedValue.dueDate ?? Date() },
                        set: { item.wrappedValue.dueDate = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()
                }

            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AuraPalette.backgroundSoft.opacity(0.9))
        )
    }

    // Checklist entry is optimized for keyboard flow: naming a checklist and
    // pressing Enter creates the first item, and item Enter creates the next row.
    private func checklistSection(checklist: Binding<BoardChecklist>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Checklist name", text: checklist.title)
                    .textFieldStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .focused($focusedChecklistTitleID, equals: checklist.wrappedValue.id)
                    .onSubmit {
                        addChecklistItemAfterTitleSubmit(for: checklist.wrappedValue)
                    }

                Spacer()

                if hoveredChecklistID == checklist.wrappedValue.id {
                    Button("Add item") {
                        addChecklistItem(to: checklist.wrappedValue.id)
                    }
                    .buttonStyle(.borderless)
                }
            }

            ForEach(checklist.items) { checklistItem in
                checklistRow(checklistID: checklist.wrappedValue.id, item: checklistItem)
                    .id(scrollID(forChecklistItem: checklistItem.id))
            }
        }
        .padding(12)
        .noteBlockBackground()
        .onHover { isHovering in
            hoveredChecklistID = isHovering ? checklist.wrappedValue.id : nil
        }
        .contextMenu {
            Button("Delete Checklist", role: .destructive) {
                deleteChecklist(checklist.wrappedValue.id)
            }
        }
    }

    private func checklistRow(checklistID: BoardChecklist.ID, item: Binding<BoardChecklistItem>) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Button {
                item.wrappedValue.isDone.toggle()
            } label: {
                Image(systemName: item.wrappedValue.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.wrappedValue.isDone ? AuraPalette.secondary : AuraPalette.muted)
            }
            .buttonStyle(.plain)

            TextField("Checklist item", text: item.text)
                .textFieldStyle(.plain)
                .strikethrough(item.wrappedValue.isDone)
                .focused($focusedChecklistItemID, equals: item.wrappedValue.id)
                .onSubmit {
                    addChecklistItemAfterSubmit(from: item.wrappedValue, in: checklistID)
                }
        }
        .contextMenu {
            Button("Delete Checklist Item", role: .destructive) {
                deleteChecklistItem(item.wrappedValue.id, from: checklistID)
            }
        }
    }

    private func addChecklist() {
        let checklist = BoardChecklist(title: "Checklist")
        checklists.append(checklist)
        rightPanelScrollTargetID = scrollID(forChecklist: checklist.id)

        DispatchQueue.main.async {
            focusedChecklistTitleID = checklist.id
        }
    }

    private func addChecklistItem(to checklistID: BoardChecklist.ID) {
        let item = BoardChecklistItem(text: "")
        guard let checklistIndex = checklists.firstIndex(where: { $0.id == checklistID }) else {
            return
        }

        checklists[checklistIndex].items.append(item)
        rightPanelScrollTargetID = scrollID(forChecklistItem: item.id)

        DispatchQueue.main.async {
            focusedChecklistItemID = item.id
        }
    }

    private func addChecklistItemAfterTitleSubmit(for checklist: BoardChecklist) {
        focusedChecklistTitleID = nil

        guard !checklist.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        addChecklistItem(to: checklist.id)
    }

    private func addChecklistItemAfterSubmit(from item: BoardChecklistItem, in checklistID: BoardChecklist.ID) {
        guard !item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            focusedChecklistItemID = nil
            DispatchQueue.main.async {
                deleteEmptyChecklistItem(item.id, from: checklistID)
            }
            return
        }

        addChecklistItem(to: checklistID)
    }

    // Unsaved notes use TextEditor so Shift+Enter can insert a newline while
    // plain Enter commits the note into the read-only existingNotes list.
    private func newNoteEditor(note: Binding<BoardNote>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Created \(NoteDateFormatter.displayFormatter.string(from: note.wrappedValue.createdAt))")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: note.text)
                .frame(minHeight: 90)
                .scrollContentBackground(.hidden)
                .focused($focusedNoteID, equals: note.wrappedValue.id)
                .onKeyPress(.return, phases: .down) { keyPress in
                    guard !keyPress.modifiers.contains(.shift) else {
                        return .ignored
                    }

                    commitNewNote(note.wrappedValue)
                    return .handled
                }
        }
        .padding(12)
        .noteBlockBackground()
        .contextMenu {
            Button("Delete Note", role: .destructive) {
                deleteNewNote(note.wrappedValue.id)
            }
        }
    }

    private func deleteExistingNote(_ noteID: BoardNote.ID) {
        existingNotes.removeAll { $0.id == noteID }
    }

    private func deleteNewNote(_ noteID: BoardNote.ID) {
        if focusedNoteID == noteID {
            focusedNoteID = nil
        }

        newNotes.removeAll { $0.id == noteID }
    }

    private func deleteChecklistItem(_ checklistItemID: BoardChecklistItem.ID, from checklistID: BoardChecklist.ID) {
        if focusedChecklistItemID == checklistItemID {
            focusedChecklistItemID = nil
        }

        guard let checklistIndex = checklists.firstIndex(where: { $0.id == checklistID }) else {
            return
        }

        checklists[checklistIndex].items.removeAll { $0.id == checklistItemID }
    }

    private func deleteChecklist(_ checklistID: BoardChecklist.ID) {
        if focusedChecklistTitleID == checklistID {
            focusedChecklistTitleID = nil
        }

        if checklists.first(where: { $0.id == checklistID })?.items.contains(where: { $0.id == focusedChecklistItemID }) == true {
            focusedChecklistItemID = nil
        }

        if hoveredChecklistID == checklistID {
            hoveredChecklistID = nil
        }

        checklists.removeAll { $0.id == checklistID }
    }

    private func deleteEmptyChecklistItem(_ checklistItemID: BoardChecklistItem.ID, from checklistID: BoardChecklist.ID) {
        guard let checklistIndex = checklists.firstIndex(where: { $0.id == checklistID }) else {
            return
        }

        checklists[checklistIndex].items.removeAll {
            $0.id == checklistItemID && $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // Todo list file operations are delegated to TodoBoardStore; the editor only
    // updates UI state, focus, and scroll targets around those calls.
    private func deleteTodoList() {
        guard let todoListURL else {
            publishDraftChanges()
            return
        }

        do {
            try TodoBoardStore.deleteTodoList(at: todoListURL)
            todoListItems = []
            newTodoListItemText = ""
            focusedTodoListItemID = nil
            isNewTodoListItemFocused = false
            self.todoListURL = nil
            otherBoardTodoListLines = []
            todoListStatusMessage = nil
            publishDraftChanges()
        } catch {
            todoListStatusMessage = error.localizedDescription
        }
    }

    private func createOrOpenTodoList() {
        do {
            let todoListURL = try TodoBoardStore.defaultTodoListURL(boardFileURL: boardFileURL)

            do {
                try TodoBoardStore.createTodoListIfNeeded(at: todoListURL)
                try loadTodoListIntoEditor(from: todoListURL)
            } catch {
                try presentTodoListSavePanel(defaultURL: todoListURL)
            }
        } catch {
            todoListStatusMessage = error.localizedDescription
        }
    }

    private func loadTodoListIntoEditor(from todoListURL: URL) throws {
        let loadResult = try TodoBoardStore.loadTodoList(
            from: todoListURL,
            cardID: draftItem.id,
            boardFileURL: boardFileURL,
            bookmarkStoreData: todoListBookmarkStore
        )
        self.todoListURL = loadResult.url
        otherBoardTodoListLines = loadResult.otherLines
        todoListItems = loadResult.currentCardItems
        if let bookmarkStoreData = loadResult.bookmarkStoreData {
            todoListBookmarkStore = bookmarkStoreData
        }
        if let bookmarkWarningMessage = loadResult.bookmarkWarningMessage {
            todoListStatusMessage = "Board todo list: \(todoListURL.lastPathComponent). Bookmark warning: \(bookmarkWarningMessage)"
        } else {
            todoListStatusMessage = "Board todo list: \(todoListURL.lastPathComponent)"
        }
        rightPanelScrollTargetID = scrollIDForTodoEditor
        publishDraftChanges()
    }

    private func saveTodoListItems() {
        guard let todoListURL else {
            return
        }

        do {
            try TodoBoardStore.saveTodoList(
                to: todoListURL,
                currentCardItems: todoListItems,
                otherLines: otherBoardTodoListLines,
                cardID: draftItem.id,
                columnContext: currentColumnContext
            )
            todoListStatusMessage = "Board todo list: \(todoListURL.lastPathComponent)"
        } catch {
            todoListStatusMessage = error.localizedDescription
        }
    }

    private func addTodoListItem() {
        let text = newTodoListItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            isNewTodoListItemFocused = false
            return
        }

        let item = TodoListEntry(line: text, isCompleted: false)
        todoListItems.append(item)
        newTodoListItemText = ""
        rightPanelScrollTargetID = scrollID(forTodoItem: item.id)

        DispatchQueue.main.async {
            isNewTodoListItemFocused = true
        }
    }

    private func toggleTodoListItem(_ item: Binding<TodoListEntry>) {
        if item.wrappedValue.isCompleted {
            item.wrappedValue.isCompleted = false
            item.wrappedValue.completionDate = nil
        } else {
            item.wrappedValue.isCompleted = true
            item.wrappedValue.completionDate = Date()
        }
    }

    private func deleteTodoListItem(_ itemID: TodoListEntry.ID) {
        if focusedTodoListItemID == itemID {
            focusedTodoListItemID = nil
        }

        todoListItems.removeAll { $0.id == itemID }
    }

    private func todoMetadataChips(for item: TodoListEntry) -> [String] {
        var chips: [String] = []

        if let dueDate = item.dueDate {
            chips.append("due: \(TodoDateFormatter.dateFormatter.string(from: dueDate))")
        }

        return chips
    }

    private func priorityColor(for priority: String?) -> Color {
        switch priority {
        case "A":
            return AuraPalette.senary
        case "B":
            return AuraPalette.tertiary
        case "C":
            return AuraPalette.secondary
        case "D":
            return AuraPalette.quinary
        default:
            return AuraPalette.selection
        }
    }

    private func presentTodoListSavePanel(defaultURL: URL) throws {
#if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        panel.directoryURL = defaultURL.deletingLastPathComponent()
        panel.nameFieldStringValue = defaultURL.lastPathComponent

        onTodoPanelWillOpen()
        defer {
            onTodoPanelDidClose()
        }

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        try TodoBoardStore.createTodoListIfNeeded(at: selectedURL)
        try loadTodoListIntoEditor(from: selectedURL)
#else
        throw CocoaError(.fileWriteNoPermission)
#endif
    }

    private func loadAttachedTodoListIfNeeded() {
        guard todoListURL == nil else {
            return
        }

        do {
            let defaultTodoListURL = try TodoBoardStore.defaultTodoListURL(boardFileURL: boardFileURL)
            let todoListPath = TodoBoardStore.todoListPath(for: defaultTodoListURL, boardFileURL: boardFileURL)

            guard let todoListURL = TodoBoardStore.bookmarkedTodoListURL(for: todoListPath, in: todoListBookmarkStore)
                    ?? TodoBoardStore.existingTodoListURL(defaultTodoListURL) else {
                return
            }

            try loadTodoListIntoEditor(from: todoListURL)
        } catch {
            todoListStatusMessage = "Board todo list needs permission."
        }
    }

    private func commitNewNote(_ note: BoardNote) {
        focusedNoteID = nil
        newNotes.removeAll { $0.id == note.id }

        guard !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        existingNotes.append(BoardNote(createdAt: note.createdAt, text: note.text))
    }

    private var priorityBinding: Binding<String> {
        Binding(
            get: { draftItem.priority ?? "" },
            set: { draftItem.priority = $0.isEmpty ? nil : $0 }
        )
    }

    private var hasDueDateBinding: Binding<Bool> {
        Binding(
            get: { draftItem.dueDate != nil },
            set: { hasDueDate in
                draftItem.dueDate = hasDueDate ? (draftItem.dueDate ?? Date()) : nil
            }
        )
    }

    private var dueDateBinding: Binding<Date> {
        Binding(
            get: { draftItem.dueDate ?? Date() },
            set: { draftItem.dueDate = $0 }
        )
    }

    // Publishes only durable editor content. Empty new notes, empty checklists,
    // and empty checklist items are filtered out before updating the board.
    private func publishDraftChanges() {
        var itemToUpdate = draftItem
        let savedNewNotes = newNotes.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let savedChecklists = checklists.compactMap { checklist -> BoardChecklist? in
            let savedItems = checklist.items.filter {
                !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            let title = checklist.title.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !title.isEmpty || !savedItems.isEmpty else {
                return nil
            }

            return BoardChecklist(id: checklist.id, title: title.isEmpty ? "Checklist" : title, items: savedItems)
        }
        itemToUpdate.notes = existingNotes + savedNewNotes
        itemToUpdate.checklists = savedChecklists
        onUpdate(itemToUpdate)
    }

    private var currentColumnContext: String? {
        guard let columnTitle = columns.first(where: { column in
                column.items.contains { $0.id == draftItem.id }
            })?
            .title else {
            return nil
        }

        let context = normalizedTag(columnTitle)
        return context.isEmpty ? nil : context
    }

    private func normalizedTag(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: "-")
    }

    private func commitPendingLabels() {
        let labelsToAdd = pendingLabelsText
            .split(separator: ",")
            .map { normalizedTag(String($0)) }
            .filter { !$0.isEmpty }

        guard !labelsToAdd.isEmpty else {
            pendingLabelsText = ""
            return
        }

        for label in labelsToAdd where !draftItem.labels.contains(label) {
            draftItem.labels.append(label)
        }

        pendingLabelsText = ""
    }

    private func removeLabel(_ label: String) {
        draftItem.labels.removeAll { $0 == label }
    }

    private func labelFilterResults(for label: String) -> [LabelFilterResult] {
        columns.flatMap { column in
            column.items.compactMap { item in
                guard item.id != draftItem.id,
                      item.labels.contains(where: { $0.caseInsensitiveCompare(label) == .orderedSame }) else {
                    return nil
                }

                return LabelFilterResult(columnTitle: column.menuTitle, item: item)
            }
        }
    }

    private var scrollIDForTodoEditor: String {
        "todo-editor"
    }

    private var scrollIDForTodoAddField: String {
        "todo-add-field"
    }

    private func scrollID(forNewNote noteID: BoardNote.ID) -> String {
        "new-note-\(noteID.uuidString)"
    }

    private func scrollID(forChecklist checklistID: BoardChecklist.ID) -> String {
        "checklist-\(checklistID.uuidString)"
    }

    private func scrollID(forChecklistItem checklistItemID: BoardChecklistItem.ID) -> String {
        "checklist-item-\(checklistItemID.uuidString)"
    }

    private func scrollID(forTodoItem todoItemID: TodoListEntry.ID) -> String {
        "todo-item-\(todoItemID.uuidString)"
    }
}

private struct LabelFilterResult: Identifiable {
    var id: BoardItem.ID { item.id }
    let columnTitle: String
    let item: BoardItem
}

// Aura palette adapted from Dalton Menezes: https://github.com/daltonmenezes/aura-theme
private enum AuraPalette {
    static let background = Color(hex: 0x15141B)
    static let foreground = Color(hex: 0xBDBDBD)
    static let muted = Color(hex: 0x6D6D6D)
    static let primary = Color(hex: 0x8464C6)
    static let secondary = Color(hex: 0x54C59F)
    static let tertiary = Color(hex: 0xC7A06F)
    static let quaternary = Color(hex: 0xC17AC8)
    static let quinary = Color(hex: 0x6CB2C7)
    static let senary = Color(hex: 0xC55858)
    static let selection = Color(hex: 0x3D375E, opacity: 0.5)
    static let backgroundSoft = Color(hex: 0x15141B)
    static let primarySoft = Color(hex: 0x8464C6)
}

// A single focus enum keeps SwiftUI from having ambiguous focus bindings
// across multiple text fields.
private enum FocusTarget: Hashable {
    case column(BoardColumn.ID)
    case item(BoardItem.ID)
}

extension UTType {
    static var markdownText: UTType {
        UTType(filenameExtension: "md") ?? .plainText
    }
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

#Preview {
    ContentView()
}
