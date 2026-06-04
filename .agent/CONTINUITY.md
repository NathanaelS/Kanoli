# Continuity

## [PLANS]

- 2026-05-25T21:19:34Z [TOOL] Corrected macOS `0.7.0` notarization submission `451d52aa-f3ee-45ea-b91d-ab1f18a7af39` is processing at Apple; once `Accepted`, staple and validate `kanoli_flutter/dist/Kanoli-0.7.0.dmg` before distribution.
- 2026-05-25T20:13:53Z [TOOL] Final macOS `0.7.0` distribution gate is Apple notarization and stapling; signed DMG submission is blocked until a `notarytool` Keychain profile named `KanoliNotary` is stored.
- 2026-05-11T02:13:26Z [USER] Implement Markdown v2.1 preferred card shape on `dev`: optional human-authored card body prose, parser/serializer modularization, roadmap update, and verification.
- 2026-05-11T02:13:26Z [ASSUMPTION] Existing uncommitted Markdown v2 work is the baseline for v2.1; do not revert it.

## [DECISIONS]

- 2026-05-11T02:13:26Z [USER] `bodyMarkdown` is a storage/readability feature only; no card editor UI changes in this pass.
- 2026-05-11T02:13:26Z [USER] Readable v2.1 body prose is human-only Markdown convention, not separate status/decision schema fields.
- 2026-05-11T02:13:26Z [CODE] `AGENTS.md` requires touched code files to stay under 300 lines and continuity to be maintained in `.agent/CONTINUITY.md`.
- 2026-05-11T03:26:00Z [USER] Human comments do not count toward the 300 LOC code limit; keep comments concise and avoid unnecessary paragraphs.
- 2026-05-24T23:00:05Z [CODE] macOS board-tab behavior is now owned by the Flutter View menu and board tab row; native AppKit window tabbing remains disabled so no second native tab strip can appear.
- 2026-05-25T20:13:53Z [USER] Supersedes the unsigned public beta distribution decision: proceed with official macOS Developer ID signing for the next DMG release.
- 2026-05-25T20:13:53Z [CODE] macOS release identity is `app.kanoli.Kanoli`; Release distribution uses Developer ID Application signing with hardened runtime enabled and without injected development entitlements.

## [PROGRESS]

