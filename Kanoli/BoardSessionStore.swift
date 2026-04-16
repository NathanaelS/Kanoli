import Foundation
import Observation

@Observable
final class BoardSessionStore {
    // This store owns the open board session: the active file, restored tabs,
    // security-scoped bookmarks, and all board-level mutations.
    var columns: [BoardColumn] = []
    var activeBoardFileURL: URL?
    var boardTabs: [BoardTab] = []
    var selectedBoardTabID: BoardTab.ID?

    private let lastOpenedBoardBookmarkKey = "lastOpenedBoardBookmark"
    private let openBoardTabSessionKey = "openBoardTabSession"
    private let userDefaults: UserDefaults
    @ObservationIgnored private var securityScopedBoardFileURLs: [String: URL] = [:]

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    deinit {
        stopAccessingAllBoardFiles()
    }

    func loadBoard(from url: URL) throws -> String? {
        guard beginAccessingSecurityScopedResourceIfNeeded(for: url) else {
            throw CocoaError(.fileReadNoPermission)
        }

        do {
            try validateBoardFileExists(at: url)

            let loadResult = MarkdownBoardStore.loadBoard(from: url)
            columns = loadResult.columns
            activeBoardFileURL = url
            upsertBoardTab(for: url)
            persistBookmark(for: url)
            persistTabSession()

            return loadResult.errorMessage
        } catch {
            if !isOpenBoardURL(url) {
                stopAccessingBoardFile(for: url)
            }

            throw error
        }
    }

