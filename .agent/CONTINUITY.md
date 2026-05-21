# Continuity

## [PLANS]

- 2026-05-11T02:13:26Z [USER] Implement Markdown v2.1 preferred card shape on `dev`: optional human-authored card body prose, parser/serializer modularization, roadmap update, and verification.
- 2026-05-11T02:13:26Z [ASSUMPTION] Existing uncommitted Markdown v2 work is the baseline for v2.1; do not revert it.

## [DECISIONS]

- 2026-05-11T02:13:26Z [USER] `bodyMarkdown` is a storage/readability feature only; no card editor UI changes in this pass.
- 2026-05-11T02:13:26Z [USER] Readable v2.1 body prose is human-only Markdown convention, not separate status/decision schema fields.
- 2026-05-11T02:13:26Z [CODE] `AGENTS.md` requires touched code files to stay under 300 lines and continuity to be maintained in `.agent/CONTINUITY.md`.
- 2026-05-11T03:26:00Z [USER] Human comments do not count toward the 300 LOC code limit; keep comments concise and avoid unnecessary paragraphs.

## [PROGRESS]

- 2026-05-21T10:06:05-0700 [TOOL] Used local `gh` with `project` scope to configure existing GitHub Project `NathanaelS/Kanoli` project #1, link it to the repo, add issues #3-#21, and populate Project v2 fields.
- 2026-05-21T09:37:39-0700 [TOOL] Migrated active `Kanoli_Roadmap_Board.md` cards to GitHub issues in `NathanaelS/Kanoli` as issues #3-#21; skipped roadmap cards already fully implemented/completed except the archived macOS beta card with an open clean-profile smoke check.
- 2026-05-21T09:20:06-0700 [CODE] Updated README repository links to `NathanaelS/Kanoli` and added GitHub tracking docs/templates under `.github/`.
- 2026-05-11T02:13:26Z [TOOL] Read `AGENTS.md`; `.agent/CONTINUITY.md` was missing and created.
- 2026-05-11T02:35:00Z [CODE] Split Markdown persistence into facade/parser/parser helpers/serializer modules, moved board formatters into `board_formatters.dart`, and added `BoardItem.bodyMarkdown`.
- 2026-05-11T02:35:00Z [CODE] Updated roadmap board with a Markdown v2.1 tracking card and selective body prose on active roadmap cards.
- 2026-05-18T20:16:18Z [CODE] Added repo-root `.gitignore` entries for `.vs/`, `kanoli_flutter/windows/out/`, and `kanoli_flutter/.kanoli_backups/` to prevent Visual Studio cache/CMake output/local backup artifacts from being offered for commit.
- 2026-05-18T20:23:05Z [CODE] Added repo-root `.gitattributes` to normalize text files to LF and mark common binary/media/archive/database files as binary.

## [DISCOVERIES]

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
