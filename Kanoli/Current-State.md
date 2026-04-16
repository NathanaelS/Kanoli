# Kanoli Current State

## Currently Implemented

- Local-first Kanban boards stored as plain Markdown files.
- Columns stored as Markdown `# Header 1`.
- Cards/items stored as Markdown `## Header 2`.
- Notes stored under cards with creation timestamps.
- Multiple named checklists per card, with unique IDs and interactive completed/uncompleted states.
- Card labels stored as todo.txt-style `+labels`, rendered as removable label chips in the editor.
- Card due date and priority fields.
- Board-level todo.txt support using a derived `BoardName.todo.txt` file.
- Todo items linked to cards with `card:<UUID>` and column context with `@ColumnName`.
- Todo items can be added, edited, checked off, and deleted from inside the card editor.
- Todo list deletion removes the actual `.todo.txt` file.
- Markdown boards can be created, opened, closed, and reopened from persisted tabs.
- Multiple Markdown board tabs.
- Filtered-results tab for viewing matching cards across open boards.
- Filtering by labels and due-date rules.
- Label-click behavior inside a card to view other matching cards.
- Manual card move/copy menu between columns and between open boards.
- Archive and delete card actions.
- Automatic persistence back to Markdown as edits happen.
- Drag and drop reordering within a column.
- Drag and drop moving between columns, using the full column as a drop target.
- Aura color palette styling credited to Dalton Menezes.
- Sandboxed file access using security-scoped bookmarks for reopened boards.

## Easy or Adjacent Next Features

- Add a confirmation dialog before deleting the board-level todo.txt file.
- Add visual drag/drop feedback, such as a highlighted destination column or insertion marker.
- Add column drag/drop reordering.
- Add checklist progress display on cards, such as `3/5`.
- Show todo count or overdue todo count on the card face.
- Add quick label filtering from the main toolbar using existing labels.
- Add a "Clear completed todos" action for the board todo file.
- Add "Move to Archive" keyboard shortcut or menu command.
- Add card search across open tabs using the existing filtered-results view.
- Add sorting options inside columns, such as priority, due date, or title.
- Add a small board status indicator showing the active Markdown file and linked todo file.
- Add export/copy Markdown path actions for the current board.
- Add stronger empty-state UI for new boards and empty columns.
- Add tests around Markdown parsing/serialization now that the file format is stabilizing.

## Roadmap for Adjacent Features

### Phase 1: Safety and Confidence

- Add a confirmation dialog before deleting the board-level todo.txt file.
- Add tests around Markdown parsing and serialization for cards, labels, notes, checklists, and todo metadata.
- Add tests for board-level todo.txt parsing so `card:<UUID>` and `@ColumnName` behavior stays stable.

Goal: protect user data before adding more interaction and workflow features.

### Phase 2: Drag and Drop Polish

- Add visual drag/drop feedback for destination columns.
- Add an insertion marker or highlighted card state while reordering.
- Add column drag/drop reordering after card drag/drop behavior is stable.

Goal: make the existing drag/drop behavior clearer and extend it to columns without changing the Markdown format.

### Phase 3: Card Surface Improvements

- Add checklist progress display on cards, such as `3/5`.
- Show todo count or overdue todo count on the card face.
- Add a small board status indicator showing the active Markdown file and linked todo file.

Goal: make the board view more informative without requiring users to open every card.

### Phase 4: Filtering, Search, and Navigation

- Add quick label filtering from the main toolbar using existing labels.
- Add card search across open tabs using the existing filtered-results view.
- Add sorting options inside columns, such as priority, due date, or title.

Goal: build on the existing filtered-results infrastructure and make larger boards easier to navigate.

### Phase 5: Workflow Shortcuts and Utilities

- Add a "Clear completed todos" action for the board todo file.
- Add "Move to Archive" keyboard shortcut or menu command.
- Add export/copy Markdown path actions for the current board.
- Add stronger empty-state UI for new boards and empty columns.

Goal: smooth out daily-use workflows and make the app feel more complete.

## Summary Pitch

Kanoli is a local-first Kanban app that treats your project board as readable Markdown instead of locking it inside a database. Columns, cards, notes, checklists, labels, due dates, and linked todo.txt tasks are editable through a graphical SwiftUI interface while remaining accessible as plain text files on disk. It supports multiple open boards, cross-board filtering, card movement, archiving, and real-time persistence, making it a lightweight personal planning tool designed for users who want the convenience of a GUI without giving up ownership, portability, or SyncThing-friendly file storage.
