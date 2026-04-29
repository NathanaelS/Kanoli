# Kanoli Flutter Rebuild - Feature Parity Checklist

Status legend:

- `[ ]` Not started
- `[~]` In progress
- `[x]` Done

## Foundation

- [x] Flutter project initialized in `KanoliDartBuild`
- [x] Target platforms enabled: macOS, Windows, Linux, iOS, Android
- [x] App theming baseline configured
- [x] Routing/app shell created
- [x] Error boundary + logging baseline implemented

## Domain and Models

- [x] Board domain models ported with stable IDs
- [x] Due date/priority/label semantics matched
- [x] BoardFilter parity (all due-date rules + label matching)
- [x] Item duplication semantics preserved (new IDs for copied entities)

## Markdown Board Persistence

- [x] Parse `#` columns and `##` cards
- [x] Parse card heading metadata `(P) +labels due: id:`
- [x] Parse note rows with timestamp support
- [x] Parse checklist + checklist-item formats
- [x] Legacy checklist compatibility preserved
- [x] Serialize markdown in Kanoli-compatible format
- [x] Round-trip tests pass against parity fixtures

## Todo Companion File (`*.todo.txt`)

- [x] Default todo filename strategy preserved
- [x] Parse card-scoped lines via `card:<UUID>`
- [x] Preserve unrelated lines/blank lines/spacing
- [x] Serialize with current `card:<UUID>` + optional `@Column`
- [x] Completion date, due date, and priority semantics preserved
- [x] Create/load/save/delete flows implemented

## JSON Import

- [x] Kanoli JSON import format decoded
- [x] Trello export format decoded
- [x] Unsupported/invalid format errors surfaced cleanly
- [x] Imported boards saved to markdown format correctly

## Session and Board Tabs

- [x] Open board file flow
- [x] Create board file flow
- [x] Import JSON board flow
- [x] Multi-tab board state model
- [x] Select/close tab behavior parity
- [x] Restore previous tab session on launch

## Board Interaction

- [x] Add/rename/delete column
- [x] Add/edit/delete card
- [x] Drag/drop card reordering within a column
- [x] Drag/drop card move across columns
- [x] Move card between boards
- [x] Copy card between boards
- [x] Archive card behavior (auto-create Archive column)

## Filtering and Views

- [x] Filter popover UI (due date + labels)
- [x] Filtered result mode within active board
- [x] Cross-board filtered results across open tabs
- [x] Archive toggle visibility behavior

## Item Editor

- [x] Rename card title inline
- [x] Priority + due-date editor
- [x] Labels add/remove + normalization
- [x] Label drill-down to matching cards
- [x] Notes add/commit/delete flow
- [x] Hyperlink detection/rendering for notes
- [x] Checklist add/edit/toggle/delete flows
- [x] Todo panel add/edit/toggle/delete flows

## Platform and File Access

- [x] macOS file picker workflows
- [~] iOS file picker workflows
- [~] Windows/Linux/Android file workflows
- [~] Persisted file permissions/handles strategy validated per OS

## Quality

- [x] Ported unit tests for parser and serialization parity
- [x] Added regression tests for legacy formats
- [x] Widget tests for critical flows
- [~] Smoke tests on all 5 target OSes
- [~] Parity sign-off pass against Swift app behavior
