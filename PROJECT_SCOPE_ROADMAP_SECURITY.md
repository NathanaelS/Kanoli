# Kanoli Project Scope, Parity Roadmap, and Security Audit

Date: 2026-04-25

## Executive Summary

Kanoli is a local-first, offline-capable kanban application for personal and team boards stored in human-readable documents. The original working build is a SwiftUI macOS/iOS app backed by Markdown board files and optional board-adjacent `todo.txt` companion files. The current rebuild is a Flutter/Dart application intended to preserve the Swift app's behavior while expanding practical reach to macOS, Windows, Linux, iOS, and Android.

The Flutter build has reached broad feature-level parity in domain logic, file parsing, session behavior, board operations, filtering, JSON import, and card editing workflows. The remaining work is less about recreating the data model and more about production hardening: platform file-access validation, OS-specific smoke testing, packaging, offline/security guarantees, and polish that makes the Flutter build feel as trustworthy as the Swift build.

The product requirement is strict: Kanoli should work 100% offline with only local documents. Network access must be optional, user-triggered, and removable without harming core board functionality.

## Product Scope

### Core Purpose

- Local kanban boards for tasks, projects, notes, checklists, priorities, labels, and due dates.
- Plain document ownership: users should be able to inspect, copy, sync, back up, and version their files outside the app.
- Offline-first operation with no required account, server, cloud API, telemetry service, or remote database.
- Portable board data using Markdown plus optional `todo.txt` companion files.
- Trello JSON import for migration into local Kanoli documents.

### Source of Truth

- Swift reference app: `/Users/krysilisproductions/Documents/Kanoli/Kanoli`
- Flutter rebuild: `/Users/krysilisproductions/Documents/Kanoli/KanoliDartBuild/kanoli_flutter`
- Port documentation: `/Users/krysilisproductions/Documents/Kanoli/KanoliDartBuild`

### Target Platforms

- Swift build: macOS-first, with iOS-oriented code paths and Apple security-scoped file access.
- Flutter build: macOS, Windows, Linux, iOS, and Android.

### Non-Goals

- No required cloud sync.
- No remote collaboration backend in the parity target.
- No account system in the parity target.
- No opaque database as the only user data format.
- No telemetry or analytics requirement.
- No dependence on internet access for opening, editing, saving, importing, or restoring boards.

## Data Model and File Format

### Board Markdown

Kanoli board files use Markdown as the primary storage format:

- `# Column Title` defines a board column.
- `## Card Title ...metadata` defines a card.
- Card metadata is encoded in todo.txt-like tokens:
  - `(A)` through `(D)` priority.
  - `+label` labels.
  - `due:yyyy-MM-dd` due date.
  - `id:<UUID>` stable card identity.
- Card notes are stored as quoted lines:
  - `> note:<timestamp> text`
- Checklists are stored as quoted structured lines:
  - `> checklist:<checklistUUID> Title`
  - `> checklist-item:<checklistUUID>:[ ] text`
  - `> checklist-item:<checklistUUID>:[x] text`
- Legacy checklist formats are intentionally supported for backward compatibility.

### Todo Companion Files

Kanoli supports board-adjacent `todo.txt` files:

- Default path is derived from the board filename, e.g. `Project.md` -> `Project.todo.txt`.
- Card-scoped todos use `card:<UUID>`.
- Optional column context uses `@ColumnName`.
- Lines belonging to other cards, unrelated todos, blank lines, and spacing should be preserved.
- The editor only mutates the current card's scoped lines.

### JSON Import

The app imports:

- Kanoli JSON export format.
- Trello board export JSON.

Imported JSON is converted into the Kanoli Markdown storage format.

## Swift Reference Build: Working State

The Swift build is the behavioral reference for parity.

### Implemented Swift Features

- Local-first Markdown board storage.
- Column/card mapping through Markdown headings.
- Card metadata: notes, checklists, labels, due dates, priority, stable IDs.
- Board-level `todo.txt` support with card-scoped todo entries.
- Create, open, and import board flows.
- Multi-board tabs and session restore.
- Security-scoped bookmark persistence for sandbox-safe file access.
- Cross-board filtering by due-date rule and labels.
- Board actions:
  - Add, rename, and delete columns.
  - Add, edit, archive, delete, move, copy, and reorder cards.
  - Move/copy cards within a board and across open boards.