    // Restore the full tab session first. The older single-board bookmark is a
    // fallback for users who had a file open before tabs were introduced.
    func restoreLastOpenedBoardIfNeeded() -> String? {
        if restoreOpenBoardTabSession() {
            return nil
        }

        guard !lastOpenedBoardBookmark.isEmpty else {
            return nil
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: lastOpenedBoardBookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                persistBookmark(for: url)
            }

            return try loadBoard(from: url)
        } catch {
            clearOpenBoards()
            return error.localizedDescription
        }
    }

    func selectBoardTab(_ tab: BoardTab) throws -> String? {
        guard selectedBoardTabID != tab.id else {
            return nil
        }

        return try loadBoard(from: tab.fileURL)
    }

    func closeSelectedBoardTab() throws -> String? {
        guard let selectedBoardTabID else {
            clearOpenBoards()
            return nil
        }

        let closingTab = boardTabs.first { $0.id == selectedBoardTabID }
        boardTabs.removeAll { $0.id == selectedBoardTabID }
        if let closingTab {
            stopAccessingBoardFileIfNoOpenTabNeedsIt(closingTab.fileURL)
        }

        guard let nextTab = boardTabs.first else {
            clearOpenBoards()
            return nil
        }

        do {
            let errorMessage = try loadBoard(from: nextTab.fileURL)
            persistTabSession()
            return errorMessage
        } catch {
            return removeUnavailableTab(nextTab, error: error)
        }
    }

    func removeUnavailableTab(_ tab: BoardTab, error: Error) -> String? {
        boardTabs.removeAll { $0.id == tab.id }
        stopAccessingBoardFileIfNoOpenTabNeedsIt(tab.fileURL)
        persistTabSession()

        guard let nextTab = boardTabs.first else {
            clearOpenBoards()
            return error.localizedDescription
        }

        do {
            return try loadBoard(from: nextTab.fileURL)
        } catch {
            clearOpenBoards()
            return error.localizedDescription
        }
    }

    func clearOpenBoards() {
        stopAccessingAllBoardFiles()
        lastOpenedBoardBookmark = Data()
        openBoardTabSession = Data()
        activeBoardFileURL = nil
        columns = []
        boardTabs = []
        selectedBoardTabID = nil
    }

    func persistBoard() throws {
        guard let activeBoardFileURL else {
            return
        }

        try MarkdownBoardStore.save(columns: columns, to: activeBoardFileURL)
    }

    func appendItem(_ item: BoardItem, to boardURL: URL) throws {
        guard beginAccessingSecurityScopedResourceIfNeeded(for: boardURL) else {
            throw CocoaError(.fileReadNoPermission)
        }

        try validateBoardFileExists(at: boardURL)

        var loadResult = MarkdownBoardStore.loadBoard(from: boardURL)

        if loadResult.columns.isEmpty {
            loadResult.columns = [BoardColumn(title: "Inbox")]
        }

        loadResult.columns[0].items.append(item)
        try MarkdownBoardStore.save(columns: loadResult.columns, to: boardURL)
    }

    // Board mutation API used by ContentView. Keeping these operations here
    // prevents SwiftUI view code from knowing how columns/items are indexed.
    @discardableResult
    func addColumn() -> BoardColumn.ID {
        let newColumn = BoardColumn(title: "")
        columns.append(newColumn)
        return newColumn.id
    }

    func updateColumnTitle(_ columnID: BoardColumn.ID, title: String) {
        guard let columnIndex = columns.firstIndex(where: { $0.id == columnID }) else {
            return
        }

        columns[columnIndex].title = title
    }

    func deleteColumn(_ columnID: BoardColumn.ID) {
        columns.removeAll { $0.id == columnID }
    }

    @discardableResult
    func addItem(to columnID: BoardColumn.ID) -> BoardItem.ID? {
        guard let columnIndex = columns.firstIndex(where: { $0.id == columnID }) else {
            return nil
        }

        let newItem = BoardItem(title: "")
        columns[columnIndex].items.append(newItem)
        return newItem.id
    }

    func itemTitle(for itemID: BoardItem.ID) -> String {
        item(for: itemID)?.title ?? ""
    }

    func updateItemTitle(_ itemID: BoardItem.ID, title: String) {
        guard let itemLocation = location(of: itemID) else {
            return
        }

        columns[itemLocation.columnIndex].items[itemLocation.itemIndex].title = title
    }

    func location(of itemID: BoardItem.ID) -> (columnIndex: Int, itemIndex: Int)? {
        for columnIndex in columns.indices {
            if let itemIndex = columns[columnIndex].items.firstIndex(where: { $0.id == itemID }) {
                return (columnIndex, itemIndex)
            }
        }

        return nil
    }

    func item(for itemID: BoardItem.ID) -> BoardItem? {
        guard let itemLocation = location(of: itemID) else {
            return nil
        }

        return columns[itemLocation.columnIndex].items[itemLocation.itemIndex]
    }

    func replaceItem(_ item: BoardItem) {
        guard let itemLocation = location(of: item.id) else {
            return
        }

        columns[itemLocation.columnIndex].items[itemLocation.itemIndex] = item
    }

    func removeItem(_ itemID: BoardItem.ID) {
        guard let itemLocation = location(of: itemID) else {
            return
        }

        columns[itemLocation.columnIndex].items.remove(at: itemLocation.itemIndex)
    }

    func moveItem(_ itemID: BoardItem.ID, to destinationColumnID: BoardColumn.ID) {
        guard let sourceLocation = location(of: itemID),
              columns[sourceLocation.columnIndex].id != destinationColumnID,
              let destinationColumnIndex = columns.firstIndex(where: { $0.id == destinationColumnID }) else {
            return
        }

        let item = columns[sourceLocation.columnIndex].items.remove(at: sourceLocation.itemIndex)
        columns[destinationColumnIndex].items.append(item)
    }

    func moveDraggedItem(_ itemID: BoardItem.ID, to destinationColumnID: BoardColumn.ID, before destinationItemID: BoardItem.ID?) {
        guard let sourceLocation = location(of: itemID),
              let destinationColumnIndex = columns.firstIndex(where: { $0.id == destinationColumnID }) else {
            return
        }

        if destinationItemID == itemID {
            return
        }

        let destinationOriginalIndex = destinationItemID.flatMap { destinationItemID in
            columns[destinationColumnIndex].items.firstIndex { $0.id == destinationItemID }
        }
        let item = columns[sourceLocation.columnIndex].items.remove(at: sourceLocation.itemIndex)
        let insertionIndex: Int

        if let destinationItemID,
           let destinationItemIndex = columns[destinationColumnIndex].items.firstIndex(where: { $0.id == destinationItemID }) {
            let isMovingDownWithinColumn = sourceLocation.columnIndex == destinationColumnIndex
                && destinationOriginalIndex.map { sourceLocation.itemIndex < $0 } == true
            insertionIndex = isMovingDownWithinColumn
                ? min(destinationItemIndex + 1, columns[destinationColumnIndex].items.endIndex)
                : destinationItemIndex
        } else {
            insertionIndex = columns[destinationColumnIndex].items.endIndex
        }

        columns[destinationColumnIndex].items.insert(item, at: insertionIndex)
    }

    func copyItem(_ itemID: BoardItem.ID, to destinationColumnID: BoardColumn.ID) {
        guard let item = item(for: itemID),
              let destinationColumnIndex = columns.firstIndex(where: { $0.id == destinationColumnID }) else {
            return
        }

        columns[destinationColumnIndex].items.append(item.duplicatedWithNewIDs())
    }

    // Cross-board transfers load the destination markdown file, append to its
    // Inbox column, and save that file without switching the active tab.
    func moveItem(_ itemID: BoardItem.ID, to boardURL: URL) throws {
        guard let item = item(for: itemID) else {
            return
        }

        try appendItem(item, to: boardURL)
        removeItem(itemID)
    }

    func copyItem(_ itemID: BoardItem.ID, to boardURL: URL) throws {
        guard let item = item(for: itemID) else {
            return
        }

        try appendItem(item.duplicatedWithNewIDs(), to: boardURL)
    }

    func archiveItem(_ itemID: BoardItem.ID) {
        let archiveColumnID: BoardColumn.ID

        if let existingArchiveColumn = columns.first(where: { $0.title.caseInsensitiveCompare("Archive") == .orderedSame }) {
            archiveColumnID = existingArchiveColumn.id
        } else {
            let archiveColumn = BoardColumn(title: "Archive")
            columns.append(archiveColumn)
            archiveColumnID = archiveColumn.id
        }

        moveItem(itemID, to: archiveColumnID)
    }

    // Filtered result views need read-only snapshots from every open tab. The
    // active board uses in-memory columns; inactive tabs are loaded from disk.
    func openBoardSnapshots() -> [OpenBoardSnapshot] {
        boardTabs.compactMap { tab in
            if tab.id == selectedBoardTabID {
                return OpenBoardSnapshot(boardTitle: tab.title, columns: columns)
            }

            guard beginAccessingSecurityScopedResourceIfNeeded(for: tab.fileURL) else {
                return nil
            }

            let loadResult = MarkdownBoardStore.loadBoard(from: tab.fileURL)
            return OpenBoardSnapshot(boardTitle: tab.title, columns: loadResult.columns)
        }
    }

    func availableLabelsAcrossOpenTabs() -> [String] {
        var labels = Set(columns.flatMap { column in
            column.items.flatMap { $0.labels }
        })

        for tab in boardTabs where tab.id != selectedBoardTabID {
            guard beginAccessingSecurityScopedResourceIfNeeded(for: tab.fileURL) else {
                continue
            }

            let loadResult = MarkdownBoardStore.loadBoard(from: tab.fileURL)
            labels.formUnion(loadResult.columns.flatMap { column in
                column.items.flatMap { $0.labels }
            })
        }

        return labels.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    @discardableResult
    func beginAccessingSecurityScopedResourceIfNeeded(for url: URL) -> Bool {
        let normalizedPath = url.standardizedFileURL.path

        if securityScopedBoardFileURLs[normalizedPath] != nil {
            return true
        }

        if url.startAccessingSecurityScopedResource() {
            securityScopedBoardFileURLs[normalizedPath] = url
            return true
        }

        return FileManager.default.isReadableFile(atPath: url.path)
    }

    // Rehydrates persisted tabs by resolving their bookmarks and dropping any
    // files that are missing, unreadable, or no longer grant permission.
    private func restoreOpenBoardTabSession() -> Bool {
        guard !openBoardTabSession.isEmpty,
              let session = try? JSONDecoder().decode(BoardTabSession.self, from: openBoardTabSession) else {
            return false
        }

        var restoredTabs: [BoardTab] = []

        for tab in session.tabs {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: tab.bookmarkData,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                guard beginAccessingSecurityScopedResourceIfNeeded(for: url) else {
                    continue
                }

                do {
                    try validateBoardFileExists(at: url)
                } catch {
                    stopAccessingBoardFileIfNoOpenTabNeedsIt(url)
                    throw error
                }

                if isStale {
                    persistBookmark(for: url)
                }

                restoredTabs.append(BoardTab(fileURL: url))
            } catch {
                continue
            }
        }

        guard !restoredTabs.isEmpty else {
            openBoardTabSession = Data()
            return false
        }

        boardTabs = restoredTabs
        let tabToLoad = restoredTabs.first { $0.normalizedPath == session.selectedTabPath } ?? restoredTabs[0]

        do {
            _ = try loadBoard(from: tabToLoad.fileURL)
            return true
        } catch {
            _ = removeUnavailableTab(tabToLoad, error: error)
            return !boardTabs.isEmpty
        }
    }

    private func persistBookmark(for url: URL) {
        lastOpenedBoardBookmark = (try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )) ?? lastOpenedBoardBookmark
    }

    private func upsertBoardTab(for url: URL) {
        let normalizedPath = url.standardizedFileURL.path

        if let existingTab = boardTabs.first(where: { $0.normalizedPath == normalizedPath }) {
            selectedBoardTabID = existingTab.id
            persistTabSession()
            return
        }

        let newTab = BoardTab(fileURL: url)
        boardTabs.append(newTab)
        selectedBoardTabID = newTab.id
    }

    private func isOpenBoardURL(_ url: URL) -> Bool {
        let normalizedPath = url.standardizedFileURL.path
        return boardTabs.contains { $0.normalizedPath == normalizedPath }
    }

    private func stopAccessingBoardFileIfNoOpenTabNeedsIt(_ url: URL) {
        if !isOpenBoardURL(url) {
            stopAccessingBoardFile(for: url)
        }
    }

    private func stopAccessingBoardFile(for url: URL) {
        let normalizedPath = url.standardizedFileURL.path
        guard let scopedURL = securityScopedBoardFileURLs.removeValue(forKey: normalizedPath) else {
            return
        }

        scopedURL.stopAccessingSecurityScopedResource()
    }

    private func stopAccessingAllBoardFiles() {
        for url in securityScopedBoardFileURLs.values {
            url.stopAccessingSecurityScopedResource()
        }

        securityScopedBoardFileURLs.removeAll()
    }

    // Store one bookmark per open tab plus the selected tab path. Paths are used
    // only for matching after bookmark resolution recreates fresh URL instances.
    private func persistTabSession() {
        let tabs = boardTabs.compactMap { tab -> BoardTabSession.Tab? in
            guard let bookmarkData = try? tab.fileURL.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) else {
                return nil
            }

            return BoardTabSession.Tab(bookmarkData: bookmarkData)
        }

        guard !tabs.isEmpty else {
            openBoardTabSession = Data()
            return
        }

        let selectedTabPath = boardTabs.first { $0.id == selectedBoardTabID }?.normalizedPath
            ?? activeBoardFileURL?.standardizedFileURL.path
        let session = BoardTabSession(tabs: tabs, selectedTabPath: selectedTabPath)
        openBoardTabSession = (try? JSONEncoder().encode(session)) ?? Data()
    }

    private func validateBoardFileExists(at url: URL) throws {
        let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey])

        guard FileManager.default.isReadableFile(atPath: url.path),
              resourceValues.isRegularFile == true else {
            throw CocoaError(.fileNoSuchFile)
        }
    }

    private var lastOpenedBoardBookmark: Data {
        get { userDefaults.data(forKey: lastOpenedBoardBookmarkKey) ?? Data() }
        set { userDefaults.set(newValue, forKey: lastOpenedBoardBookmarkKey) }
    }

    private var openBoardTabSession: Data {
        get { userDefaults.data(forKey: openBoardTabSessionKey) ?? Data() }
        set { userDefaults.set(newValue, forKey: openBoardTabSessionKey) }
    }
}
