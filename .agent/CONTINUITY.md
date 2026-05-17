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

- 2026-05-11T02:13:26Z [TOOL] Read `AGENTS.md`; `.agent/CONTINUITY.md` was missing and created.
- 2026-05-11T02:35:00Z [CODE] Split Markdown persistence into facade/parser/parser helpers/serializer modules, moved board formatters into `board_formatters.dart`, and added `BoardItem.bodyMarkdown`.
- 2026-05-11T02:35:00Z [CODE] Updated roadmap board with a Markdown v2.1 tracking card and selective body prose on active roadmap cards.

## [DISCOVERIES]

- 2026-05-11T02:13:26Z [TOOL] Pre-refactor line counts: `markdown_board_store.dart` 668, `board_entities.dart` 322, `markdown_board_store_test.dart` 299.
- 2026-05-11T02:58:00Z [TOOL] Final touched-code line counts are under 300 LOC: parser helpers 295, board entities 269, store test 298, body test 135.

## [OUTCOMES]

- 2026-05-11T02:58:00Z [CODE] Markdown v2.1 implemented: parser/serializer preserve optional `BoardItem.bodyMarkdown`, legacy compact/current v2 reads remain compatible, and the roadmap board now uses selective body prose.
- 2026-05-11T02:58:00Z [TOOL] Verification passed: `dart format`, `flutter analyze`, full `flutter test`, and targeted roadmap body parser test.
- 2026-05-11T03:42:00Z [CODE] Added concise human-facing file summaries to all Dart source/test files and section comments around major app, persistence, controller, and editor flows.
- 2026-05-11T03:42:00Z [TOOL] Comment pass verification passed: `dart format lib test`, `flutter analyze`, and full `flutter test`.
