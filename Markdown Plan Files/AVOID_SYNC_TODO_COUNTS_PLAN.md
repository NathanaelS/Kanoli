# Avoid Synchronous Todo Count Reads Plan

Created: 2026-06-16T18:54:08Z
Workspace: `/Users/krysilisproductions/Documents/Kanoli/KanoliDart/kanoli_flutter`
Status: Completed in code/tests; manual validation pending

## Current Goal

Move active todo sidecar counting out of `BoardWorkspacePage` rebuilds with the smallest safe change.

The current board-face todo progress implementation computes active sidecar counts during widget rebuilds by reading `BoardName.todo.txt` synchronously. The goal is to preserve the visible card tile counts while moving sidecar file I/O to controller-owned state so rebuilds consume cached data.

## Non-Goals

- Do not change Markdown board parsing, serialization, or card IDs.
- Do not change `todo.txt` line format or sidecar file naming.
- Do not add file watching, background services, cloud sync, telemetry, or new dependencies.
- Do not redesign card tile UI.
- Do not move checklist counts; those already come from `BoardItem`.
- Do not make todo counts perfectly live for external sidecar edits unless explicitly requested.

## Relevant Files

- `kanoli_flutter/lib/features/board/presentation/board_workspace_page.dart`
- `kanoli_flutter/lib/features/board/application/board_session_controller.dart`
- `kanoli_flutter/lib/data/board/todo_board_store.dart`
- `kanoli_flutter/test/features/board/board_workspace_page_test.dart`
- `kanoli_flutter/test/features/board/board_session_controller_test.dart`
- `kanoli_flutter/test/data/todo_board_store_test.dart`

## Phase Plan

### Phase 1
- [x] Add cached active todo counts to `BoardSessionController`.
- [x] Add an internal async refresh method that reads `activeTodoPath`, calls `TodoBoardStore.countsByCardId`, stores the result, and notifies listeners.
- [x] Guard async refresh ordering so stale reads cannot overwrite counts after board or todo path changes.
- [x] Clear counts when the active todo path is missing, empty, deleted, or unreadable.

### Phase 2
- [x] Change `BoardWorkspacePage` to consume controller-owned cached counts.
- [x] Remove synchronous `File.existsSync()` and `readAsStringSync()` calls from board rebuild logic.
- [x] Keep existing card tile checklist and todo progress rendering unchanged.

### Phase 3
- [x] Add focused controller coverage for active todo count refresh.
- [x] Add or update widget coverage proving card-face todo progress still renders from cached counts.
- [x] `TodoBoardStore` API was unchanged, so no additional store-test changes were needed.

## Compatibility Risks

- Markdown format: no planned changes.
- `todo.txt`: parser/count behavior should remain byte-compatible; only read timing changes.
- Trello import: no planned changes.
- Persistence: no planned board or sidecar write changes.
- UI/state behavior: counts may be briefly empty while async refresh completes.
- External sidecar edits: counts may remain stale until the next explicit refresh trigger.
- Board switching: stale async reads must not update the newly selected board's counts.
- Sidecar failure: missing or unreadable files should produce empty counts and avoid crashing board rendering.

## Validation Plan

- [x] `dart format .`
- [x] `flutter analyze`
- [x] `flutter test --no-pub test/features/board/board_session_controller_test.dart`
- [x] `flutter test --no-pub test/features/board/board_workspace_page_test.dart`
- [x] `flutter test --no-pub test/data/todo_board_store_test.dart`
- [ ] manual validation: open a board with an active todo sidecar and verify card-face todo counts appear without synchronous rebuild reads.

## Completion Criteria

- [x] Board rebuilds no longer read the active todo sidecar synchronously.
- [x] Card tiles still show checklist and todo progress counts.
- [x] Active todo count refresh is owned by controller state or an equivalently non-widget state boundary.
- [x] Markdown and `todo.txt` compatibility are unchanged.
- [x] Relevant tests/checks pass or limitations are documented.
- [x] Remaining risks and follow-up work are summarized.
