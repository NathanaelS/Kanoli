# Current State
## (A) Confirm macOS-first Phase 3 baseline +docs +phase3 +release id:11111111-1111-4111-8111-111111111111
> note:2026-05-10T12:00:00-07:00 KanoliDart is the active Flutter rebuild. Core feature parity is complete, Phase 2 macOS smoke passed, and Phase 3 macOS hardening is signed off.
> checklist:11111111-1111-4111-8111-111111111112 Baseline evidence
> checklist-item:11111111-1111-4111-8111-111111111112:[x] flutter analyze passes
> checklist-item:11111111-1111-4111-8111-111111111112:[x] flutter test passes
> checklist-item:11111111-1111-4111-8111-111111111112:[x] Both KanoliDart and KanoliSwift git statuses are clean
> checklist-item:11111111-1111-4111-8111-111111111112:[x] Reconcile stale docs that still say Phase 3 is in progress

## (B) Preserve current local-first data contract +markdown +todo +compatibility id:11111111-1111-4111-8111-111111111113
> note:2026-05-10T12:00:00-07:00 Keep Markdown and companion todo.txt files as the source of truth while expanding features.
> checklist:11111111-1111-4111-8111-111111111114 Compatibility guardrails
> checklist-item:11111111-1111-4111-8111-111111111114:[x] Columns remain Markdown # headings
> checklist-item:11111111-1111-4111-8111-111111111114:[x] Cards remain Markdown ## headings with metadata
> checklist-item:11111111-1111-4111-8111-111111111114:[x] Todo items remain card-scoped with card:<UUID>
> checklist-item:11111111-1111-4111-8111-111111111114:[ ] Any new feature must round-trip safely through Markdown

# Next Up
## (A) Reconcile roadmap and hardening documentation +docs +phase3 id:22222222-2222-4222-8222-222222222221
> note:2026-05-10T12:00:00-07:00 PHASE3_SIGNOFF says Phase 3 is complete, but the production hardening plan/checklist still contain older in-progress language and unchecked exit rows.
> checklist:22222222-2222-4222-8222-222222222222 Doc cleanup
> checklist-item:22222222-2222-4222-8222-222222222222:[x] Update Phase 3 plan status to signed off
> checklist-item:22222222-2222-4222-8222-222222222222:[x] Resolve unchecked hardening checklist exit criteria or explain accepted limitations
> checklist-item:22222222-2222-4222-8222-222222222222:[x] Replace old KanoliDartBuild paths with current KanoliDart paths where appropriate

## (A) Finish macOS release readiness +macos +release +packaging id:22222222-2222-4222-8222-222222222223
> note:2026-05-10T12:00:00-07:00 A macOS .dmg artifact exists. The remaining work is distribution polish, signing/notarization, and installer QA.
> checklist:22222222-2222-4222-8222-222222222224 Release checklist
> checklist-item:22222222-2222-4222-8222-222222222224:[ ] Confirm build artifact version and release naming
> checklist-item:22222222-2222-4222-8222-222222222224:[ ] Add signing and notarization workflow notes
> checklist-item:22222222-2222-4222-8222-222222222224:[ ] Smoke install on a clean macOS user profile
> checklist-item:22222222-2222-4222-8222-222222222224:[ ] Prepare public release notes

## (B) Run cross-platform smoke matrix +windows +linux +ios +android id:22222222-2222-4222-8222-222222222225
> note:2026-05-10T12:00:00-07:00 Flutter targets are enabled, but Windows, Linux, iOS, and Android smoke coverage was explicitly deferred.
> checklist:22222222-2222-4222-8222-222222222226 Platform smoke
> checklist-item:22222222-2222-4222-8222-222222222226:[ ] Windows create/open/import/relaunch
> checklist-item:22222222-2222-4222-8222-222222222226:[ ] Linux create/open/import/relaunch
> checklist-item:22222222-2222-4222-8222-222222222226:[ ] iOS document picker lifecycle
> checklist-item:22222222-2222-4222-8222-222222222226:[ ] Android Storage Access Framework lifecycle
> checklist-item:22222222-2222-4222-8222-222222222226:[ ] Permission-denied and malformed-file cases per platform

