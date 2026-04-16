import Foundation

struct TodoBoardParseResult {
    var currentCardItems: [TodoListEntry]
    var otherLines: [String]
}

struct TodoBoardFileLoadResult {
    var url: URL
    var currentCardItems: [TodoListEntry]
    var otherLines: [String]
    var bookmarkStoreData: Data?
    var bookmarkWarningMessage: String?
}

// Owns the external todo.txt companion file for a board. It handles sandbox
// bookmarks, file I/O, and conversion between card-scoped todo lines and the
// editor-friendly TodoListEntry model.
struct TodoBoardStore {
    static func defaultTodoListURL(boardFileURL: URL?) throws -> URL {
        guard let boardFileURL else {
            throw CocoaError(.fileNoSuchFile)
        }

        let filename = sanitizedTodoListFilename(from: boardFileURL.deletingPathExtension().lastPathComponent)
        return boardFileURL
            .deletingLastPathComponent()
            .appendingPathComponent(filename)
            .appendingPathExtension("todo.txt")
    }

    static func existingTodoListURL(_ todoListURL: URL) -> URL? {
        FileManager.default.fileExists(atPath: todoListURL.path) ? todoListURL : nil
    }

    static func createTodoListIfNeeded(at todoListURL: URL) throws {
        guard !FileManager.default.fileExists(atPath: todoListURL.path) else {
            return
        }

        try Data().write(to: todoListURL)
    }

