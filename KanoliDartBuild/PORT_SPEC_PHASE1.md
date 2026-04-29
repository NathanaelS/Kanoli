# Kanoli Swift -> Flutter Port Spec (Phase 1)

## Scope and Non-Negotiables

- Source of truth (read-only): `/Users/krysilisproductions/Documents/Kanoli`
- New implementation workspace: `/Users/krysilisproductions/Documents/KanoliDartBuild`
- No file in `Kanoli` is modified, deleted, or moved.
- Goal: behavioral parity first, then UX polish.

## Current Swift App Architecture (Observed)

- Entrypoint: `Kanoli/KanoliApp.swift`
- Main UI and most feature UI logic: `Kanoli/ContentView.swift` (single large file)
- Session/domain state owner: `Kanoli/BoardSessionStore.swift`
- Domain models: `Kanoli/BoardModels.swift`
- Markdown board persistence: `Kanoli/MarkdownBoardStore.swift`
- Card-scoped todo.txt persistence: `Kanoli/TodoBoardStore.swift`
- Trello/Kanoli JSON import: `Kanoli/JSONBoardStore.swift`
- Crash diagnostics/logging: `Kanoli/CrashLogStore.swift`
- Legacy unused scaffold: `Kanoli/Persistence.swift` (Core Data template)

## Feature and Data Semantics to Preserve

### Board File Model

- Board columns are Markdown `#` headings.
- Cards are Markdown `##` headings.
- Card metadata in heading line uses todo.txt-like tokens:
  - priority `(A)` style
  - labels as `+label`
  - due date `due:yyyy-MM-dd`
  - stable identity token `id:<UUID>`
- Notes/checklists stored as quoted lines (`>`):
  - note lines: `note:<timestamp> text`
  - checklist header: `checklist:<checklistUUID> Title`
  - checklist item: `checklist-item:<checklistUUID>:[ ] text` or `[x]`
- Backward compatibility behavior exists for legacy checklist line formats.

### Session Behavior

- Multi-tab board session restore on launch.
- Bookmark-based file access persistence (security scoped).
- Fallback restore from last-opened board bookmark.
- Cross-board operations (copy/move card between open board tabs).

### Card Editor Behavior

- Inline card title editing.
- Notes with timestamps and link auto-detection.
- Multiple checklists per card.
- Labels with quick filter drill-down to other matching cards.
- Priority and optional due date.
- Card-scoped todo list integration with companion `BoardName.todo.txt` file.

### Filtering Behavior

- Due-date rules:
  - any
  - has due date
  - no due date
  - due today
  - overdue
- Label filtering (contains all selected labels)
- Filtered results can span all open boards.

## Flutter Target Architecture

- `lib/core/`
  - app shell, routing, theme, error boundaries, platform services
- `lib/domain/`
  - entities: board, column, item, note, checklist, todo entry
  - pure domain rules (filters, normalization)
- `lib/data/`
  - markdown parser/serializer
  - todo file parser/serializer
  - json import adapters (Kanoli JSON + Trello JSON)
  - repository abstractions and file system adapters
- `lib/features/board/`
  - board workspace, tabs, columns/cards, DnD
- `lib/features/item_editor/`
  - notes/checklists/todo integration/labels
- `lib/features/filtering/`
  - board + cross-board filter UI and logic
- `test/`
  - parser/serializer parity tests
  - domain behavior tests
  - widget tests for key flows

## Swift -> Flutter Type Mapping

- `BoardColumn` -> `BoardColumnEntity`
- `BoardItem` -> `BoardItemEntity`
- `BoardNote` -> `BoardNoteEntity`
- `BoardChecklist` -> `BoardChecklistEntity`
- `BoardChecklistItem` -> `BoardChecklistItemEntity`
- `TodoListEntry` -> `TodoEntryEntity`
- `BoardFilter` + `DueDateRule` -> `BoardFilter` + enum
- `BoardSessionStore` -> `BoardSessionController` + repositories/services

## Platform Strategy (5 OS Targets)

- Shared Flutter app for macOS, Windows, Linux, iOS, Android.
- File access strategy:
  - macOS/iOS: document picker + app-scoped permissions/bookmark-like persistence via platform-compatible storage approach.
  - Windows/Linux/Android: filesystem/document picker with persisted path handles where possible.
- Keep file format identical across all platforms.

## Migration Sequence (Implementation Plan Preview)

1. Build domain and data parity layers first (no UI coupling).
2. Port markdown/todo/json parsers with test parity against Swift fixture behavior.
3. Implement board session controller with open/close/select tab semantics.
4. Build board shell UI (columns/cards, add/edit/delete, DnD).
5. Build item editor UI (notes/checklists/labels/todo panel).
6. Add cross-board filtering and transfer flows.
7. Add crash/event diagnostics equivalent.
8. Platform test sweep and parity sign-off.

## Explicit Out of Scope for Initial Port

- New features beyond current Swift behavior.
- File format changes.
- Refactoring the original Swift project.