- 2026-06-01T00:13:51Z [CODE] Added fast-search scope selection for current board vs all open boards; all-open-board results carry board/tab context and selection switches to the source tab before opening the existing card editor.
- 2026-05-31T23:32:58Z [CODE] Enhanced fast card search palette guidance with inline example criteria and extended matching to support `+label` and `due:YYYY-MM-DD`/date queries.
- 2026-05-31T23:26:07Z [CODE] Fixed Cmd+P fast card search invocation on macOS by adding a native Flutter `PlatformMenuItem` shortcut (`Edit > Search Cards`) and guarding against duplicate palette dialogs.
- 2026-05-31T23:16:54Z [CODE] Implemented active-board Cmd+P fast card search in Flutter: pure search over title/labels/body-notes/checklists/todo text, read-only todo sidecar text grouping, palette UI with keyboard navigation, and workspace shortcut routing to the existing item editor.
- 2026-05-26T21:31:40Z [CODE] Added overdue notifications across the Flutter board and item editor: cards now distinguish overdue card due dates from overdue todo.txt items using separate warnings on the board face and in `item_editor_sheet.dart`, backed by lightweight `isOverdue` helpers and overdue todo counting in `todo_board_store.dart`.
- 2026-05-26T13:53:22Z [TOOL] Created GitHub issue `#23` (`Task: Avoid synchronous todo sidecar reads during board rebuilds`) to track the known UI-path file I/O risk introduced by card-face todo counts.
- 2026-05-26T09:26:00Z [CODE] Added card-face checklist and todo progress counts in `kanoli_flutter/lib/features/board/presentation/board_workspace_page.dart`, using `BoardItem` checklist count getters and a new `TodoBoardStore.countsByCardId()` helper so the board reads sidecar todo counts once per rebuild without changing editor flow or board serialization.
- 2026-05-26T02:47:18Z [CODE] Updated `kanoli_flutter/lib/features/board/presentation/board_workspace_page.dart` for Swift-parity action affordances: non-filtered column headers now use a single ellipsis menu for `Rename` and `Delete Column`, and card actions now open from an ellipsis menu grouped as move, copy, archive, and `Delete Card`.
- 2026-05-25T21:19:34Z [TOOL] First notarization submission `3d5f1ccf-e522-4fb1-9f3d-129a95e14746` was rejected because `Kanoli.app/Contents/MacOS/Kanoli` lacked a secure timestamp; re-signed the staged app with Developer ID, hardened runtime, release entitlements, and `--timestamp`, rebuilt and timestamp-signed the DMG, then submitted corrected artifact as `451d52aa-f3ee-45ea-b91d-ab1f18a7af39`.
- 2026-05-25T20:31:23Z [USER] Signed macOS installation succeeded on a separate Mac; follow-up smoke testing reached the Trello JSON import workflow.
- 2026-05-25T20:13:53Z [CODE] Advanced the macOS release build to `0.7.0+1`, aligned the app bundle identifier to `app.kanoli.Kanoli`, and configured Release for Developer ID Application signing, hardened runtime, and release-only sandbox/file-access entitlements.
- 2026-05-25T20:13:53Z [TOOL] Built and Developer ID-signed `kanoli_flutter/dist/Kanoli-0.7.0.dmg` with `KANOLI_ENV=prod`; verified DMG integrity, app deep signing, embedded framework team identity, universal binary slices, and successful launch from the mounted DMG.
- 2026-05-24T23:52:49Z [CODE] Refined archive history output so archived cards get inline body prose (`Archived at <timestamp>`) instead of a timestamp-only note heading.
- 2026-05-24T23:52:49Z [TOOL] Re-verified the archive behavior with `flutter test test/features/board/board_session_controller_test.dart` after the format tweak.
- 2026-05-24T23:40:04Z [CODE] Updated archive behavior so archiving a card inserts a timestamped `BoardNote` reading `Moved to Archive` before saving the card into the Archive column.
- 2026-05-24T23:40:04Z [TOOL] Verified the archive history entry with `flutter test test/features/board/board_session_controller_test.dart`, `flutter test test/data/markdown_board_store_test.dart test/data/markdown_board_body_test.dart`, and `flutter analyze`.
- 2026-05-24T23:00:05Z [CODE] Disabled AppKit automatic window tabbing in `MainFlutterWindow.swift`, then updated `board_workspace_page.dart` so the macOS View menu toggles Kanoli's own board tab row (`Hide Tab Bar` / `Show Tab Bar`).
- 2026-05-24T23:00:05Z [TOOL] Verification passed after the macOS tabbing/menu change: `flutter test test/features/board/board_session_controller_test.dart` and `flutter analyze`.
- 2026-05-24T11:38:27-0700 [TOOL] Created GitHub milestones for the roadmap timeline and assigned issues #3-#21 to the matching delivery buckets.
- 2026-05-24T11:00:33-0700 [TOOL] Added and populated GitHub Project `Roadmap Week` values for issues #3-#21, then created a saved `Weekly Board` board view grouped into weekly columns.
- 2026-05-24T10:27:29-0700 [TOOL] Added GitHub Project date fields `Start Date` and `Target Date`, then populated issues #3-#21 around a v1 release goal of 2026-06-14.
- 2026-05-24T10:19:52-0700 [TOOL] Added GitHub Project `Timeframe` field with build-order buckets and populated `Target`/`Timeframe` for issues #3-#21 in `NathanaelS/Kanoli`.
- 2026-05-24T10:08:49-0700 [TOOL] Created GitHub labels `Feature`, `Research`, and `Task`, renamed default `bug` to `Bug`, and applied title-prefix labels to roadmap issues #3-#21 in `NathanaelS/Kanoli`.
- 2026-05-21T10:06:05-0700 [TOOL] Used local `gh` with `project` scope to configure existing GitHub Project `NathanaelS/Kanoli` project #1, link it to the repo, add issues #3-#21, and populate Project v2 fields.
- 2026-05-21T09:37:39-0700 [TOOL] Migrated active `Kanoli_Roadmap_Board.md` cards to GitHub issues in `NathanaelS/Kanoli` as issues #3-#21; skipped roadmap cards already fully implemented/completed except the archived macOS beta card with an open clean-profile smoke check.
- 2026-05-21T09:20:06-0700 [CODE] Updated README repository links to `NathanaelS/Kanoli` and added GitHub tracking docs/templates under `.github/`.
- 2026-05-11T02:13:26Z [TOOL] Read `AGENTS.md`; `.agent/CONTINUITY.md` was missing and created.
- 2026-05-11T02:35:00Z [CODE] Split Markdown persistence into facade/parser/parser helpers/serializer modules, moved board formatters into `board_formatters.dart`, and added `BoardItem.bodyMarkdown`.
- 2026-05-11T02:35:00Z [CODE] Updated roadmap board with a Markdown v2.1 tracking card and selective body prose on active roadmap cards.
- 2026-05-18T20:16:18Z [CODE] Added repo-root `.gitignore` entries for `.vs/`, `kanoli_flutter/windows/out/`, and `kanoli_flutter/.kanoli_backups/` to prevent Visual Studio cache/CMake output/local backup artifacts from being offered for commit.
- 2026-05-18T20:23:05Z [CODE] Added repo-root `.gitattributes` to normalize text files to LF and mark common binary/media/archive/database files as binary.

