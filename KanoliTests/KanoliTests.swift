import XCTest
@testable import Kanoli

final class KanoliTests: XCTestCase {
    func testMarkdownBoardStoreRoundTripsColumnsItemsMetadataNotesAndChecklists() throws {
        let itemID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let checklistID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let noteDate = NoteDateFormatter.markdownFormatter.date(from: "2026-04-13T12:30:00-07:00")!
        let dueDate = TodoDateFormatter.dateFormatter.date(from: "2026-04-16")!
        let columns = [
            BoardColumn(
                title: "Doing",
                items: [
                    BoardItem(
                        id: itemID,
                        title: "Test Item",
                        notes: [BoardNote(createdAt: noteDate, text: "First note")],
                        checklists: [
                            BoardChecklist(
                                id: checklistID,
                                title: "Launch",
                                items: [
                                    BoardChecklistItem(text: "Write tests", isDone: false),
                                    BoardChecklistItem(text: "Ship", isDone: true)
                                ]
                            )
                        ],
                        dueDate: dueDate,
                        priority: "A",
                        labels: ["AI", "more-testing"]
                    )
                ]
            )
        ]

        let fileURL = temporaryMarkdownURL()
        try MarkdownBoardStore.save(columns: columns, to: fileURL)
        let result = MarkdownBoardStore.loadBoard(from: fileURL)
        let loadedItem = try XCTUnwrap(result.columns.first?.items.first)

        XCTAssertNil(result.errorMessage)
        XCTAssertEqual(result.columns.first?.title, "Doing")
        XCTAssertEqual(loadedItem.id, itemID)
        XCTAssertEqual(loadedItem.title, "Test Item")
        XCTAssertEqual(loadedItem.priority, "A")
        XCTAssertEqual(loadedItem.labels, ["AI", "more-testing"])
        XCTAssertEqual(TodoDateFormatter.dateFormatter.string(from: try XCTUnwrap(loadedItem.dueDate)), "2026-04-16")
        XCTAssertEqual(loadedItem.notes.first?.text, "First note")
        XCTAssertEqual(NoteDateFormatter.markdownFormatter.string(from: try XCTUnwrap(loadedItem.notes.first?.createdAt)), "2026-04-13T12:30:00-07:00")
        XCTAssertEqual(loadedItem.checklists.first?.id, checklistID)
        XCTAssertEqual(loadedItem.checklists.first?.title, "Launch")
        XCTAssertEqual(loadedItem.checklists.first?.items.map(\.text), ["Write tests", "Ship"])
        XCTAssertEqual(loadedItem.checklists.first?.items.map(\.isDone), [false, true])
    }

    func testMarkdownBoardStoreParsesLegacyChecklistItems() throws {
        let fileURL = temporaryMarkdownURL()
        try """
        # Doing
        ## Legacy Card id:11111111-1111-1111-1111-111111111111
        > checklist:[ ] First legacy item
        > checklist:[x] Second legacy item
        """.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = MarkdownBoardStore.loadBoard(from: fileURL)
        let checklist = try XCTUnwrap(result.columns.first?.items.first?.checklists.first)

        XCTAssertEqual(checklist.title, "Checklist")
        XCTAssertEqual(checklist.items.map(\.text), ["First legacy item", "Second legacy item"])
        XCTAssertEqual(checklist.items.map(\.isDone), [false, true])
    }

    func testMarkdownBoardStoreIgnoresLegacyTodoMetadata() throws {
        let fileURL = temporaryMarkdownURL()
        try """
        # Doing
        ## Card Title todo:Old%20Todo.txt +AI id:11111111-1111-1111-1111-111111111111
        """.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = MarkdownBoardStore.loadBoard(from: fileURL)
        let item = try XCTUnwrap(result.columns.first?.items.first)

        XCTAssertEqual(item.title, "Card Title")
        XCTAssertEqual(item.labels, ["AI"])
    }

    func testTodoListEntryParsesPriorityDueDateAndCompletionDate() throws {
        let entry = TodoListEntry(line: "2026-04-13 (A) Test ranking due:2026-04-16", isCompleted: true)

        XCTAssertEqual(entry.text, "Test ranking")
        XCTAssertTrue(entry.isCompleted)
        XCTAssertEqual(entry.priority, "A")
        XCTAssertEqual(TodoDateFormatter.dateFormatter.string(from: try XCTUnwrap(entry.completionDate)), "2026-04-13")
        XCTAssertEqual(TodoDateFormatter.dateFormatter.string(from: try XCTUnwrap(entry.dueDate)), "2026-04-16")
    }

