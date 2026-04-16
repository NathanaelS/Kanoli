import Foundation

// Translates between the editable Kanoli model and the plain markdown file on
// disk. The format stays intentionally readable: columns are H1 headings, cards
// are H2 headings, and card details are quoted metadata lines.
struct MarkdownBoardStore {
    static func loadBoard(from fileURL: URL) -> BoardLoadResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return BoardLoadResult(columns: [], errorMessage: CocoaError(.fileNoSuchFile).localizedDescription)
        }

        do {
            let markdown = try String(contentsOf: fileURL, encoding: .utf8)
            return BoardLoadResult(columns: parse(markdown: markdown), errorMessage: nil)
        } catch {
            return BoardLoadResult(columns: [], errorMessage: error.localizedDescription)
        }
    }

    static func save(columns: [BoardColumn], to fileURL: URL) throws {
        let markdown = serialize(columns: columns)
        let directoryURL = fileURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private static func parse(markdown: String) -> [BoardColumn] {
        // Parsing is single-pass and stateful because notes/checklists belong to
        // the most recent item heading under the most recent column heading.
        var parsedColumns: [BoardColumn] = []
        var currentColumn: BoardColumn?
        var currentItemID: BoardItem.ID?
        var currentChecklistID: BoardChecklist.ID?

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if let itemTitle = headerContent(in: line, level: 2) {
                guard currentColumn != nil else {
                    continue
                }

                let item = parseTodoItem(from: itemTitle)
                currentColumn?.items.append(item)
                currentItemID = item.id
                currentChecklistID = nil
                continue
            }

            if let columnTitle = headerContent(in: line, level: 1) {
                if let currentColumn {
                    parsedColumns.append(currentColumn)
                }

                currentColumn = BoardColumn(title: columnTitle)
                currentItemID = nil
                currentChecklistID = nil
                continue
            }

            if let currentItemID, let noteLine = noteContent(in: line) {
                guard let itemIndex = currentColumn?.items.firstIndex(where: { $0.id == currentItemID }) else {
                    continue
                }

                if let checklist = parseChecklist(from: noteLine) {
                    currentColumn?.items[itemIndex].checklists.append(checklist)
                    currentChecklistID = checklist.id
                } else if let checklistItem = parseChecklistItem(from: noteLine) {
                    appendChecklistItem(checklistItem, to: &currentColumn, itemIndex: itemIndex, checklistID: &currentChecklistID)
                } else if let checklistItem = parseLegacyChecklistItem(from: noteLine) {
                    appendLegacyChecklistItem(checklistItem, to: &currentColumn, itemIndex: itemIndex, checklistID: &currentChecklistID)
                } else {
                    currentColumn?.items[itemIndex].notes.append(parseNote(from: noteLine))
                }
            }
        }

        if let currentColumn {
            parsedColumns.append(currentColumn)
        }

        return parsedColumns
    }

    private static func serialize(columns: [BoardColumn]) -> String {
        // Serialization mirrors parsing and omits empty note/checklist content
        // so the markdown file remains compact and hand-editable.
        columns.map { column in
            let lines = ["# \(column.title)"] + column.items.flatMap { item in
                var itemLines = ["## \(todoLine(for: item))"]

                for note in item.notes where !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let createdAt = NoteDateFormatter.markdownFormatter.string(from: note.createdAt)
                    itemLines += note.text
                        .components(separatedBy: .newlines)
                        .map { "> note:\(createdAt) \($0)" }
                }

                for checklist in item.checklists where !checklist.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || checklist.items.contains(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    itemLines.append("> checklist:\(checklist.id.uuidString) \(checklist.title)")

                    for checklistItem in checklist.items where !checklistItem.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let marker = checklistItem.isDone ? "x" : " "
                        itemLines.append("> checklist-item:\(checklist.id.uuidString):[\(marker)] \(checklistItem.text)")
                    }
                }

                return itemLines
            }
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    private static func headerContent(in line: String, level: Int) -> String? {
        let headerPrefix = String(repeating: "#", count: level)

        guard line == headerPrefix || line.hasPrefix("\(headerPrefix) ") else {
            return nil
        }

        return String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
    }

    // Card metadata is encoded inline on the H2 line using todo.txt-inspired
    // tokens: priority, +labels, due:date, and a stable id:UUID.
    private static func parseTodoItem(from line: String) -> BoardItem {
        var titleParts: [String] = []
        var priority: String?
        var dueDate: Date?
        var labels: [String] = []
        var id = UUID()

        let parts = line.split(separator: " ").map(String.init)

        for (index, part) in parts.enumerated() {
            if index == 0, part.count == 3, part.hasPrefix("("), part.hasSuffix(")") {
                priority = String(part.dropFirst().dropLast())
            } else if part.hasPrefix("+") {
                labels.append(String(part.dropFirst()))
            } else if part.hasPrefix("due:") {
                let value = String(part.dropFirst(4))
                dueDate = TodoDateFormatter.dateFormatter.date(from: value)
            } else if part.hasPrefix("id:") {
                let value = String(part.dropFirst(3))
                id = UUID(uuidString: value) ?? id
            } else if part.hasPrefix("todo:") {
                continue
            } else {
                titleParts.append(part)
            }
        }

        return BoardItem(
            id: id,
            title: titleParts.joined(separator: " "),
            notes: [],
            checklists: [],
            dueDate: dueDate,
            priority: priority,
            labels: labels
        )
    }

    private static func todoLine(for item: BoardItem) -> String {
        var parts: [String] = []

        if let priority = item.priority, !priority.isEmpty {
            parts.append("(\(priority))")
        }

        parts.append(item.title)
        parts += item.labels
            .map(normalizedTag)
            .filter { !$0.isEmpty }
            .map { "+\($0)" }

        if let dueDate = item.dueDate {
            parts.append("due:\(TodoDateFormatter.dateFormatter.string(from: dueDate))")
        }

        parts.append("id:\(item.id.uuidString)")

        return parts.joined(separator: " ")
    }

    nonisolated private static func normalizedTag(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: "-")
    }

    // Notes and checklist rows are stored as markdown blockquotes under the
    // current card so the file remains readable outside the GUI.
    private static func noteContent(in line: String) -> String? {
        guard line.hasPrefix(">") else {
            return nil
        }

        return String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
    }

    private static func parseNote(from line: String) -> BoardNote {
        guard line.hasPrefix("note:") else {
            return BoardNote(text: line)
        }

        let remainder = String(line.dropFirst(5))
        let parts = remainder.split(separator: " ", maxSplits: 1).map(String.init)

        guard let datePart = parts.first,
              let createdAt = NoteDateFormatter.markdownFormatter.date(from: datePart) else {
            return BoardNote(text: line)
        }

        let text = parts.count > 1 ? parts[1] : ""
        return BoardNote(createdAt: createdAt, text: text)
    }

    private static func parseChecklist(from line: String) -> BoardChecklist? {
        guard line.hasPrefix("checklist:") else {
            return nil
        }

        let remainder = String(line.dropFirst(10))
        let parts = remainder.split(separator: " ", maxSplits: 1).map(String.init)
        guard let idPart = parts.first, let id = UUID(uuidString: idPart) else {
            return nil
        }

        let title = parts.count > 1 ? parts[1] : "Checklist"
        return BoardChecklist(id: id, title: title)
    }

    private static func parseChecklistItem(from line: String) -> BoardChecklistItem? {
        let uncheckedMarker = ":[ ]"
        let checkedMarker = ":[x]"
        let checkedUppercaseMarker = ":[X]"

        guard line.hasPrefix("checklist-item:") else {
            return nil
        }

        if let markerRange = line.range(of: uncheckedMarker) {
            let text = String(line[markerRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            return BoardChecklistItem(text: text, isDone: false)
        }

        if let markerRange = line.range(of: checkedMarker) {
            let text = String(line[markerRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            return BoardChecklistItem(text: text, isDone: true)
        }

        if let markerRange = line.range(of: checkedUppercaseMarker) {
            let text = String(line[markerRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            return BoardChecklistItem(text: text, isDone: true)
        }

        return nil
    }

    private static func parseLegacyChecklistItem(from line: String) -> BoardChecklistItem? {
        let uncheckedPrefix = "checklist:[ ]"
        let checkedPrefix = "checklist:[x]"
        let checkedUppercasePrefix = "checklist:[X]"

        if line.hasPrefix(uncheckedPrefix) {
            let text = String(line.dropFirst(uncheckedPrefix.count)).trimmingCharacters(in: .whitespaces)
            return BoardChecklistItem(text: text, isDone: false)
        }

        if line.hasPrefix(checkedPrefix) {
            let text = String(line.dropFirst(checkedPrefix.count)).trimmingCharacters(in: .whitespaces)
            return BoardChecklistItem(text: text, isDone: true)
        }

        if line.hasPrefix(checkedUppercasePrefix) {
            let text = String(line.dropFirst(checkedUppercasePrefix.count)).trimmingCharacters(in: .whitespaces)
            return BoardChecklistItem(text: text, isDone: true)
        }

        return nil
    }

    // Legacy checklist rows did not carry checklist IDs. When encountered, they
    // are grouped into a synthetic "Checklist" block for compatibility.
    private static func appendChecklistItem(
        _ checklistItem: BoardChecklistItem,
        to currentColumn: inout BoardColumn?,
        itemIndex: Int,
        checklistID: inout BoardChecklist.ID?
    ) {
        guard let checklistID,
              let checklistIndex = currentColumn?.items[itemIndex].checklists.firstIndex(where: { $0.id == checklistID }) else {
            appendLegacyChecklistItem(checklistItem, to: &currentColumn, itemIndex: itemIndex, checklistID: &checklistID)
            return
        }

        currentColumn?.items[itemIndex].checklists[checklistIndex].items.append(checklistItem)
    }

    private static func appendLegacyChecklistItem(
        _ checklistItem: BoardChecklistItem,
        to currentColumn: inout BoardColumn?,
        itemIndex: Int,
        checklistID: inout BoardChecklist.ID?
    ) {
        if checklistID == nil {
            let checklist = BoardChecklist(title: "Checklist")
            currentColumn?.items[itemIndex].checklists.append(checklist)
            checklistID = checklist.id
        }

        guard let checklistID,
              let checklistIndex = currentColumn?.items[itemIndex].checklists.firstIndex(where: { $0.id == checklistID }) else {
            return
        }

        currentColumn?.items[itemIndex].checklists[checklistIndex].items.append(checklistItem)
    }
}