## [DISCOVERIES]

- 2026-05-31T23:26:07Z [TOOL] Full-project `flutter analyze` now completes successfully on `feature/5-add-fast-card-search`; previous analyzer-hang discovery is superseded for this branch state.
- 2026-05-26T21:31:40Z [TOOL] Full-project `flutter analyze` still hangs at `Analyzing kanoli_flutter...` and exits with `analysis server exited with code -2` when interrupted, but targeted analysis of the four edited overdue-notification files completed successfully with no issues.
- 2026-05-26T09:26:00Z [TOOL] Full-project `flutter analyze` again stalled at `Analyzing kanoli_flutter...`; targeted analysis for `board_workspace_page.dart`, `todo_board_store.dart`, and `board_entities.dart` completed successfully with no issues.
- 2026-05-26T02:47:18Z [TOOL] Targeted validation for `board_workspace_page.dart` passes (`dart format` and `flutter analyze lib/features/board/presentation/board_workspace_page.dart`), but full-project `flutter analyze` currently hangs at `Analyzing kanoli_flutter...` and, when interrupted, reports `analysis server exited with code -2`.
- 2026-05-25T21:19:34Z [TOOL] Notarization validates the timestamp on the app executable inside a signed DMG; timestamping only the DMG is insufficient. The corrected staged app validates deeply and preserves only sandbox plus user-selected file read/write entitlements.
- 2026-05-25T20:31:23Z [TOOL] The reported JSON import "crash log" is a diagnostics export showing two handled `FormatException` failures: both selected `.json` inputs begin with `<!doctype html>` rather than JSON, so evidence does not implicate Trello decoding, Markdown persistence, or macOS file permission handling.
- 2026-05-25T20:13:53Z [TOOL] The macOS `0.6.0` clean-install failure is a pre-app `dyld` abort loading `file_selector_macos.framework`, not an import/parser/persistence failure; the shipped hardened ad-hoc bundle reproduces `mapping process and mapped file (non-platform) have different Team IDs`.
- 2026-05-25T20:13:53Z [TOOL] A temporary hardened ad-hoc copy launched only when signed with `com.apple.security.cs.disable-library-validation`; the official `0.7.0` build instead resolves the defect by signing the app and nested frameworks with Developer ID team `5Z6FYPML23`.
- 2026-05-11T02:13:26Z [TOOL] Pre-refactor line counts: `markdown_board_store.dart` 668, `board_entities.dart` 322, `markdown_board_store_test.dart` 299.
- 2026-05-11T02:58:00Z [TOOL] Final touched-code line counts are under 300 LOC: parser helpers 295, board entities 269, store test 298, body test 135.
- 2026-05-14T19:02:31Z [TOOL] Flutter environment inspection: SDK exists at `C:\Users\develop\flutter_windows_3.41.9-stable\flutter` with Flutter 3.41.9/Dart 3.11.5 metadata; raw `dart.exe --version` works, but Flutter wrapper commands hung and Git reports the SDK repo as dubious ownership from the current execution context.
- 2026-05-14T19:02:31Z [TOOL] VS Code has Dart extension `dart-code.dart-code@3.60.1` but no Flutter extension; `flutter` is not on PATH; Java 21 and Git are on PATH; Android SDK, `adb`, `sdkmanager`, Visual Studio/MSBuild/C++ compiler, CMake, and Ninja were not found in the checked default locations/PATH.
- 2026-05-14T21:56:28Z [TOOL] Re-inspection found progress: VS Code now has `dart-code.dart-code@3.134.0` and `dart-code.flutter@3.134.0`, and user settings contain `dart.flutterSdkPath` pointing to `C:\Users\develop\flutter_windows_3.41.9-stable\flutter`.
- 2026-05-14T21:56:28Z [TOOL] Remaining Flutter environment gaps: `flutter`/`dart` are still not on PATH, `flutter.bat --version` still timed out here, Git still reports dubious ownership for the Flutter SDK checkout, and Android SDK/Android Studio plus Windows native build tooling were not found in checked paths/PATH.
- 2026-05-14T22:47:31Z [TOOL] Flutter environment re-check: Git safe-directory issue for the Flutter SDK is now resolved (`git rev-parse HEAD` returned `00b0c91...`), but `flutter.bat --version` still timed out even with escalated user-cache access.
- 2026-05-14T22:47:31Z [TOOL] No additional platform tooling found: `flutter`/`dart` still absent from PATH; Android SDK/Studio and Visual Studio Build Tools remain absent from checked paths/PATH; VS Code Flutter extension and `dart.flutterSdkPath` setting remain present.
- 2026-05-15T00:04:25Z [TOOL] Flutter PATH is now fixed (`flutter.bat` and `dart.bat` resolve from `C:\Users\develop\flutter_windows_3.41.9-stable\flutter\bin`), but `flutter --version` and verbose startup still time out.
- 2026-05-15T00:04:25Z [TOOL] Flutter CLI startup blocker narrowed to tool-cache mismatch: SDK Git revision is `00b0c91...`, while `bin/cache/flutter_tools.stamp` is `"73a67bd690bacdf373d9f9debd5cda13309f1aae:"`; Flutter likely tries to rebuild `flutter_tools.snapshot` and stalls before project build.
- 2026-05-15T00:04:25Z [TOOL] Windows `.exe` build blocker remains native toolchain absence: `cmake`, `ninja`, `msbuild`, `cl`, Visual Studio 2022 Community/BuildTools, and `vswhere.exe` were not found in PATH/default install paths.
- 2026-05-16T21:15:37Z [TOOL] Environment re-check: Flutter now resolves from `C:\Users\natha\Develop\flutter\bin`, Docker CLI is installed (`Docker version 29.4.3`), and Visual Studio Community 2026 is installed at `C:\Program Files\Microsoft Visual Studio\18\Community`.
- 2026-05-16T21:15:37Z [TOOL] Remaining Windows Flutter blockers: new Flutter SDK path has Git dubious ownership for Codex sandbox user; `flutter --verbose --version` still times out; `vswhere -requires Microsoft.VisualStudio.Workload.NativeDesktop` and checks for VC Tools/CMake/Windows SDK components returned no matching VS install; VS install has MSBuild/MSVC directories but not Flutter-required workload/component registration.
- 2026-05-16T21:15:37Z [TOOL] Docker is not usable from Codex sandbox: `docker info`/`docker context ls` fail with access denied for `C:\Users\natha\.docker` and the Docker engine pipe; actual `natha` user is listed in `docker-users`, but current sandbox user is not.

