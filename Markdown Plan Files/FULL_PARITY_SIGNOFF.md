# Kanoli Flutter Full Parity Signoff

Date: 2026-04-23
Workspace: `/Users/krysilisproductions/Documents/Kanoli/KanoliDart/kanoli_flutter`
Source app kept untouched during original parity work: `/Users/krysilisproductions/Documents/Kanoli/KanoliSwift`

Current planning source: `/Users/krysilisproductions/Documents/Kanoli/KanoliDart/Kanoli_Roadmap_Board.md`

## Current Status Note

This document is retained as the historical feature parity signoff. Since this signoff, Phase 2 macOS smoke testing and Phase 3 macOS hardening have also been completed. Current planning and tracking now lives in the Kanoli board in the KanoliDart repo.

## Summary

The Flutter rebuild now implements feature-level parity with the Swift Kanoli application for core board workflows, markdown/todo/json persistence, multi-tab sessions, filtering, board/item actions, and item-detail editing flows.

## Implemented Parity Areas

- Startup actions: create/open/import board
- Markdown board persistence (parse/serialize)
- Todo sidecar persistence (parse/serialize, card-scoped lines)
- Trello + Kanoli JSON import
- Multi-tab session model, select/close behavior
- Session restore on launch (persisted tab paths + selected tab)
- Board interactions:
  - add/rename/delete columns
  - add/edit/delete cards
  - in-column reorder
  - cross-column move via drag/drop target zones
  - move/copy to other columns and other open boards
  - archive action with auto-created Archive column
- Filtering:
  - due-date rules and label matching
  - filtered result columns across open tabs
  - archive-only toggle
- Item editor:
  - title, priority, due date
  - labels add/remove/normalize
  - label drill-down to matching cards
  - notes add/edit/delete
  - hyperlink rendering + open external URLs
  - checklists add/edit/toggle/delete
  - todo panel add/edit/toggle/delete

## Verification Completed

- `flutter analyze`: pass
- `flutter test`: pass at signoff time (15 tests)
- Current spot check on 2026-05-10: `flutter test` passes (22 tests)
- Added controller-level parity tests for:
  - cross-column move positioning
  - archive behavior
  - cross-board filter aggregation
  - tab session restore
  - cross-board move/copy persistence

## External Blockers for Platform Verification

The following are environment/toolchain prerequisites, not app-code gaps:

- macOS release build blocking status is no longer tracked here. A macOS `.dmg` artifact exists; signing, notarization, installer QA, and release readiness are tracked on the Kanoli board.
- iOS/Android/Windows/Linux smoke runs require platform toolchains/devices/simulators configured in the environment.

## Practical 1:1 Status

- Feature parity in app logic and workflows: Achieved.
- Cross-platform build/distribution verification: Pending external setup.
