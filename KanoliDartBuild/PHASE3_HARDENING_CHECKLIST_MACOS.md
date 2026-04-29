# Phase 3 Hardening Checklist (macOS)

Date started: 2026-04-28  
Project root: `/Users/krysilisproductions/Documents/Kanoli/KanoliDartBuild/kanoli_flutter`

## Workstream 1: Safe Persistence Layer

- [x] Added shared atomic write helper (`SafeFileStore`).
- [x] Replaced direct markdown save writes with atomic writes.
- [x] Replaced direct todo save/create/delete writes with safe file helper.
- [x] Added rolling backup snapshots with cap support.
- [x] Added automated tests for safe write + backup cap behavior.
- [x] `flutter analyze` passes.
- [x] `flutter test` passes.

Notes:
- Backups are written under a per-file folder in `.kanoli_backups` next to the target file.
- Current implementation keeps the most recent `maxBackups` snapshots (default: 5).

## Workstream 2: Error UX and Recovery

- [x] Standardize user-facing IO errors.
- [x] Add missing/moved file recovery flow for reopen.
- [x] Add reveal/copy-path actions.
- [x] Ensure sidecar failures are non-blocking with clear feedback.

## Workstream 3: Destructive Action Guardrails

- [x] Confirmations for delete column/card/todo file.
- [x] Confirmation for import destination overwrite.
- [x] Optional “don’t ask again” preferences.

## Workstream 4: Local Diagnostics

- [x] Rotating local diagnostics log.
- [x] In-app diagnostics panel.
- [x] Crash-safe startup fallback prompt.

## Exit Criteria

- [x] `flutter analyze` pass (current branch state).
- [x] `flutter test` pass (current branch state).
- [ ] macOS hardening smoke checklist pass.
- [ ] no known P0/P1 data-loss defects.