- Item editor:
  - Title editing.
  - Priority and due date editing.
  - Label add/remove and label drill-down.
  - Timestamped notes.
  - Hyperlink detection.
  - Multiple checklists.
  - Card-scoped todo panel.
- macOS-oriented visual styling and file command flows.
- Crash diagnostics and logging scaffolding.

### Known Swift Improvement Areas

- Card-level attachments and images are not yet implemented.
- Markdown readability can be improved for hand editing.
- Todo companion file deletion should require clearer confirmation.
- Drag/drop affordances can be made more explicit.
- Column reordering is a desired enhancement.
- Card tiles could show checklist and todo progress.
- Faster search and quick filters are desirable.
- Sorting modes by priority, due date, and title are not yet complete.

## Flutter Build: Current State Compared to Swift

### Current Practical Status

The Flutter port is functionally close to the Swift app for the central board experience. Existing project docs report feature-level parity for core workflows, with passing `flutter analyze` and `flutter test` at the last documented signoff. The active gap is platform validation and production-grade file permission behavior across all target operating systems.

### Parity Matrix

| Area | Swift Reference | Flutter Current State | Status |
|---|---|---|---|
| Markdown board parse/save | Implemented | Implemented with tests | Parity likely |
| Legacy checklist compatibility | Implemented | Implemented with regression tests | Parity likely |
| Todo companion parse/save | Implemented | Implemented with preservation behavior | Parity likely |
| Trello JSON import | Implemented | Implemented | Parity likely |
| Kanoli JSON import | Implemented | Implemented | Parity likely |
| Create/open/import board | Implemented | Implemented; macOS native dialog bridge plus file selector fallback | Mostly parity |
| Multi-tab boards | Implemented | Implemented | Parity likely |
| Session restore | Security-scoped bookmarks and tab session | Path-based session restore via `shared_preferences` | Partial parity |
| macOS file permission restore | Security-scoped bookmarks | Not fully validated/equivalent | Gap |
| iOS file permission restore | Apple document access model | Not fully validated/equivalent | Gap |
| Windows/Linux/Android file workflows | Not primary Swift target | Scaffolded through Flutter/file selector/path prompts | Needs smoke testing |
| Add/edit/delete columns | Implemented | Implemented | Parity likely |
| Add/edit/delete cards | Implemented | Implemented | Parity likely |
| Drag/drop reorder | Implemented | Implemented | Needs UX verification |
| Cross-board move/copy | Implemented | Implemented | Parity likely |
| Archive behavior | Implemented | Implemented | Parity likely |
| Due date and label filters | Implemented | Implemented | Parity likely |
| Cross-board filtering | Implemented | Implemented | Parity likely |
| Card editor | Implemented | Implemented | Parity likely |
| Hyperlink opening | Implemented | Implemented through `url_launcher` | Offline-safe only if treated as explicit external action |
| Crash diagnostics | Swift crash store | Flutter error reporter/debug logging | Partial parity |
| Packaging/distribution | Existing alpha path documented | Not fully validated for all target OSes | Gap |

### Important Current Gaps

1. Persisted file access is not yet equivalent to the Swift security-scoped bookmark model.
2. Cross-platform smoke testing remains incomplete for macOS, Windows, Linux, iOS, and Android.
3. macOS release build previously required CocoaPods setup.
4. The Flutter app stores session paths in local preferences; this is convenient but needs privacy review and platform permission handling.
5. Hyperlinks can launch external URLs. This does not break offline board functionality, but it is the only obvious network-adjacent behavior and should be explicitly user-controlled.
6. There is no implemented encryption/password protection layer yet.
7. There is no full attachment/image storage model yet.

## Roadmap to Full Swift Parity

### Phase 0: Baseline Freeze

- Re-run `flutter analyze`.
- Re-run full Flutter tests.
- Record exact Flutter SDK, Dart SDK, dependency versions, and platform toolchain versions.
- Capture fixture files that prove Swift-to-Flutter parse/serialize compatibility.
- Define the parity acceptance checklist as blocking release criteria.

