# Phase 0 Baseline Report

Date: 2026-04-25 12:54:19 MST
Workspace: `/Users/krysilisproductions/Documents/Kanoli/KanoliDartBuild/kanoli_flutter`
Branch: `DartPort-Features`

## 1. Baseline Gates

### 1.1 `flutter analyze`
- Command: `flutter analyze`
- Result: PASS
- Output summary: `No issues found!`

### 1.2 `flutter test`
- Command: `flutter test`
- Result: PASS
- Output summary: `All tests passed!` (16 tests)

## 2. Toolchain Snapshot

### 2.1 Flutter / Dart
- Flutter: `3.41.7` (stable)
- Framework revision: `cc0734ac71`
- Engine revision: `59aa584fdf` (engine hash `7a53c052bc4b...`)
- Dart SDK: `3.11.5`
- DevTools: `2.54.2`

### 2.2 Apple Toolchain / OS
- Xcode: `26.4.1`
- Xcode build version: `17E202`
- macOS: `26.3.2`
- macOS build: `25D2140`

## 3. Dependency Snapshot (Resolved Direct Dependencies)

From `pubspec.lock`:
- `cupertino_icons` = `1.0.9`
- `file_selector` = `1.1.0`
- `path_provider` = `2.1.5`
- `shared_preferences` = `2.5.5`
- `url_launcher` = `6.3.2`
- `flutter_lints` = `6.0.0`

Declared constraints from `pubspec.yaml` remain:
- `cupertino_icons: ^1.0.8`
- `file_selector: ^1.0.3`
- `path_provider: ^2.1.5`
- `shared_preferences: ^2.5.3`
- `url_launcher: ^6.3.2`

## 4. Swift-to-Flutter Compatibility Fixture Evidence

Evidence captured from existing automated tests:

### 4.1 Markdown compatibility
- File: `test/data/markdown_board_store_test.dart`
- Cases:
  - `round-trips columns, item metadata, notes, and checklists`
  - `parses legacy checklist items`
  - `ignores legacy todo metadata token on card heading`
  - `parses Swift-exported mixed board markdown safely`
- Notes: Includes a mixed Swift-export style markdown fixture with labels, notes, due dates, checklist metadata, archive column, and empty-title card handling.

### 4.2 JSON compatibility
- File: `test/data/json_board_store_test.dart`
- Cases:
  - `decodes Kanoli JSON columns/items/notes/checklists`
  - `decodes Trello board export`
  - `rejects invalid imported due date format`

### 4.3 Todo companion compatibility
- File: `test/data/todo_board_store_test.dart`
- Cases:
  - `parses card-scoped items and preserves other lines`
  - `serializes while preserving other lines and card metadata`
  - `load-save-delete todo list file`

## 5. Phase 0 Acceptance Checklist

- [x] `flutter analyze` passes
- [x] Full Flutter tests pass
- [x] Toolchain snapshot recorded
- [x] Dependency snapshot recorded
- [x] Swift/legacy compatibility fixture evidence recorded
- [ ] Clean working tree at freeze point

Working tree note at capture time:
- Modified: `KanoliDartBuild/kanoli_flutter/lib/features/board/presentation/board_workspace_page.dart`
- Untracked: `PROJECT_SCOPE_ROADMAP_SECURITY.md`

## 6. Phase 0 Status

Phase 0 execution is complete from a validation/documentation standpoint. The only unmet freeze criterion is a clean working tree at capture time.

Recommended closeout step before Phase 1:
- Commit or stash in-progress changes so the freeze baseline is fully reproducible.
