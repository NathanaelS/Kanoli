# Current State

## Confirm macOS-first Phase 3 baseline
> kanoli:id 11111111-1111-4111-8111-111111111111
> kanoli:priority A
> kanoli:labels docs, phase3, release

_Summary: KanoliDart is the current release baseline, with macOS hardening complete._

**Status:** Baseline confirmed and documented.
**Decision:** Treat the Flutter/Dart app as the active product track while preserving Swift context for reference.

### Notes

#### 2026-05-10T12:00:00-07:00
KanoliDart is the active Flutter rebuild. Core feature parity is complete, Phase 2 macOS smoke passed, and Phase 3 macOS hardening is signed off.

### Baseline evidence
> kanoli:checklist 11111111-1111-4111-8111-111111111112
- [x] flutter analyze passes
- [x] flutter test passes
- [x] Both KanoliDart and KanoliSwift git statuses are clean
- [x] Reconcile stale docs that still say Phase 3 is in progress

## Preserve current local-first data contract
> kanoli:id 11111111-1111-4111-8111-111111111113
> kanoli:priority B
> kanoli:labels markdown, todo, compatibility

_Summary: Keep Kanoli files inspectable, editable, and durable outside the app._

**Status:** Guardrails are active.
**Compatibility:** Markdown boards and todo.txt sidecars remain the source-of-truth storage model.

### Notes

#### 2026-05-10T12:00:00-07:00
Keep Markdown and companion todo.txt files as the source of truth while expanding features.

### Compatibility guardrails
> kanoli:checklist 11111111-1111-4111-8111-111111111114
- [x] Columns remain Markdown # headings
- [x] Cards remain Markdown ## headings with metadata
- [x] Todo items remain card-scoped with card:<UUID>
- [ ] Any new feature must round-trip safely through Markdown

# Next Up

## Implement human-readable Markdown v2
> kanoli:id 66666666-6666-4666-8666-666666666661
> kanoli:priority A
> kanoli:labels markdown, compatibility

_Summary: Replace compact machine-oriented saves with a readable Markdown board format._

**Status:** Implemented as the baseline readable format.
**Compatibility:** Legacy compact Markdown remains readable and migrates to v2 on save.

### Notes

#### 2026-05-10T14:10:00-07:00
Implement readable Kanoli Markdown v2 as the default save format while keeping legacy compact Markdown readable.

### Markdown v2 rollout
> kanoli:checklist 66666666-6666-4666-8666-666666666662
- [x] Serialize clean card headings with kanoli metadata blockquote lines
- [x] Parse readable v2 notes and Markdown task-list checklists
- [x] Keep legacy compact Markdown parsing compatible
- [x] Add migration and round-trip tests

## Implement human-readable Markdown v2.1 card bodies
> kanoli:id 77777777-7777-4777-8777-777777777771
> kanoli:priority A
> kanoli:labels markdown, readability, compatibility

_Summary: Add optional human-authored body prose between card metadata and structured sections._

**Status:** Implemented and verified.
**Decision:** Body prose is Markdown text only, not new Kanoli schema fields.
**Compatibility:** Legacy compact Markdown and current readable v2 files remain readable.

### Notes

#### 2026-05-10T21:13:26-05:00
Implement v2.1 after AGENTS.md introduced continuity and code modularity rules.

### Markdown v2.1 rollout
> kanoli:checklist 77777777-7777-4777-8777-777777777772
- [x] Preserve optional bodyMarkdown in parser and serializer
- [x] Keep changed code files under 300 LOC
- [x] Add body prose tests
- [x] Verify roadmap board parses as v2.1

## Reconcile roadmap and hardening documentation
> kanoli:id 22222222-2222-4222-8222-222222222221
> kanoli:priority A
> kanoli:labels docs, phase3

_Summary: Bring the planning documents into alignment with the completed Phase 3 signoff._

**Status:** Completed.
**Decision:** Keep historical hardening records, but remove stale in-progress language where it misleads planning.

### Notes

#### 2026-05-10T12:00:00-07:00
PHASE3_SIGNOFF says Phase 3 is complete, but the production hardening plan/checklist still contain older in-progress language and unchecked exit rows.

### Doc cleanup
> kanoli:checklist 22222222-2222-4222-8222-222222222222
- [x] Update Phase 3 plan status to signed off
- [x] Resolve unchecked hardening checklist exit criteria or explain accepted limitations
- [x] Replace old KanoliDartBuild paths with current KanoliDart paths where appropriate

