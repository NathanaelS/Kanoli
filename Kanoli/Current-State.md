# Kanoli Current State

## Current Feature Set

- Local-first kanban boards stored as plain Markdown.
- Column and card structure mapped to markdown headings (`#` for columns, `##` for cards).
- Rich card metadata: notes (timestamped), checklists, labels, due date, and priority.
- Built-in board todo support via companion `BoardName.todo.txt` files.
- Todo entries linked to cards using `card:<UUID>` with optional column context (`@ColumnName`).
- Card-level todo create/edit/complete/delete flows in the editor.
- Multi-board workflow: create/open/import, tabbed boards, and tab/session restore.
- Cross-board filtering with due-date rules and label matching.
- Card operations: move/copy (within board and across boards), archive, delete, and drag/drop reorder.
- Auto-persistence to Markdown with sandbox-safe, security-scoped bookmark access.
- Aura-themed visual styling and startup/file command flows for macOS.

## Next Potential Features

- File attachment support at the card level.
- Image support (attach, preview, and render inline where appropriate).
- More readable markdown output (cleaner structure and human-first formatting).
- Confirm before deleting board todo files.
- Add drag/drop destination and insertion feedback.
- Support column drag/drop reordering.
- Show checklist progress and todo counts on cards.
- Add fast card search and quick-label filter controls.
- Add column sorting (priority, due date, title).
- Add “clear completed todos” action.
- Add keyboard shortcut/menu action for “Move to Archive.”
- Add board status/footer showing active Markdown + todo file.
- Expand parsing/serialization test coverage.

## Potential Roadmap

### Phase 1: Data Safety and Format Readability

- Improve markdown readability and structure for hand-editing.
- Add regression tests for markdown/todo parsing and serialization.
- Add deletion confirmations for todo files.

### Phase 2: Attachments and Media

- Add file attachment support on cards.
- Add image attachment support with inline preview.
- Define markdown conventions for attachment/image persistence.

### Phase 3: Board Interaction Polish

- Add drag/drop visual affordances for cards.
- Add column reorder support.
- Improve empty states for new boards/columns.

### Phase 4: Card Visibility and Findability

- Add checklist progress and todo/overdue indicators on card tiles.
- Add toolbar quick filters and cross-board card search.
- Add configurable sort modes per column.

### Phase 5: Workflow Shortcuts and Utilities

- Add clear-completed-todos action.
- Add archive keyboard shortcut and command improvements.
- Add quick actions for board file path/export copy.