# Quick Wins
## (B) Add fast card search +search +ux id:33333333-3333-4333-8333-333333333331
> note:2026-05-10T12:00:00-07:00 High-value usability feature with low persistence risk because cards are already loaded in memory.
> checklist:33333333-3333-4333-8333-333333333332 Implementation sketch
> checklist-item:33333333-3333-4333-8333-333333333332:[ ] Search title, labels, notes, checklist text, and todo text
> checklist-item:33333333-3333-4333-8333-333333333332:[ ] Support current-board and all-open-boards modes
> checklist-item:33333333-3333-4333-8333-333333333332:[ ] Add focused widget/controller tests

## (B) Show checklist and todo counts on cards +cards +ux id:33333333-3333-4333-8333-333333333333
> note:2026-05-10T12:00:00-07:00 Existing card data already includes checklists and todo sidecar items, so this is mostly card tile UI.
> checklist:33333333-3333-4333-8333-333333333334 Display states
> checklist-item:33333333-3333-4333-8333-333333333334:[ ] Checklist complete/total count
> checklist-item:33333333-3333-4333-8333-333333333334:[ ] Todo open/completed count
> checklist-item:33333333-3333-4333-8333-333333333334:[ ] Overdue indicator if due dates exist

## (C) Add clear completed todos action +todo +workflow id:33333333-3333-4333-8333-333333333335
> note:2026-05-10T12:00:00-07:00 Todo completion state already exists. This should include a confirmation prompt and preserve unrelated todo.txt lines.
> checklist:33333333-3333-4333-8333-333333333336 Safety criteria
> checklist-item:33333333-3333-4333-8333-333333333336:[ ] Confirm before deleting completed todos
> checklist-item:33333333-3333-4333-8333-333333333336:[ ] Preserve unrelated lines and spacing where possible
> checklist-item:33333333-3333-4333-8333-333333333336:[ ] Test merge behavior against todo sidecar fixtures

## (C) Add archive keyboard/menu command +archive +workflow id:33333333-3333-4333-8333-333333333337
> note:2026-05-10T12:00:00-07:00 Archive behavior already exists; this card is about exposing it as a faster command.
> checklist:33333333-3333-4333-8333-333333333338 Command surface
> checklist-item:33333333-3333-4333-8333-333333333338:[ ] Add shortcut/menu entry for Move to Archive
> checklist-item:33333333-3333-4333-8333-333333333338:[ ] Ensure selected-card context is clear
> checklist-item:33333333-3333-4333-8333-333333333338:[ ] Confirm behavior with Archive column auto-create

# Mermaid Integration
## (B) Preserve Mermaid fenced code blocks in notes +mermaid +markdown id:44444444-4444-4444-8444-444444444441
> note:2026-05-10T12:00:00-07:00 First Mermaid step: allow users to store Mermaid source in Kanoli Markdown without rendering it yet.
> note:2026-05-10T12:00:00-07:00 Example source: ```mermaid flowchart TD; Idea-->Build; Build-->Ship; ```
> checklist:44444444-4444-4444-8444-444444444442 Markdown handling
> checklist-item:44444444-4444-4444-8444-444444444442:[ ] Decide whether Mermaid belongs in notes, card body text, or a new diagram block type
> checklist-item:44444444-4444-4444-8444-444444444442:[ ] Preserve fenced blocks without mangling line breaks
> checklist-item:44444444-4444-4444-8444-444444444442:[ ] Add parse/serialize tests for fenced Mermaid content

## (B) Detect and label Mermaid blocks in the card editor +mermaid +ux id:44444444-4444-4444-8444-444444444443
> note:2026-05-10T12:00:00-07:00 Before rendering diagrams, Kanoli can still improve editing by recognizing Mermaid blocks and showing them as diagram source.
> checklist:44444444-4444-4444-8444-444444444444 Editor polish
> checklist-item:44444444-4444-4444-8444-444444444444:[ ] Add simple Mermaid block detection
> checklist-item:44444444-4444-4444-8444-444444444444:[ ] Add a compact Diagram label or icon
> checklist-item:44444444-4444-4444-8444-444444444444:[ ] Keep raw source editable