## Finish macOS release readiness
> kanoli:id 22222222-2222-4222-8222-222222222223
> kanoli:priority A
> kanoli:labels macos, release, packaging

_Summary: Finish the unsigned public beta release path for Kanoli 0.6.0 Beta._

**Status:** DMG built and release notes prepared; clean-profile install smoke remains open.
**Decision:** Ship the public beta unsigned, with the signed/notarized path documented as a future release upgrade.

### Notes

#### 2026-05-10T12:00:00-07:00
Target release is Kanoli 0.6.0 Beta as an unsigned public beta DMG. The signed/notarized Apple Developer ID path is documented as a future upgrade, not a blocker for this beta.

#### 2026-05-10T13:40:00-07:00
Built and verified Kanoli-0.6.0-beta.dmg. The macOS bundle reports version 0.6.0 build 1; the beta label is carried by the release name, tag, and DMG filename.

### Release checklist
> kanoli:checklist 22222222-2222-4222-8222-222222222224
- [x] Confirm build artifact version and release naming
- [x] Add signing and notarization workflow notes
- [ ] Smoke install on a clean macOS user profile
- [x] Prepare public release notes

## Run cross-platform smoke matrix
> kanoli:id 22222222-2222-4222-8222-222222222225
> kanoli:priority B
> kanoli:labels windows, linux, ios, android

_Summary: Validate the same core board lifecycle on every enabled Flutter target._

**Status:** Deferred until the macOS beta path is stable.
**Compatibility:** Platform-specific file pickers and permission failures must be covered before broader release claims.

### Notes

#### 2026-05-10T12:00:00-07:00
Flutter targets are enabled, but Windows, Linux, iOS, and Android smoke coverage was explicitly deferred.

### Platform smoke
> kanoli:checklist 22222222-2222-4222-8222-222222222226
- [ ] Windows create/open/import/relaunch
- [ ] Linux create/open/import/relaunch
- [ ] iOS document picker lifecycle
- [ ] Android Storage Access Framework lifecycle
- [ ] Permission-denied and malformed-file cases per platform

# Quick Wins

## Add fast card search
> kanoli:id 33333333-3333-4333-8333-333333333331
> kanoli:priority B
> kanoli:labels search, ux

### Notes

#### 2026-05-10T12:00:00-07:00
High-value usability feature with low persistence risk because cards are already loaded in memory.

### Implementation sketch
> kanoli:checklist 33333333-3333-4333-8333-333333333332
- [ ] Search title, labels, notes, checklist text, and todo text
- [ ] Support current-board and all-open-boards modes
- [ ] Add focused widget/controller tests

## Show checklist and todo counts on cards
> kanoli:id 33333333-3333-4333-8333-333333333333
> kanoli:priority B
> kanoli:labels cards, ux

### Notes

#### 2026-05-10T12:00:00-07:00
Existing card data already includes checklists and todo sidecar items, so this is mostly card tile UI.

### Display states
> kanoli:checklist 33333333-3333-4333-8333-333333333334
- [ ] Checklist complete/total count
- [ ] Todo open/completed count
- [ ] Overdue indicator if due dates exist

## Add clear completed todos action
> kanoli:id 33333333-3333-4333-8333-333333333335
> kanoli:priority C
> kanoli:labels todo, workflow

### Notes

#### 2026-05-10T12:00:00-07:00
Todo completion state already exists. This should include a confirmation prompt and preserve unrelated todo.txt lines.

### Safety criteria
> kanoli:checklist 33333333-3333-4333-8333-333333333336
- [ ] Confirm before deleting completed todos
- [ ] Preserve unrelated lines and spacing where possible
- [ ] Test merge behavior against todo sidecar fixtures

## Add archive keyboard/menu command
> kanoli:id 33333333-3333-4333-8333-333333333337
> kanoli:priority C
> kanoli:labels archive, workflow

### Notes

#### 2026-05-10T12:00:00-07:00
Archive behavior already exists; this card is about exposing it as a faster command.

### Command surface
> kanoli:checklist 33333333-3333-4333-8333-333333333338
- [ ] Add shortcut/menu entry for Move to Archive
- [ ] Ensure selected-card context is clear
- [ ] Confirm behavior with Archive column auto-create

# Mermaid Integration

## Preserve Mermaid fenced code blocks in notes
> kanoli:id 44444444-4444-4444-8444-444444444441
> kanoli:priority B
> kanoli:labels mermaid, markdown

### Notes

#### 2026-05-10T12:00:00-07:00
First Mermaid step: allow users to store Mermaid source in Kanoli Markdown without rendering it yet.