### Phase 1: File Access and Offline Guarantees

- Implement a formal file-access abstraction instead of direct path handling throughout UI/controller code.
- macOS:
  - Match Swift security-scoped bookmark behavior as closely as Flutter allows.
  - Persist permission tokens, not only raw paths, where possible.
  - Validate reopen-after-relaunch from arbitrary user folders.
- iOS/iPadOS:
  - Validate document picker lifecycle.
  - Confirm edit-in-place behavior for local documents.
  - Confirm whether external provider documents are allowed or should be excluded for "local-only" mode.
- Windows/Linux:
  - Validate open/save/reopen paths.
  - Confirm behavior with removable drives and permission-denied paths.
- Android:
  - Validate Storage Access Framework behavior.
  - Confirm persisted URI permissions if using document providers.
- Add a visible offline/local-only mode policy:
  - No background network calls.
  - No telemetry.
  - No cloud sync prompts.
  - External links open only after explicit user action.

### Phase 2: Parity Smoke Testing

- Test create/open/save/reopen board on every target OS.
- Test import Trello JSON on every target OS.
- Test session restore after app restart.
- Test board-adjacent todo file creation, save, delete, and merge behavior.
- Test moving/copying cards across multiple open boards.
- Test drag/drop reorder in columns and across columns.
- Test filters and cross-board filters.
- Test card editor save behavior under rapid editing.
- Test app behavior with malformed Markdown, malformed JSON, missing files, renamed files, and permission-denied paths.

### Phase 3: Production Hardening

- Add autosave failure recovery and clearer user-facing save errors.
- Add atomic writes for Markdown and todo files.
- Add optional backup-before-save or rolling local backup snapshots.
- Add file corruption detection and repair prompts.
- Add "Save As" and "Reveal in Finder/File Manager" commands where platform-appropriate.
- Add explicit confirmation before destructive actions:
  - Delete column.
  - Delete card.
  - Delete todo companion file.
  - Overwrite imported board destination.
- Add crash/error logs that stay local and are easy for users to inspect.

### Phase 4: Security and Privacy Completion

- Implement threat model decisions listed in the security audit section.
- Choose an encryption model for boards and/or cards.
- Add password handling rules:
  - Never store raw passwords.
  - Use strong key derivation.
  - Use authenticated encryption.
  - Support local-only password reset expectations: if the password is lost, data cannot be recovered.
- Add secure memory and clipboard guidance where feasible.
- Add tests for encrypted file round trips and wrong-password failure behavior.
- Add dependency/license/security review before release.

### Phase 5: Release Readiness

- Package signed builds where applicable.
- Verify app sandbox entitlements.
- Verify all file permissions survive relaunch as expected.
- Produce release notes documenting:
  - Supported platforms.
  - Offline behavior.
  - File format compatibility.
  - Known limitations.
  - Encryption/password protection status.

## Tiered Enhancements

### Tier 1: Low-Risk, High-Value Enhancements

- Improve Markdown output readability while preserving parser compatibility.
- Add checklist progress indicators on cards.
- Add todo count and overdue todo badges on cards.
- Add a board footer showing active Markdown path and todo companion path.
- Add confirmation before deleting board todo files.
- Add "clear completed todos" action.
- Add quick label chips in the toolbar.
- Add fast card search within the active board.
- Add keyboard shortcuts for archive, new card, new column, search, and close board.
- Add drag/drop destination highlighting and insertion markers.
- Add a missing-file recovery dialog for session restore.
- Add local crash log viewer.

### Tier 2: Medium Complexity Enhancements

- Column drag/drop reordering.
- Column sorting modes:
  - Priority.
  - Due date.
  - Title.
  - Manual order.
- Saved filters and filter presets.
- Cross-board search.
- Board templates.
- Card templates.
- Markdown preview for card notes.
- Duplicate board.
- Export board to Markdown bundle.
- Export filtered cards.
- Per-board appearance settings.
- Local backup snapshots before save.
- Attachment manifest format for local files.
- Image attachment previews.

### Tier 3: Larger Product Features

