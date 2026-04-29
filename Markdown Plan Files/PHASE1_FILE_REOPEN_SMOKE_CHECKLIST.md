# Phase 1 File Access and Reopen Smoke Checklist

Date: 2026-04-25 13:03:07 MST
Branch: `DartPort-Features`
Workspace: `/Users/krysilisproductions/Documents/Kanoli/KanoliDartBuild/kanoli_flutter`

## Scope

This checklist verifies Phase 1 file-access behavior with emphasis on reopen-after-relaunch and offline local-document guarantees.

## Preflight (Completed)

- [x] `flutter analyze` passes
- [x] `flutter test` passes
- [x] `flutter build macos --debug` passes
- [x] macOS entitlements include sandbox + user-selected read/write access

Entitlement snapshot:
- DebugProfile:
  - `com.apple.security.app-sandbox = true`
  - `com.apple.security.files.user-selected.read-write = true`
- Release:
  - `com.apple.security.app-sandbox = true`
  - `com.apple.security.files.user-selected.read-write = true`

## macOS Reopen Verification

### Test Data

Use a board outside app container, for example:
- `/Users/krysilisproductions/Documents/KanoliBoard.md`
- optional import source: `/Users/krysilisproductions/Documents/*.json`

### Test Cases

1. `Create -> Save -> Relaunch`
- Steps:
  - Launch app.
  - Create a board and save into `/Users/krysilisproductions/Documents`.
  - Add one column and one card.
  - Quit app (`Cmd+Q`).
  - Relaunch app.
- Expected:
  - If `Remember open boards on launch = ON`, board reopens with saved content.
  - If setting is `OFF`, app starts with no board open.

2. `Open existing board -> Relaunch`
- Steps:
  - Open an existing markdown board from Documents.
  - Quit app.
  - Relaunch app.
- Expected:
  - Same remember-setting behavior as above.

3. `Import JSON -> Save markdown -> Relaunch`
- Steps:
  - Import Trello/Kanoli JSON.
  - Save output markdown in Documents.
  - Quit and relaunch.
- Expected:
  - Imported board present on relaunch when remember-setting is ON.

4. `Remember toggle OFF behavior`
- Steps:
  - Open one or more boards.
  - Open `Privacy Settings`.
  - Disable `Remember open boards on launch`.
  - Quit and relaunch.
- Expected:
  - No boards auto-restored.

5. `Clear remembered session data`
- Steps:
  - Open one or more boards.
  - Run `Clear Remembered Session Data` from `Privacy Settings`.
  - Quit and relaunch.
- Expected:
  - No boards auto-restored.

6. `Permission/path change resilience`
- Steps:
  - Open board A.
  - Rename/move board A in Finder while app is closed.
  - Relaunch app.
- Expected:
  - App starts without crash.
  - Missing file does not block launch.

### macOS Execution Log

- Status: PASS
- Completed by agent in this phase:
  - preflight checks and entitlement verification
- Pending manual runtime verification:
  - None, all 6 cases have been ran and succeeded

## Windows / Linux / iOS / Android (Queued)

For each platform, run the same six cases with platform-appropriate file picker paths. Record pass/fail and notes.

- Windows: PENDING
- Linux: PENDING
- iOS: PENDING
- Android: PENDING

## Pass Criteria for Phase 1 Reopen

- macOS: all six cases pass.
- At least one execution pass logged for each remaining platform.
- No crash in create/open/import/relaunch flows.
- Remember-session privacy controls behave exactly as documented.