## [OUTCOMES]

- 2026-06-01T00:13:51Z [TOOL] Fast-search scope validation passed: `flutter analyze`, focused search/palette/controller tests, and full `flutter test` completed successfully.
- 2026-05-31T23:32:58Z [TOOL] Search guidance/date-label enhancement validation passed: `flutter analyze`, focused search/palette tests, and full `flutter test` completed successfully.
- 2026-05-31T23:26:07Z [TOOL] Cmd+P invocation fix validation passed: `flutter analyze`, focused fast-search tests, and full `flutter test` all completed successfully.
- 2026-05-31T23:16:54Z [TOOL] Fast card search validation passed: targeted `flutter analyze` for the edited search/palette/todo/workspace files reported no issues, focused search tests passed, and full `flutter test` passed.
- 2026-05-26T21:31:40Z [CODE] Overdue notification support now distinguishes board-level overdue cards from overdue todo-list items without changing Markdown/todo.txt formats, controller flow, or editor navigation; remaining validation risk is limited to the existing full-project analyzer hang.
- 2026-05-26T13:53:22Z [TOOL] Added issue `#23` to GitHub Project `NathanaelS/Kanoli` project `1` and categorized it as `Task`, `Priority B`, `Area UI`, `Source GitHub Issue`, `Target v1.0`, `Timeframe v1.0 Polish`, `Roadmap Week: Week of Jun 7`, with `Start Date 2026-06-09`, `Target Date 2026-06-10`, and issue milestone `v1.0 Polish`.
- 2026-05-26T09:26:00Z [CODE] Card tiles now surface checklist and todo progress counts directly on the board face with a small UI-only diff; persistence, parsing formats, controller flow, and the item editor behavior remain unchanged.
- 2026-05-26T02:47:18Z [CODE] Scoped Flutter board workspace action-menu parity completed without touching controllers, models, persistence, tests, themes, platform files, or Swift sources; residual risk is limited to the unresolved full-project analyzer hang, so `flutter test` remains unverified for this pass.
- 2026-05-25T21:19:34Z [TOOL] Corrected Developer ID and secure-timestamp signed DMG is at `kanoli_flutter/dist/Kanoli-0.7.0.dmg` with pre-staple SHA-256 `f6818862044e2f05435e3d9ea7f6d03ba53cb82a7ce67b7eb4d6fca49ddf5424`; final release status remains pending Apple acceptance and stapling.
- 2026-05-25T20:13:53Z [TOOL] Signed macOS release candidate created at `kanoli_flutter/dist/Kanoli-0.7.0.dmg` (SHA-256 `476ca67607ca698a483cbdf9f9a6ccb19fdd90223a80384a7c753492196eae7c`); Gatekeeper status remains `Unnotarized Developer ID` until notarization and stapling complete.
- 2026-05-24T23:52:49Z [CODE] Archive history is now stored as readable inline Markdown prose on the card body, preserving Markdown compatibility while avoiding timestamp-only note headings.
- 2026-05-24T23:40:04Z [CODE] Archiving now leaves a readable, timestamped note in the Markdown board file without changing the existing card schema; behavior remains compatible with legacy boards and the existing notes parser/serializer.
- 2026-05-24T23:00:05Z [TOOL] Native macOS tabbing suppression completed and the Flutter board tab row now has an explicit View-menu visibility action; no changes were made to Markdown, persistence, or board serialization.
- 2026-05-24T11:38:27-0700 [TOOL] GitHub milestones now track the roadmap: `Beta Cleanup` due 2026-06-01 with 4 issues, `v1.0 Foundation` due 2026-06-07 with 4, `v1.0 Polish` due 2026-06-10 with 3, `v1.0 Release` due 2026-06-14 with 2, `Post-v1.0 Enhancements` due 2026-06-30 with 3, and `Later Roadmap` due 2026-07-31 with 3.
- 2026-05-24T11:00:33-0700 [TOOL] `Weekly Board` now shows week columns by start date: Week of May 24 has 6 items (#3, #4, #10, #12, #13, #21), Week of May 31 has 4, Week of Jun 7 has 3, Week of Jun 14 has 3, Week of Jun 28 has 1, Week of Jul 5 has 1, and Week of Jul 19 has 1.
- 2026-05-24T10:27:29-0700 [TOOL] Kanoli GitHub Project timeline now spans 2026-05-24 through 2026-07-31: beta cleanup through 2026-06-01, v1 foundation/polish through 2026-06-10, v1 release process 2026-06-11..2026-06-14, and post-v1/later work after 2026-06-15.
- 2026-05-24T10:19:52-0700 [TOOL] Roadmap Project ordering now uses `Now`, `Beta Cleanup`, `v1.0 Foundation`, `v1.0 Polish`, `Post-v1.0`, and `Later`; targets are `Beta`, `v1.0`, or `Later`.
- 2026-05-24T10:08:49-0700 [TOOL] Verified issues #3-#21 each have exactly one title-prefix GitHub label: `Task`, `Feature`, `Bug`, or `Research`.
- 2026-05-21T10:06:05-0700 [TOOL] Kanoli GitHub Project is public at `https://github.com/users/NathanaelS/projects/1` with 19 roadmap issues, custom fields Type/Priority/Platform/Area/Source/Target, default Status values, and a short project readme; `gh` does not expose saved Project view creation.
- 2026-05-21T09:37:39-0700 [TOOL] Created public-facing GitHub roadmap issues #3-#21 with source card IDs, summaries, checklists, and suggested project fields in the issue bodies; GitHub Projects v2 field assignment was not available through the connector.
- 2026-05-21T09:20:06-0700 [CODE] Added documentation-only GitHub project layout and issue forms for bug reports, feature requests, and tasks; no remote GitHub project or issue changes were made.
- 2026-05-11T02:58:00Z [CODE] Markdown v2.1 implemented: parser/serializer preserve optional `BoardItem.bodyMarkdown`, legacy compact/current v2 reads remain compatible, and the roadmap board now uses selective body prose.
- 2026-05-11T02:58:00Z [TOOL] Verification passed: `dart format`, `flutter analyze`, full `flutter test`, and targeted roadmap body parser test.
- 2026-05-11T03:42:00Z [CODE] Added concise human-facing file summaries to all Dart source/test files and section comments around major app, persistence, controller, and editor flows.
- 2026-05-11T03:42:00Z [TOOL] Comment pass verification passed: `dart format lib test`, `flutter analyze`, and full `flutter test`.
- 2026-05-14T19:02:31Z [TOOL] Flutter build readiness report completed: project has Flutter target folders and VS Code launch configs, but needs Flutter VS Code extension, PATH/safe-directory cleanup, and platform build toolchains before reliable builds.
- 2026-05-14T21:56:28Z [TOOL] Flutter environment re-check completed; editor integration improved, but reliable command-line/native builds still need PATH/Git trust/toolchain setup.
- 2026-05-14T22:47:31Z [TOOL] Latest environment check completed; Git trust improved, but Flutter wrapper startup, PATH setup, and native platform build tools remain blockers.
- 2026-05-15T00:04:25Z [TOOL] `.exe` beta build readiness check completed: PATH/Git trust improved, but Flutter tool snapshot rebuild and Windows C++ build tools must be fixed before `flutter build windows` can succeed.
- 2026-05-16T21:15:37Z [TOOL] Windows testing readiness check completed: VS/Docker were installed, but Flutter CLI startup, VS Native Desktop C++ workload/components, and Docker access from the testing runner still need resolution.
- 2026-05-18T20:16:18Z [TOOL] Ignore verification passed: `git check-ignore -v` matched the prior locked `.vsidx`, Windows CMake output, and local Kanoli backup paths; `git status` now leaves only `.gitignore`, existing generated plugin changes, `.agent/CONTINUITY.md`, and `kanoli_flutter/KanoliBoard.md` visible.
- 2026-05-18T20:23:05Z [TOOL] Line-ending verification: `git check-attr text eol` reports `text=auto eol=lf` for representative repo text files; `git diff --check` only reported that `.agent/CONTINUITY.md` working-copy CRLF will be normalized to LF when Git next touches it.
