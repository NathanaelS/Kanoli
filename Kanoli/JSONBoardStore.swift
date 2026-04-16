import Foundation

struct JSONBoardStore {
    static func importBoard(from jsonURL: URL, to boardURL: URL) throws {
        let didAccessJSON = jsonURL.startAccessingSecurityScopedResource()
        defer {
            if didAccessJSON {
                jsonURL.stopAccessingSecurityScopedResource()
            }
        }

        let columns = try loadBoard(from: jsonURL)
        try MarkdownBoardStore.save(columns: columns, to: boardURL)
    }

    static func loadBoard(from fileURL: URL) throws -> [BoardColumn] {
        let data = try Data(contentsOf: fileURL)
        return try decodeBoard(from: data)
    }

    static func decodeBoard(from data: Data) throws -> [BoardColumn] {
        let decoder = JSONDecoder()
        if let board = try? decoder.decode(ImportedBoard.self, from: data) {
            return board.columns.map { $0.boardColumn }
        }

        if let trelloBoard = try? decoder.decode(TrelloBoard.self, from: data) {
            return trelloBoard.boardColumns
        }

        throw JSONBoardImportError.unsupportedFormat
    }
}

enum JSONBoardImportError: LocalizedError {
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported JSON format. Expected Kanoli export or Trello board export."
        }
    }
}

private struct ImportedBoard: Decodable {
    var columns: [ImportedColumn]
}

private struct ImportedColumn: Decodable {
    var title: String
    var items: [ImportedItem]?

    var boardColumn: BoardColumn {
        BoardColumn(
            title: title,
            items: (items ?? []).map { $0.boardItem }
        )
    }
}

private struct ImportedItem: Decodable {
    var id: UUID?
    var title: String
    var notes: [ImportedNote]
    var checklists: [ImportedChecklist]?
    var dueDate: Date?
    var priority: String?
    var labels: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case notes
        case checklists
        case dueDate
        case priority
        case labels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try ImportedNote.decodeNotesIfPresent(from: container, forKey: .notes)
        checklists = try container.decodeIfPresent([ImportedChecklist].self, forKey: .checklists)
        dueDate = try Self.decodeDateIfPresent(from: container, forKey: .dueDate)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        labels = try container.decodeIfPresent([String].self, forKey: .labels)
    }

    var boardItem: BoardItem {
        BoardItem(
            id: id ?? UUID(),
            title: title,
            notes: notes.map { $0.boardNote },
            checklists: (checklists ?? []).map { $0.boardChecklist },
            dueDate: dueDate,
            priority: priority,
            labels: labels ?? []
        )
    }

    private static func decodeDateIfPresent<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Date? {
        guard let value = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        guard let date = TodoDateFormatter.dateFormatter.date(from: value) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Expected date formatted as yyyy-MM-dd."
            )
        }

        return date
    }
}

private enum ImportedNote: Decodable {
    case text(String)
    case detailed(createdAt: Date?, text: String)

    enum CodingKeys: String, CodingKey {
        case createdAt
        case text
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let text = try? container.decode(String.self) {
            self = .text(text)
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let text = try container.decode(String.self, forKey: .text)
        let createdAt = try Self.decodeDateIfPresent(from: container, forKey: .createdAt)
        self = .detailed(createdAt: createdAt, text: text)
    }

    var boardNote: BoardNote {
        switch self {
        case .text(let text):
            return BoardNote(text: text)
        case .detailed(let createdAt, let text):
            if let createdAt {
                return BoardNote(createdAt: createdAt, text: text)
            }

            return BoardNote(text: text)
        }
    }

    static func decodeNotesIfPresent<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> [ImportedNote] {
        try container.decodeIfPresent([ImportedNote].self, forKey: key) ?? []
    }

    private static func decodeDateIfPresent<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Date? {
        guard let value = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        guard let date = NoteDateFormatter.markdownFormatter.date(from: value) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Expected date formatted as yyyy-MM-dd'T'HH:mm:ssZZZZZ."
            )
        }

        return date
    }
}

private struct ImportedChecklist: Decodable {
    var id: UUID?
    var title: String
    var items: [ImportedChecklistItem]?

    var boardChecklist: BoardChecklist {
        BoardChecklist(
            id: id ?? UUID(),
            title: title,
            items: (items ?? []).map { $0.boardChecklistItem }
        )
    }
}

private struct ImportedChecklistItem: Decodable {
    var id: UUID?
    var text: String
    var isDone: Bool?

    var boardChecklistItem: BoardChecklistItem {
        BoardChecklistItem(
            id: id ?? UUID(),
            text: text,
            isDone: isDone ?? false
        )
    }
}