    static func loadTodoList(
        from todoListURL: URL,
        cardID: BoardItem.ID,
        boardFileURL: URL?,
        bookmarkStoreData: Data
    ) throws -> TodoBoardFileLoadResult {
        // Security-scoped access is started only around the immediate file read
        // and bookmark refresh; the SwiftUI editor keeps only the URL afterward.
        let didAccessSecurityScope = todoListURL.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                todoListURL.stopAccessingSecurityScopedResource()
            }
        }

        let text = try String(contentsOf: todoListURL, encoding: .utf8)
        let parsedTodoList = parse(text: text, cardID: cardID)
        let bookmarkUpdateResult = refreshedBookmarkStoreData(
            updating: bookmarkStoreData,
            todoListURL: todoListURL,
            boardFileURL: boardFileURL
        )

        return TodoBoardFileLoadResult(
            url: todoListURL,
            currentCardItems: parsedTodoList.currentCardItems,
            otherLines: parsedTodoList.otherLines,
            bookmarkStoreData: bookmarkUpdateResult.data,
            bookmarkWarningMessage: bookmarkUpdateResult.warningMessage
        )
    }

    static func saveTodoList(
        to todoListURL: URL,
        currentCardItems: [TodoListEntry],
        otherLines: [String],
        cardID: BoardItem.ID,
        columnContext: String?
    ) throws {
        // The save path preserves todos for other cards by merging the edited
        // card's lines back into the untouched otherLines captured at load time.
        let didAccessSecurityScope = todoListURL.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                todoListURL.stopAccessingSecurityScopedResource()
            }
        }

        try serialize(
            currentCardItems: currentCardItems,
            otherLines: otherLines,
            cardID: cardID,
            columnContext: columnContext
        )
        .write(to: todoListURL, atomically: true, encoding: .utf8)
    }

    static func deleteTodoList(at todoListURL: URL) throws {
        let didAccessSecurityScope = todoListURL.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScope {
                todoListURL.stopAccessingSecurityScopedResource()
            }
        }

        if FileManager.default.fileExists(atPath: todoListURL.path) {
            try FileManager.default.removeItem(at: todoListURL)
        }
    }

    static func bookmarkedTodoListURL(for todoListPath: String, in bookmarkStoreData: Data) -> URL? {
        guard let bookmarkData = todoListBookmarks(from: bookmarkStoreData)[todoListPath] else {
            return nil
        }

        do {
            var isStale = false
            return try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            return nil
        }
    }

    // Relative paths keep board-adjacent todo files portable for SyncThing,
    // while absolute paths still work when the user chooses another location.
    static func todoListPath(for todoListURL: URL, boardFileURL: URL?) -> String {
        guard let boardFileURL else {
            return todoListURL.path
        }

        let boardDirectoryURL = boardFileURL.deletingLastPathComponent().standardizedFileURL
        let todoListURL = todoListURL.standardizedFileURL

        if todoListURL.deletingLastPathComponent() == boardDirectoryURL {
            return todoListURL.lastPathComponent
        }

        return todoListURL.path
    }

    // Only lines tagged with card:<UUID> are edited in a card window. Untagged
    // and other-card lines are preserved verbatim.
    static func parse(text: String, cardID: BoardItem.ID) -> TodoBoardParseResult {
        var currentCardItems: [TodoListEntry] = []
        var otherLines: [String] = []
        var rawLines = text.components(separatedBy: .newlines)

        if text.hasSuffix("\n") || text.hasSuffix("\r\n") {
            rawLines.removeLast()
        }

        for rawLine in rawLines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !line.isEmpty else {
                otherLines.append(rawLine)
                continue
            }

            let isCompleted = line.hasPrefix("x ")
            let activeLine = isCompleted ? String(line.dropFirst(2)) : line

            guard todoLine(activeLine, matchesCardID: cardID) else {
                otherLines.append(rawLine)
                continue
            }

            currentCardItems.append(TodoListEntry(line: todoLineForCurrentCardEditor(activeLine), isCompleted: isCompleted))
        }

        return TodoBoardParseResult(currentCardItems: currentCardItems, otherLines: otherLines)
    }

    static func serialize(
        currentCardItems: [TodoListEntry],
        otherLines: [String],
        cardID: BoardItem.ID,
        columnContext: String?
    ) -> String {
        let currentCardLines = currentCardItems
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { item in
                serializedBoardTodoLine(for: item, cardID: cardID, columnContext: columnContext)
            }
        let lines = otherLines + currentCardLines

        return lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
    }

    // When saving a card's todo line, strip stale card/context tokens and add
    // the current card ID plus the current column as a todo.txt @context.
    private static func serializedBoardTodoLine(
        for item: TodoListEntry,
        cardID: BoardItem.ID,
        columnContext: String?
    ) -> String {
        var parts = item.todoLine
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.hasPrefix("card:") && !$0.hasPrefix("@") }

        parts.append("card:\(cardID.uuidString)")

        if let columnContext {
            parts.append("@\(columnContext)")
        }

        let line = parts.joined(separator: " ")
        return item.isCompleted ? "x \(line)" : line
    }

    private static func todoLine(_ line: String, matchesCardID cardID: BoardItem.ID) -> Bool {
        line.split(separator: " ").contains { $0 == "card:\(cardID.uuidString)" }
    }

    private static func todoLineForCurrentCardEditor(_ line: String) -> String {
        line.split(separator: " ")
            .map(String.init)
            .filter { !$0.hasPrefix("card:") && !$0.hasPrefix("@") }
            .joined(separator: " ")
    }

    private static func refreshedBookmarkStoreData(updating bookmarkStoreData: Data, todoListURL: URL, boardFileURL: URL?) -> (data: Data?, warningMessage: String?) {
        do {
            return (
                try updatedBookmarkStoreData(updating: bookmarkStoreData, todoListURL: todoListURL, boardFileURL: boardFileURL),
                nil
            )
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    private static func updatedBookmarkStoreData(updating bookmarkStoreData: Data, todoListURL: URL, boardFileURL: URL?) throws -> Data {
        let todoListPath = todoListPath(for: todoListURL, boardFileURL: boardFileURL)
        var bookmarks = todoListBookmarks(from: bookmarkStoreData)
        bookmarks[todoListPath] = try todoListURL.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        return try JSONEncoder().encode(bookmarks)
    }

    private static func todoListBookmarks(from bookmarkStoreData: Data) -> [String: Data] {
        (try? JSONDecoder().decode([String: Data].self, from: bookmarkStoreData)) ?? [:]
    }

    private static func sanitizedTodoListFilename(from title: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
            .union(.newlines)
            .union(.controlCharacters)
        let sanitized = title
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return sanitized.isEmpty ? "Untitled Todo List" : sanitized
    }
}

// Represents the editable portion of one todo.txt line. Completion, priority,
// and due date are parsed into fields while arbitrary task text stays intact.
struct TodoListEntry: Identifiable, Equatable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var completionDate: Date?
    var priority: String?
    var dueDate: Date?

    init(
        id: UUID = UUID(),
        text: String,
        isCompleted: Bool,
        completionDate: Date? = nil,
        priority: String? = nil,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.priority = priority
        self.dueDate = dueDate
    }

    init(id: UUID = UUID(), line: String, isCompleted: Bool) {
        var remainingParts = line.split(separator: " ").map(String.init)
        var completionDate: Date?
        var priority: String?
        var dueDate: Date?

        if isCompleted,
           let firstPart = remainingParts.first,
           let parsedCompletionDate = TodoDateFormatter.dateFormatter.date(from: firstPart) {
            completionDate = parsedCompletionDate
            remainingParts.removeFirst()
        }

        if let firstPart = remainingParts.first,
           firstPart.count == 3,
           firstPart.hasPrefix("("),
           firstPart.hasSuffix(")") {
            priority = String(firstPart.dropFirst().dropLast())
            remainingParts.removeFirst()
        }

        let textParts = remainingParts.compactMap { part -> String? in
            if part.hasPrefix("due:") {
                dueDate = TodoDateFormatter.dateFormatter.date(from: String(part.dropFirst(4)))
                return nil
            }

            return part
        }

        self.init(
            id: id,
            text: textParts.joined(separator: " "),
            isCompleted: isCompleted,
            completionDate: completionDate,
            priority: priority,
            dueDate: dueDate
        )
    }

    var priorityLabel: String {
        priority ?? "-"
    }

    var todoLine: String {
        var parts: [String] = []

        if isCompleted, let completionDate {
            parts.append(TodoDateFormatter.dateFormatter.string(from: completionDate))
        }

        if let priority, !priority.isEmpty {
            parts.append("(\(priority))")
        }

        parts.append(text)

        if let dueDate {
            parts.append("due:\(TodoDateFormatter.dateFormatter.string(from: dueDate))")
        }

        return parts.joined(separator: " ")
    }
}
