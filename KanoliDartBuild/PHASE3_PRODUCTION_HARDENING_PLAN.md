# Phase 3 Production Hardening Plan (macOS-first)

Date: 2026-04-25  
Branch: `DartPort-Features`  
Workspace: `/Users/krysilisproductions/Documents/Kanoli/KanoliDartBuild/kanoli_flutter`

## Objective

Harden the Flutter macOS build for reliable daily use after Phase 2 parity completion.  
Primary focus: resilience, data safety, and failure recovery.  
Cross-platform hardening (Windows/Linux/iOS/Android) is explicitly deferred.

## Scope (In)

- Autosave reliability and clearer save failure UX.
- Atomic file writes for board markdown and todo sidecar files.
- Optional local backup-before-save snapshots.
- Better corruption/error handling and user recovery paths.
- Explicit confirmations for destructive operations.
- Local-first diagnostics (human-readable logs, no telemetry).

## Scope (Out for Phase 3)

- Encryption/password protection (Phase 4).
- Packaging/signing/distribution readiness (Phase 5).
- New platform smoke coverage beyond macOS.
- Feature expansion unrelated to reliability (calendar/timeline/plugins/etc).

## Workstream 1: Safe Persistence Layer

Goal: prevent partial/corrupt writes and improve recovery from interrupted saves.

Tasks:
1. Implement atomic write helper for markdown and todo files:
   - write to temp file in same directory
   - fsync/flush
   - replace target file atomically
2. Add backup-before-save option:
   - keep rolling snapshots (for example last 5)
   - store in local app data folder with board-based subfolders
3. Add write result model:
   - success
   - permission denied
   - file missing/moved
   - unknown IO failure

Acceptance criteria:
- No direct overwrite writes remain in save paths.
- Interrupted write simulation does not leave malformed target file.
- Backup snapshots are created and capped correctly.

## Workstream 2: Error UX and Recovery

Goal: every failure mode provides clear, actionable feedback.

Tasks:
1. Standardize save/open/import error surfaces:
   - concise headline
   - OS error reason
   - suggested next action
2. Add missing/moved file recovery dialog on reopen:
   - remove stale reference
   - browse for new location
3. Add “Reveal file” / “Copy path” utility actions for active board and todo file.
4. Add non-blocking fallback behavior for sidecar failures:
   - board editing remains usable even if todo path fails

Acceptance criteria:
- Permission-denied, missing-file, malformed-file, and save-failure paths all show user-facing explanations.
- App remains interactive after all tested failures.

## Workstream 3: Destructive Action Guardrails

Goal: reduce accidental data loss.

Tasks:
1. Add confirmation prompts for:
   - delete column
   - delete card
   - delete todo file
   - overwrite import destination
2. Add optional “Don’t ask again” preference where appropriate.
3. Ensure undo-safe internal ordering:
   - persist after confirmation only
   - avoid pre-delete writes

Acceptance criteria:
- All destructive actions require explicit confirmation by default.
- No destructive action executes without visible user intent.

## Workstream 4: Local Diagnostics and Supportability

Goal: make troubleshooting possible without external services.

Tasks:
1. Add structured local diagnostic log file rotation.
2. Add in-app “Diagnostics” panel:
   - recent errors
   - current board path
   - current todo path
   - export diagnostics text
3. Add crash-safe startup handling:
   - if last run failed during open/restore, app boots to safe mode prompt

Acceptance criteria:
- Users can inspect/export logs locally.
- No telemetry/network dependencies introduced.

## Workstream 5: Phase 3 Test Plan (macOS)

Automated:
1. Atomic write unit tests (success/failure/interrupt simulation).
2. Backup rotation tests.
3. Error classification tests for IO exceptions.
4. Controller/widget tests for destructive confirmation flow.

Manual:
1. Permission denied on save/open/todo paths.
2. Missing/renamed board on relaunch.
3. Malformed markdown and malformed json handling.
4. Crash/restart resilience for autosave.
5. Backup restore spot checks from snapshots.

Exit criteria:
- `flutter analyze` pass.
- `flutter test` pass including new hardening tests.
- macOS hardening smoke checklist pass.
- No known P0/P1 data-loss defects open.

## Suggested Execution Order

1. Workstream 1 (Safe Persistence Layer)
2. Workstream 2 (Error UX and Recovery)
3. Workstream 3 (Destructive Action Guardrails)
4. Workstream 4 (Local Diagnostics)
5. Workstream 5 (Validation and signoff)

## Deliverables

1. Hardened persistence implementation in app code.
2. New/updated tests for reliability flows.
3. `PHASE3_HARDENING_CHECKLIST_MACOS.md` (execution log and pass/fail).
4. `PHASE3_SIGNOFF.md` with known limitations and deferred items.

## Risks and Mitigations

1. Risk: atomic replace behavior edge cases on sandboxed paths.
   - Mitigation: same-directory temp files + explicit macOS manual path tests.
2. Risk: backup feature increases IO overhead.
   - Mitigation: configurable snapshot cap and deferred cleanup.
3. Risk: confirmation prompts slow power users.
   - Mitigation: optional “don’t ask again” settings with sane defaults.