private struct TrelloBoard: Decodable {
    var lists: [TrelloList]
    var cards: [TrelloCard]
    var checklists: [TrelloChecklist]
    var labels: [TrelloLabel]
    var actions: [TrelloAction]?

    var boardColumns: [BoardColumn] {
        let labelsByID = Dictionary(uniqueKeysWithValues: labels.map { ($0.id, $0.name) })
        let checklistByCardID = Dictionary(grouping: checklists, by: \.idCard)
        let commentsByCardID = Dictionary(grouping: (actions ?? []).compactMap(\.comment), by: \.cardID)

        let cardsByListID = Dictionary(grouping: cards, by: \.idList)
        let sortedLists = lists.sorted { $0.pos < $1.pos }

        return sortedLists.map { list in
            let listCards = (cardsByListID[list.id] ?? [])
                .sorted { $0.pos < $1.pos }
                .map { card in
                    let cardChecklists = (checklistByCardID[card.id] ?? [])
                        .sorted { $0.pos < $1.pos }
                        .map(\.boardChecklist)
                    let cardLabels = card.idLabels.compactMap { labelsByID[$0] }.filter { !$0.isEmpty }
                    let comments = (commentsByCardID[card.id] ?? [])
                        .sorted { $0.date < $1.date }
                        .map { BoardNote(createdAt: $0.date, text: $0.text) }
                    var notes: [BoardNote] = []

                    if !card.desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        notes.append(BoardNote(text: card.desc))
                    }
                    notes.append(contentsOf: comments)

                    return BoardItem(
                        title: card.name,
                        notes: notes,
                        checklists: cardChecklists,
                        dueDate: card.dueDate,
                        priority: nil,
                        labels: cardLabels
                    )
                }

            return BoardColumn(title: list.name, items: listCards)
        }
    }
}

private struct TrelloList: Decodable {
    var id: String
    var name: String
    var pos: Double
}

private struct TrelloCard: Decodable {
    var id: String
    var idList: String
    var name: String
    var desc: String
    var idLabels: [String]
    var pos: Double
    var dueDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case idList
        case name
        case desc
        case idLabels
        case pos
        case due
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        idList = try container.decode(String.self, forKey: .idList)
        name = try container.decode(String.self, forKey: .name)
        desc = try container.decodeIfPresent(String.self, forKey: .desc) ?? ""
        idLabels = try container.decodeIfPresent([String].self, forKey: .idLabels) ?? []
        pos = try container.decodeIfPresent(Double.self, forKey: .pos) ?? 0
        dueDate = try Self.decodeDateIfPresent(from: container, forKey: .due)
    }

    private static func decodeDateIfPresent<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Date? {
        guard let value = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: value)
            ?? ISO8601DateFormatter.standard.date(from: value) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "Expected ISO8601 date in Trello export."
        )
    }
}

private struct TrelloChecklist: Decodable {
    var id: String
    var idCard: String
    var name: String
    var pos: Double
    var checkItems: [TrelloChecklistItem]

    var boardChecklist: BoardChecklist {
        BoardChecklist(
            title: name,
            items: checkItems
                .sorted { $0.pos < $1.pos }
                .map(\.boardChecklistItem)
        )
    }
}

private struct TrelloChecklistItem: Decodable {
    var name: String
    var pos: Double
    var state: String?

    var boardChecklistItem: BoardChecklistItem {
        BoardChecklistItem(
            text: name,
            isDone: state == "complete"
        )
    }
}

private struct TrelloLabel: Decodable {
    var id: String
    var name: String
}

private struct TrelloAction: Decodable {
    var type: String
    var date: Date
    var data: TrelloActionData

    enum CodingKeys: String, CodingKey {
        case type
        case date
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        data = try container.decode(TrelloActionData.self, forKey: .data)

        let value = try container.decode(String.self, forKey: .date)
        guard let parsedDate = ISO8601DateFormatter.withFractionalSeconds.date(from: value)
            ?? ISO8601DateFormatter.standard.date(from: value) else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Expected ISO8601 action date in Trello export."
            )
        }

        date = parsedDate
    }

    var comment: TrelloComment? {
        guard type == "commentCard",
              let cardID = data.card?.id,
              let text = data.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return TrelloComment(cardID: cardID, text: text, date: date)
    }
}

private struct TrelloActionData: Decodable {
    var text: String?
    var card: TrelloActionCard?
}

private struct TrelloActionCard: Decodable {
    var id: String
}

private struct TrelloComment {
    var cardID: String
    var text: String
    var date: Date
}

private extension ISO8601DateFormatter {
    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