## (A) Prototype rendered Mermaid preview +mermaid +prototype id:44444444-4444-4444-8444-444444444445
> note:2026-05-10T12:00:00-07:00 Mermaid rendering likely needs a WebView/JS or export pipeline decision. Keep this as a prototype until storage and security rules are clear.
> checklist:44444444-4444-4444-8444-444444444446 Prototype questions
> checklist-item:44444444-4444-4444-8444-444444444446:[ ] Compare Flutter WebView rendering vs external export pipeline
> checklist-item:44444444-4444-4444-8444-444444444446:[ ] Confirm offline behavior
> checklist-item:44444444-4444-4444-8444-444444444446:[ ] Validate sanitization and local-file safety
> checklist-item:44444444-4444-4444-8444-444444444446:[ ] Decide if previews are cached or generated on demand

## (C) Generate board relationship diagrams from Kanoli data +mermaid +automation id:44444444-4444-4444-8444-444444444447
> note:2026-05-10T12:00:00-07:00 Longer-term Mermaid feature: generate flowcharts from columns, cards, labels, due-date risk, or project workflow structure.
> checklist:44444444-4444-4444-8444-444444444448 Generation ideas
> checklist-item:44444444-4444-4444-8444-444444444448:[ ] Column flow diagram
> checklist-item:44444444-4444-4444-8444-444444444448:[ ] Label dependency diagram
> checklist-item:44444444-4444-4444-8444-444444444448:[ ] Release workflow timeline

# Long Term
## (A) Add card attachments and image previews +attachments +media id:55555555-5555-4555-8555-555555555551
> note:2026-05-10T12:00:00-07:00 Large feature because it needs file reference policy, missing-file recovery, Markdown conventions, and preview UI.
> checklist:55555555-5555-4555-8555-555555555552 Design decisions
> checklist-item:55555555-5555-4555-8555-555555555552:[ ] Link vs copy attachment files
> checklist-item:55555555-5555-4555-8555-555555555552:[ ] Define Markdown storage format
> checklist-item:55555555-5555-4555-8555-555555555552:[ ] Handle missing or moved attachments
> checklist-item:55555555-5555-4555-8555-555555555552:[ ] Add image preview UI

## (A) Design optional local encryption +security +phase4 id:55555555-5555-4555-8555-555555555553
> note:2026-05-10T12:00:00-07:00 Security-sensitive roadmap item. Needs a threat model, recovery story, key handling, and cross-platform behavior.
> checklist:55555555-5555-4555-8555-555555555554 Security planning
> checklist-item:55555555-5555-4555-8555-555555555554:[ ] Define what encryption protects and does not protect
> checklist-item:55555555-5555-4555-8555-555555555554:[ ] Choose file format and migration story
> checklist-item:55555555-5555-4555-8555-555555555554:[ ] Decide password/key recovery behavior
> checklist-item:55555555-5555-4555-8555-555555555554:[ ] Add tests for locked/corrupt/wrong-password cases

## (B) Build full cross-platform release process +release +platforms id:55555555-5555-4555-8555-555555555555
> note:2026-05-10T12:00:00-07:00 Beyond smoke testing, each platform needs packaging, signing, permissions, and install/update QA.
> checklist:55555555-5555-4555-8555-555555555556 Release channels
> checklist-item:55555555-5555-4555-8555-555555555556:[ ] macOS signed/notarized DMG
> checklist-item:55555555-5555-4555-8555-555555555556:[ ] Windows installer or portable package
> checklist-item:55555555-5555-4555-8555-555555555556:[ ] Linux package format decision
> checklist-item:55555555-5555-4555-8555-555555555556:[ ] Android build/distribution decision
> checklist-item:55555555-5555-4555-8555-555555555556:[ ] iOS signing/TestFlight/App Store path decision

## (C) Explore plugin or automation layer +plugins +automation id:55555555-5555-4555-8555-555555555557
> note:2026-05-10T12:00:00-07:00 Powerful but architecture-shaping. This should wait until the local-first safety model is more mature.
> checklist:55555555-5555-4555-8555-555555555558 Architecture questions
> checklist-item:55555555-5555-4555-8555-555555555558:[ ] Define what plugins can read/write
> checklist-item:55555555-5555-4555-8555-555555555558:[ ] Keep all automation local-first by default
> checklist-item:55555555-5555-4555-8555-555555555558:[ ] Add permission boundaries and recovery behavior