    func testTodoBoardStoreParseScopesItemsToRequestedCard() throws {
        let cardID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let otherCardID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let text = "(A) Current card task due:2026-04-16 card:\(cardID.uuidString) @Doing\n  Other card task card:\(otherCardID.uuidString) @Backlog\n\nx 2026-04-13 Done task card:\(cardID.uuidString) @Doing\n\tUntagged board-level task\n"

        let result = TodoBoardStore.parse(text: text, cardID: cardID)

        let firstItem = try XCTUnwrap(result.currentCardItems.first)

        XCTAssertEqual(result.currentCardItems.map(\.text), ["Current card task", "Done task"])
        XCTAssertEqual(firstItem.priority, "A")
        XCTAssertEqual(TodoDateFormatter.dateFormatter.string(from: try XCTUnwrap(firstItem.dueDate)), "2026-04-16")
        XCTAssertTrue(result.currentCardItems[1].isCompleted)
        XCTAssertEqual(result.otherLines, [
            "  Other card task card:\(otherCardID.uuidString) @Backlog",
            "",
            "\tUntagged board-level task"
        ])
    }

    func testTodoBoardStoreSerializePreservesOtherLinesAndAddsCardMetadata() {
        let cardID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let dueDate = TodoDateFormatter.dateFormatter.date(from: "2026-04-16")
        let completionDate = TodoDateFormatter.dateFormatter.date(from: "2026-04-13")
        let items = [
            TodoListEntry(text: "Current task", isCompleted: false, priority: "B", dueDate: dueDate),
            TodoListEntry(text: "Finished task", isCompleted: true, completionDate: completionDate)
        ]

        let text = TodoBoardStore.serialize(
            currentCardItems: items,
            otherLines: ["Existing other card card:22222222-2222-2222-2222-222222222222 @Backlog"],
            cardID: cardID,
            columnContext: "Doing"
        )

        XCTAssertEqual(
            text,
            """
            Existing other card card:22222222-2222-2222-2222-222222222222 @Backlog
            (B) Current task due:2026-04-16 card:\(cardID.uuidString) @Doing
            x 2026-04-13 Finished task card:\(cardID.uuidString) @Doing

            """
        )
    }

    func testTodoBoardStoreRoundTripPreservesUnrelatedSpacingAndBlankLines() throws {
        let cardID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let otherCardID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let text = "  Other task card:\(otherCardID.uuidString) @Backlog\n\n\tLoose task with indentation\nCurrent task card:\(cardID.uuidString) @Doing\n"
        let parsed = TodoBoardStore.parse(text: text, cardID: cardID)
        let serialized = TodoBoardStore.serialize(
            currentCardItems: parsed.currentCardItems,
            otherLines: parsed.otherLines,
            cardID: cardID,
            columnContext: "Doing"
        )

        XCTAssertEqual(
            serialized,
            "  Other task card:\(otherCardID.uuidString) @Backlog\n\n\tLoose task with indentation\nCurrent task card:\(cardID.uuidString) @Doing\n"
        )
    }

    func testTodoBoardStoreBuildsDefaultTodoListURLFromBoardName() throws {
        let boardURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("My Board")
            .appendingPathExtension("md")

        let todoListURL = try TodoBoardStore.defaultTodoListURL(boardFileURL: boardURL)

        XCTAssertEqual(todoListURL.lastPathComponent, "My Board.todo.txt")
        XCTAssertEqual(TodoBoardStore.todoListPath(for: todoListURL, boardFileURL: boardURL), "My Board.todo.txt")
    }

    func testTodoBoardStoreLoadSaveAndDeleteTodoListFile() throws {
        let cardID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let todoListURL = temporaryTodoListURL()
        let dueDate = TodoDateFormatter.dateFormatter.date(from: "2026-04-16")
        let items = [
            TodoListEntry(text: "Write todo file", isCompleted: false, priority: "A", dueDate: dueDate)
        ]

        try TodoBoardStore.createTodoListIfNeeded(at: todoListURL)
        try TodoBoardStore.saveTodoList(
            to: todoListURL,
            currentCardItems: items,
            otherLines: ["Existing task card:22222222-2222-2222-2222-222222222222 @Backlog"],
            cardID: cardID,
            columnContext: "Doing"
        )

        let result = try TodoBoardStore.loadTodoList(
            from: todoListURL,
            cardID: cardID,
            boardFileURL: nil,
            bookmarkStoreData: Data()
        )

        XCTAssertEqual(result.currentCardItems.map(\.text), ["Write todo file"])
        XCTAssertEqual(result.currentCardItems.first?.priority, "A")
        XCTAssertEqual(TodoDateFormatter.dateFormatter.string(from: try XCTUnwrap(result.currentCardItems.first?.dueDate)), "2026-04-16")
        XCTAssertEqual(result.otherLines, ["Existing task card:22222222-2222-2222-2222-222222222222 @Backlog"])

        try TodoBoardStore.deleteTodoList(at: todoListURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: todoListURL.path))
    }

    private func temporaryMarkdownURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("md")
    }

    private func temporaryTodoListURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("todo.txt")
    }
}