#### 2026-05-10T12:00:00-07:00
Example source: ```mermaid flowchart TD; Idea-->Build; Build-->Ship; ```

### Markdown handling
> kanoli:checklist 44444444-4444-4444-8444-444444444442
- [ ] Decide whether Mermaid belongs in notes, card body text, or a new diagram block type
- [ ] Preserve fenced blocks without mangling line breaks
- [ ] Add parse/serialize tests for fenced Mermaid content

## Detect and label Mermaid blocks in the card editor
> kanoli:id 44444444-4444-4444-8444-444444444443
> kanoli:priority B
> kanoli:labels mermaid, ux

### Notes

#### 2026-05-10T12:00:00-07:00
Before rendering diagrams, Kanoli can still improve editing by recognizing Mermaid blocks and showing them as diagram source.

### Editor polish
> kanoli:checklist 44444444-4444-4444-8444-444444444444
- [ ] Add simple Mermaid block detection
- [ ] Add a compact Diagram label or icon
- [ ] Keep raw source editable

## Prototype rendered Mermaid preview
> kanoli:id 44444444-4444-4444-8444-444444444445
> kanoli:priority A
> kanoli:labels mermaid, prototype

### Notes

#### 2026-05-10T12:00:00-07:00
Mermaid rendering likely needs a WebView/JS or export pipeline decision. Keep this as a prototype until storage and security rules are clear.

### Prototype questions
> kanoli:checklist 44444444-4444-4444-8444-444444444446
- [ ] Compare Flutter WebView rendering vs external export pipeline
- [ ] Confirm offline behavior
- [ ] Validate sanitization and local-file safety
- [ ] Decide if previews are cached or generated on demand

## Generate board relationship diagrams from Kanoli data
> kanoli:id 44444444-4444-4444-8444-444444444447
> kanoli:priority C
> kanoli:labels mermaid, automation

### Notes

#### 2026-05-10T12:00:00-07:00
Longer-term Mermaid feature: generate flowcharts from columns, cards, labels, due-date risk, or project workflow structure.

### Generation ideas
> kanoli:checklist 44444444-4444-4444-8444-444444444448
- [ ] Column flow diagram
- [ ] Label dependency diagram
- [ ] Release workflow timeline

# Long Term

## Add card attachments and image previews
> kanoli:id 55555555-5555-4555-8555-555555555551
> kanoli:priority A
> kanoli:labels attachments, media

### Notes

#### 2026-05-10T12:00:00-07:00
Large feature because it needs file reference policy, missing-file recovery, Markdown conventions, and preview UI.

### Design decisions
> kanoli:checklist 55555555-5555-4555-8555-555555555552
- [ ] Link vs copy attachment files
- [ ] Define Markdown storage format
- [ ] Handle missing or moved attachments
- [ ] Add image preview UI

## Design optional local encryption
> kanoli:id 55555555-5555-4555-8555-555555555553
> kanoli:priority A
> kanoli:labels security, phase4

### Notes

#### 2026-05-10T12:00:00-07:00
Security-sensitive roadmap item. Needs a threat model, recovery story, key handling, and cross-platform behavior.

### Security planning
> kanoli:checklist 55555555-5555-4555-8555-555555555554
- [ ] Define what encryption protects and does not protect
- [ ] Choose file format and migration story
- [ ] Decide password/key recovery behavior
- [ ] Add tests for locked/corrupt/wrong-password cases

## Build full cross-platform release process
> kanoli:id 55555555-5555-4555-8555-555555555555
> kanoli:priority B
> kanoli:labels release, platforms

### Notes

#### 2026-05-10T12:00:00-07:00
Beyond smoke testing, each platform needs packaging, signing, permissions, and install/update QA.

### Release channels
> kanoli:checklist 55555555-5555-4555-8555-555555555556
- [ ] macOS signed/notarized DMG
- [ ] Windows installer or portable package
- [ ] Linux package format decision
- [ ] Android build/distribution decision
- [ ] iOS signing/TestFlight/App Store path decision

## Explore plugin or automation layer
> kanoli:id 55555555-5555-4555-8555-555555555557
> kanoli:priority C
> kanoli:labels plugins, automation

### Notes

#### 2026-05-10T12:00:00-07:00
Powerful but architecture-shaping. This should wait until the local-first safety model is more mature.

### Architecture questions
> kanoli:checklist 55555555-5555-4555-8555-555555555558
- [ ] Define what plugins can read/write
- [ ] Keep all automation local-first by default
- [ ] Add permission boundaries and recovery behavior