- Card-level file attachments.
- Image attachment storage, preview, and optional inline Markdown rendering.
- Board-level and card-level encryption/password protection.
- Local encrypted archive export/import.
- Local full-text search index.
- Conflict detection for boards edited by another app while Kanoli is open.
- Git-friendly change summaries.
- Multi-window desktop support.
- Print/export to PDF.
- Calendar view for due dates.
- Timeline view.
- Local plugin/action system.

### Tier 4: Optional Future Features That Must Not Break Offline-First

- Optional local network sync.
- Optional Git sync wrapper.
- Optional cloud-folder compatibility guidance for iCloud Drive, Dropbox, Syncthing, or similar user-managed folders.
- Optional remote collaboration only if it is strictly opt-in and isolated from the default local-only experience.

## Security Audit

### Security Goals

- Kanoli must be usable without internet access.
- User board data should remain in user-selected local files.
- The app should not transmit board contents, paths, labels, notes, todos, or metadata.
- The app should minimize sensitive data stored outside board files.
- Destructive file actions should be intentional and recoverable when practical.
- Encrypted/password-protected data should fail closed when credentials are wrong or missing.

### Threat Model

Primary assets:

- Board Markdown files.
- Todo companion files.
- Imported Trello/Kanoli JSON files.
- Attachments/images once implemented.
- Session metadata containing recently opened file paths.
- Local crash/error logs.
- Future encryption keys and password-derived keys.

Likely threats:

- Accidental data loss from save errors, overwrite, delete, or parser bugs.
- Unauthorized local access to board files on a shared machine.
- Sensitive path leakage through logs/preferences.
- Opening malicious or malformed Markdown/JSON files.
- External URL abuse from links embedded in notes.
- Dependency or plugin behavior that introduces network calls.
- Weak encryption design that gives users a false sense of protection.
- Platform permission mismatch that prevents users from reopening documents.

Out of scope unless explicitly added later:

- Defending against a fully compromised operating system.
- Remote account compromise, because there should be no required account.
- Server breach, because there should be no Kanoli server in the offline-first product.

### Current Security Observations

- The app currently uses local files and local preferences; this is aligned with offline-first goals.
- The Flutter dependencies are modest: Flutter SDK, `file_selector`, `path_provider`, `shared_preferences`, and `url_launcher`.
- The only obvious network-adjacent dependency behavior is opening user-clicked links through `url_launcher`.
- Session restore currently stores local file paths in preferences. This is useful but can reveal project names or folder structures to anyone with local profile access.
- Markdown and todo writes are currently straightforward file writes. Atomic write behavior and backups should be added before release.
- JSON import parses local files. Malformed input is handled, but import should be fuzzed and size-limited to avoid UI hangs or memory pressure.
- Todo deletion exists and should be guarded by explicit confirmation.
- Crash/error logging currently emits debug logs; production behavior should avoid storing card text, note contents, full board contents, or sensitive paths unless the user explicitly exports a report.
- No encryption/password protection is currently implemented.

### Offline-First Requirements

Required:

- App launch must not require network.
- Board create/open/save/import must not require network.
- Session restore must not require network.
- Help/error flows must not require network.
- Default logging must stay local.
- No telemetry, analytics, remote config, update ping, or crash upload by default.
- Links inside notes may be displayed, but opening them must require explicit user action.

Recommended controls:

- Add a "Local Documents Only" security mode, enabled by default.
- Add a network policy test that fails if HTTP clients or analytics packages are introduced without review.
- Keep `url_launcher` isolated behind a user-action-only external-link service.
- Document that cloud folders are user-managed local filesystem locations, not Kanoli cloud sync.

### File I/O and Data Integrity Audit

Risks:

- Partial writes can corrupt board files if the app crashes mid-save.
- Concurrent edits from another editor can be overwritten.
- Missing permissions can produce silent save failures if errors are not surfaced.
- Board and todo files can drift if one saves and the other fails.

Required mitigations:

- Use atomic write strategy:
  - Write to temporary file in same directory.
  - Flush.
  - Replace original.
  - Keep a recoverable backup on failure.
- Add optional rolling backups:
  - `.kanoli-backups/BoardName.timestamp.md`
  - Retention limit by count or age.
- Detect external modification:
  - Track last known modified time and file size/hash.
  - Warn before overwriting changed files.
