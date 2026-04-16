import Foundation

// Shared result type for loading a markdown board. The store returns both the
// parsed board and any recoverable error text the UI should surface.
struct BoardLoadResult {
    var columns: [BoardColumn]
    var errorMessage: String?
}

// Cross-board filtering is intentionally model-level so board views, filtered
// result tabs, and label drill-downs can all use the same matching rules.
struct BoardFilter: Equatable {
    var dueDateRule = DueDateRule.any
    var labels: [String] = []

    var isActive: Bool {
        dueDateRule != .any || !labels.isEmpty
    }

    func matches(_ item: BoardItem) -> Bool {
        matchesDueDate(item.dueDate)
            && containsAll(requiredTerms: labels, in: item.labels)
    }

    private func matchesDueDate(_ dueDate: Date?) -> Bool {
        switch dueDateRule {
        case .any:
            return true
        case .hasDueDate:
            return dueDate != nil
        case .noDueDate:
            return dueDate == nil
        case .dueToday:
            guard let dueDate else {
                return false
            }

            return Calendar.current.isDateInToday(dueDate)
        case .overdue:
            guard let dueDate else {
                return false
            }

            return dueDate < Calendar.current.startOfDay(for: Date())
        }
    }

    private func containsAll(requiredTerms: [String], in itemTerms: [String]) -> Bool {
        guard !requiredTerms.isEmpty else {
            return true
        }

        let normalizedItemTerms = Set(itemTerms.map { $0.lowercased() })
        return requiredTerms.allSatisfy { normalizedItemTerms.contains($0.lowercased()) }
    }

    enum DueDateRule: String, CaseIterable, Identifiable {
        case any
        case hasDueDate
        case noDueDate
        case dueToday
        case overdue

        var id: String { rawValue }

        var label: String {
            switch self {
            case .any:
                "Any due date"
            case .hasDueDate:
                "Has due date"
            case .noDueDate:
                "No due date"
            case .dueToday:
                "Due today"
            case .overdue:
                "Overdue"
            }
        }
    }
}

struct BoardTab: Identifiable, Equatable {
    let id = UUID()
    let fileURL: URL

    var title: String {
        fileURL.deletingPathExtension().lastPathComponent
    }

    var normalizedPath: String {
        fileURL.standardizedFileURL.path
    }
}

// Persisted tab state stores security-scoped bookmarks rather than raw paths so
// macOS sandbox permissions can be restored across app launches.
struct BoardTabSession: Codable {
    var tabs: [Tab]
    var selectedTabPath: String?

    struct Tab: Codable {
        var bookmarkData: Data
    }
}

// The core board hierarchy mirrors the markdown format:
// BoardColumn -> "# Heading", BoardItem -> "## Heading", and nested metadata
// lives below the item as quoted lines.
struct BoardColumn: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var items: [BoardItem] = []

    var menuTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled column" : title
    }
}

struct BoardItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var notes: [BoardNote]
    var checklists: [BoardChecklist]
    var dueDate: Date?
    var priority: String?
    var labels: [String]

    init(
        id: UUID = UUID(),
        title: String,
        notes: [BoardNote] = [],
        checklists: [BoardChecklist] = [],
        dueDate: Date? = nil,
        priority: String? = nil,
        labels: [String] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.checklists = checklists
        self.dueDate = dueDate
        self.priority = priority
        self.labels = labels
    }

    var displayTitle: String {
        title.isEmpty ? "New item" : title
    }

    var metadataSummary: String {
        var parts: [String] = []

        if let priority, !priority.isEmpty {
            parts.append("(\(priority))")
        }

        parts += labels.map { "+\($0)" }

        if let dueDate {
            parts.append("due:\(TodoDateFormatter.dateFormatter.string(from: dueDate))")
        }

        return parts.joined(separator: " ")
    }

    // Copies keep the visible card content but intentionally regenerate IDs so
    // duplicated cards, notes, and checklist items remain independently editable.
    func duplicatedWithNewIDs() -> BoardItem {
        BoardItem(
            title: title,
            notes: notes.map { BoardNote(createdAt: $0.createdAt, text: $0.text) },
            checklists: checklists.map { checklist in
                BoardChecklist(
                    title: checklist.title,
                    items: checklist.items.map { BoardChecklistItem(text: $0.text, isDone: $0.isDone) }
                )
            },
            dueDate: dueDate,
            priority: priority,
            labels: labels
        )
    }
}

// Checklist and note IDs are serialized so markdown round-trips do not break
// SwiftUI identity, context menus, or focus state.
struct BoardChecklist: Identifiable, Equatable {
    let id: UUID
    var title: String
    var items: [BoardChecklistItem]

    init(id: UUID = UUID(), title: String, items: [BoardChecklistItem] = []) {
        self.id = id
        self.title = title
        self.items = items
    }
}

struct BoardChecklistItem: Identifiable, Equatable {
    let id: UUID
    var text: String
    var isDone: Bool

    init(id: UUID = UUID(), text: String, isDone: Bool = false) {
        self.id = id
        self.text = text
        self.isDone = isDone
    }
}

struct BoardNote: Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    var text: String

    init(id: UUID = UUID(), createdAt: Date = Date(), text: String) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
    }
}

// Date formatters are centralized because markdown and todo.txt both rely on
// stable, locale-independent date strings.
enum TodoDateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

enum NoteDateFormatter {
    static let markdownFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
