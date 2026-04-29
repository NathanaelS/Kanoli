# Phase 2 Parity Smoke Matrix

Date: 2026-04-25  
Branch: `DartPort-Features`  
Workspace: `/Users/krysilisproductions/Documents/Kanoli/KanoliDartBuild/kanoli_flutter`

## Goal

Execute parity smoke tests from the roadmap across core workflows and failure paths, with clear separation between:
- automated checks executed in-repo
- manual runtime checks per target OS

Current scope decision:
- Phase 2 is macOS-first.
- Windows/Linux/iOS/Android smoke runs are deferred to a later platform-expansion phase.

## Automated Checks (Executed)

- [x] `flutter analyze` (pass)
- [x] `flutter test` (pass)
- [x] Session restore skips missing/renamed file paths and keeps valid tabs
- [x] Invalid JSON import reports error and does not crash
- [x] Missing board path reports file-not-found and does not activate a board
- [x] Existing parser and persistence regression suites still pass:
  - markdown parse/serialize
  - todo companion file behavior
  - JSON decoding (Kanoli + Trello)
  - board controller operations (move/copy/archive/filter/tab restore)

## macOS Runtime Smoke (Manual)

Status: [x] Completed (PASS)

- [x] Create -> Save -> Relaunch
- [x] Open existing board -> Relaunch
- [x] Import JSON -> Save markdown -> Relaunch
- [x] Todo companion file behavior (`*.todo.txt`) create/save/delete/merge
- [x] Multi-board move/copy + relaunch persistence sanity
- [x] Drag/drop reorder (within column + cross-column)
- [x] Filter + cross-board filter manual UX validation
- [x] Rapid card-editor save stress pass
- [x] Malformed markdown file open behavior
- [x] Malformed JSON import behavior
- [x] Missing/renamed file recovery behavior
- [x] Permission-denied path behavior (with explicit user-facing error message)

## Windows Runtime Smoke (Manual)

Status: [~] Deferred (out of current phase scope)

- [ ] Create/Open/Import/Relaunch
- [ ] Session restore
- [ ] Todo sidecar behavior
- [ ] Move/copy/drag/drop/filter/card editor stress
- [ ] Malformed and permission-denied path scenarios

## Linux Runtime Smoke (Manual)

Status: [~] Deferred (out of current phase scope)

- [ ] Create/Open/Import/Relaunch
- [ ] Session restore
- [ ] Todo sidecar behavior
- [ ] Move/copy/drag/drop/filter/card editor stress
- [ ] Malformed and permission-denied path scenarios

## iOS Runtime Smoke (Manual)

Status: [~] Deferred (out of current phase scope)

- [ ] Document picker lifecycle
- [ ] Create/Open/Import/Relaunch
- [ ] Session restore
- [ ] Todo sidecar behavior
- [ ] Move/copy/filter/card editor stress
- [ ] Malformed input scenarios

## Android Runtime Smoke (Manual)

Status: [~] Deferred (out of current phase scope)

- [ ] Storage Access Framework picker lifecycle
- [ ] Create/Open/Import/Relaunch
- [ ] Session restore
- [ ] Todo sidecar behavior
- [ ] Move/copy/filter/card editor stress
- [ ] Malformed input scenarios

## Phase 2 Exit Criteria

- [x] macOS runtime smoke list completed
- [x] No crash in create/open/import/relaunch flows on macOS scope
- [x] Phase 2 accepted as macOS-first baseline

## Notes

- 2026-04-25: Added automated failure-path controller tests to strengthen Phase 2 coverage:
  - restore with missing path
  - malformed JSON import handling
  - missing board path handling
- 2026-04-25: macOS manual smoke completed as PASS, including:
  - todo sidecar creation/reopen under sandbox constraints
  - drag/drop interaction quality pass (empty-column drop + stronger hover indication)
  - permission-denied flow now surfaces explicit OS reason to user