- Validate after save:
  - Re-parse saved Markdown.
  - Confirm expected card IDs are present.
- Preserve todo unrelated lines exactly.
- Confirm before deleting todo files.

### Parser and Import Audit

Risks:

- Malformed files could crash parsing or produce unexpected data loss.
- Extremely large JSON/Markdown files could freeze the UI.
- Trello imports may contain unexpected nested data, HTML, URLs, or very long strings.

Required mitigations:

- Keep parsers pure and well-tested.
- Add max file size warning before import/open.
- Add string length caps for titles, labels, notes, and checklist items at UI boundaries.
- Keep unknown Trello fields ignored, not executed or rendered as code.
- Escape or treat imported text as inert text.
- Add golden tests for known legacy formats.
- Add fuzz-style tests for malformed headings, metadata tokens, dates, UUIDs, and checklist lines.

### Local Storage and Privacy Audit

Risks:

- File paths in preferences can reveal project/client names.
- Recent board lists can reveal sensitive work.
- Logs can accidentally include paths or card content.

Required mitigations:

- Add privacy setting: "Remember open boards on launch".
- Add "Clear recent/session data".
- Store display names separately from full paths where possible.
- Avoid logging note/card/todo contents.
- Redact paths in production logs unless user opts into diagnostics.
- Keep all diagnostics local.

### Dependency and Build Audit

Required checks:

- Lock dependency versions.
- Review transitive dependencies before release.
- Confirm no dependency performs background network activity.
- Generate license inventory.
- Run static analysis.
- Run tests on release mode builds.
- Review platform entitlements:
  - macOS sandbox file access.
  - iOS document access.
  - Android storage permissions.
  - Windows/Linux filesystem access.

### UI Security Audit

Risks:

- Users may not realize when a link leaves the local app.
- Destructive actions can be too easy.
- Password/encryption UI can imply recoverability when none exists.

Required mitigations:

- External links should show destination and require a direct click/tap.
- Add confirmation for destructive file actions.
- Add clear wrong-password handling with no data overwrite.
- Explain encryption recovery limits in password setup UI.
- Never auto-fill or display passwords after setup.

## Encryption and Password Protection Options

### Option A: Board-Level Encrypted File

Encrypt the entire board file as one protected document.

Possible format:

- Plain board: `Project.md`
- Encrypted board: `Project.kanoli`
- Internals:
  - Magic header/version.
  - Salt.
  - KDF parameters.
  - Nonce.
  - Authenticated ciphertext of the Markdown payload.

Recommended cryptography:

- Key derivation: Argon2id preferred; PBKDF2-HMAC-SHA256 acceptable if Argon2id is not available on all targets.
- Encryption: XChaCha20-Poly1305 or AES-256-GCM.
- Authentication: built into AEAD mode.

Pros:

- Strongest privacy for board contents.
- Hides titles, labels, due dates, notes, checklists, and card IDs.
- Simplest mental model: unlock the board to use it.
- Works well for board-level backups and export/import.

Cons:

- Not human-readable while locked.
- Git diffs become opaque.
- Search/indexing cannot work until unlocked.
- Todo companion and attachments need their own protection or must be included in an encrypted bundle.

Best use:

- Sensitive boards where privacy matters more than plain-text portability.

Recommendation:

- Make this the first encryption feature if encryption is added. It has the cleanest security boundary.

### Option B: Board Bundle Encryption

Protect the board, todo companion file, and attachments as one encrypted local bundle.

Possible format:

- `Project.kanolibundle`
- Bundle contains encrypted:
  - `board.md`
  - `board.todo.txt`
  - `attachments/`
  - `manifest.json`

Pros:

- Protects all board-related local documents together.
- Avoids leaking attachment filenames if manifest and filenames are encrypted.
- Easier to move, back up, and import as one unit.

Cons:

- More implementation work.
- Needs careful atomic save behavior for a multi-file package.
- Less compatible with ordinary Markdown editors.

Best use:

- Full privacy mode with attachments/images.

Recommendation:

- Target this after attachments exist, or design attachments now with this future bundle in mind.

### Option C: Card-Level Encryption Inside Plain Markdown

Encrypt only selected cards while leaving the board file mostly readable.

Possible Markdown shape:

```markdown
## Locked Card id:<UUID> encrypted:v1
> encrypted-card:...
```

Pros:

- Most of the board can remain plain Markdown.
- Users can protect only sensitive cards.
- Less disruptive for mixed-sensitivity boards.
- Git diffs remain useful for unlocked cards.

Cons:

- Metadata leakage is hard to avoid.
- Column name, card order, placeholder title, modified time, labels, or due dates may still leak unless also encrypted.
- Searching/filtering locked cards is limited unless metadata remains plaintext.
- More complicated UX: some cards are locked, some are not.
- Easy to accidentally leak sensitive text through card titles or labels.

Best use:

- Personal boards with a few sensitive notes.

Recommendation:

- Implement only after board-level encryption, and present it as "private card contents" rather than full card anonymity unless metadata is also encrypted.

### Option D: Password-Locked Cards Without Encryption

Gate card display behind an app password, but store card text in plaintext.

Pros:

- Easy to implement.
- Keeps Markdown readable.
- Useful as a casual privacy screen.

Cons:

- Not real security.
- Anyone opening the file outside Kanoli can read the card.
- Can mislead users.

Best use:

- Avoid for security claims. Only acceptable if labeled clearly as "hide in app" or "privacy screen".

Recommendation:

- Do not present this as password protection. If implemented, name it "Hide card in Kanoli" and explain that it does not encrypt the file.

### Option E: OS-Keychain-Protected Board Keys

Generate a random board key and store it in the OS keychain, optionally protected by biometrics or device auth.

Pros:

- Smooth user experience.
- Avoids users typing passwords every time.
- Can pair with board-level encryption.

Cons:

- Portability is harder because the key lives on one device.
- Backup and migration need a recovery/export story.
- Behavior differs across macOS, iOS, Windows, Linux, and Android.

Best use:

- "Remember password on this device" option after password-based encryption exists.

Recommendation:

- Treat as a convenience layer, not the primary recovery mechanism.

## Recommended Encryption Strategy

### First Release

Implement board-level encryption with password-derived keys.

Minimum requirements:

- New encrypted file extension, e.g. `.kanoli`.
- Strong KDF with per-file salt.
- Authenticated encryption.
- Wrong password never modifies the file.
- Autosave writes atomically.
- No plaintext temp files outside controlled, immediately deleted locations.
- Clear warning: lost passwords cannot be recovered.
- No password storage by default.

### Second Release

Add encrypted board bundles once attachments exist.

Minimum requirements:

- Board, todo file, attachments, and manifest protected together.
- Attachment names and metadata encrypted where possible.
- Atomic bundle update or recoverable transaction log.

### Third Release

Add optional card-level encrypted sections.

Minimum requirements:

- Clear metadata leakage warning.
- Ability to encrypt title/labels/due date or intentionally leave them searchable.
- Locked-card placeholder UI.
- Batch unlock for active session.

## Acceptance Criteria for "100% Offline With Local Documents"

- Fresh install can create, open, edit, save, close, and reopen a board with no network.
- App remains usable with network disabled.
- Tests confirm no required HTTP/API call in core workflows.
- All user data is stored in user-selected local documents or local app preferences.
- Preferences contain only session metadata, not board contents.
- External links open only after direct user action.
- Import reads local JSON only.
- Crash/error reporting is local only.
- Encryption/password protection works locally without accounts or servers.
- Documentation clearly explains where data lives.

## Immediate Next Actions

1. Re-run Flutter analyze/test and update signoff docs with current results.
2. Validate macOS file reopen behavior after relaunch using user-selected folders.
3. Decide whether `shared_preferences` path restore is acceptable per platform or must be replaced by platform permission handles.
4. Add atomic write and local backup strategy before expanding features.
5. Add explicit offline/security policy to the app and README.
6. Pick encryption package/implementation after confirming cross-platform support for AEAD and key derivation.
7. Implement board-level encryption before card-level encryption.
8. Add confirmations for destructive file actions.
9. Build smoke-test scripts/checklists for all five target platforms.
10. Keep enhancement work behind parity/security stabilization so the port does not drift from the Swift reference.
