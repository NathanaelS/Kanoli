# AGENTS.md

## Project Identity

Kanoli is a local-first Flutter/Dart kanban app focused on:
- human-readable Markdown board files
- optional `todo.txt` interoperability
- offline-first workflows
- user ownership of data
- cross-platform support

Core principles:
- Preserve local-first behavior.
- Preserve Markdown readability and compatibility.
- Preserve stable board/card serialization.
- Avoid unnecessary complexity.
- Do not add cloud sync, telemetry, analytics, account systems, or network services unless explicitly requested.

## Repository Layout

Primary Flutter workspace:
- `kanoli_flutter/`

Common directories:
- `kanoli_flutter/lib/app/`
- `kanoli_flutter/lib/core/`
- `kanoli_flutter/lib/domain/board/`
- `kanoli_flutter/lib/data/board/`
- `kanoli_flutter/lib/features/board/`
- `kanoli_flutter/test/`

## Read Only What Is Needed

Default to focused inspection.

Before broad repo exploration:
1. identify the likely files or directories
2. inspect those first
3. expand only when evidence requires it

Do not scan the entire repository for small, localized tasks unless the prompt explicitly asks for a repo-wide audit.

## Editing Rules

- Make the smallest safe change that solves the issue.
- Preserve existing style and conventions.
- Prefer patch-style edits over full-file rewrites.
- Keep diffs small and reviewable.
- Avoid unnecessary formatting churn.
- Do not rename files, symbols, or modules unless required.
- Remove dead code and unused scaffolding when no longer needed.
- Long-running tooling must use timeouts/non-interactive flags when available.

## Modularity

- Prefer code files under 300 lines when practical.
- Do not split files mechanically just to satisfy a line count.
- Extract only clear responsibilities.
- Avoid tiny abstraction files that make the code harder to follow.
- Documentation, plans, fixtures, and generated reports may exceed 300 lines.

## Development Behavior

- Do not add silent default fallbacks during development.
- If something fails, let it fail clearly so it can be fixed correctly.
- Do not leave empty `try`/`catch` blocks.
- Feature toggles/configuration are mandatory for runtime-conditional behavior.
- Prefer open-source and self-hosted libraries when appropriate.
- Ask before introducing major third-party dependencies.
- Design UI for the end-user, not for the schema.

## Flutter / Dart Checks

Run from `kanoli_flutter/`:

```bash
dart format .
flutter analyze
flutter test
```

If checks cannot be run:
- state why
- state what remains unverified

## Local File Compatibility

Kanoli's core value is local, human-readable data.

Do not break:
- Markdown board structure
- card IDs
- metadata serialization
- checklist/note serialization
- companion `BoardName.todo.txt` behavior
- Trello JSON import compatibility
- offline operation

Any change to parsing, serialization, import/export, persistence, or migration logic must include focused tests, fixtures, or clearly documented manual validation.

## Role-Specific Guidance

Load only the relevant file for the current task:
- Planning: `docs/agents/planner.md`
- Execution: `docs/agents/executor.md`
- Review: `docs/agents/reviewer.md`
- Debugging: `docs/agents/debugger.md`
- Testing: `docs/agents/tester.md`

Do not load every role file by default.

## Project Context Files

Use only when relevant:
- Architecture: `docs/project-context/architecture.md`
- Markdown format: `docs/project-context/markdown-format.md`
- Persistence: `docs/project-context/persistence.md`
- Flutter state/UI: `docs/project-context/flutter-state-ui.md`
- Trello import: `docs/project-context/trello-import.md`

<!-- ## Continuity

Maintain `.agent/CONTINUITY.md` for meaningful project deltas only.

At the start of a substantial task:
- read `.agent/CONTINUITY.md` if it exists

Update it when:
- a plan changes
- an architecture decision is made
- a compatibility rule is discovered
- meaningful progress occurs
- a task completes with remaining risks

Do not update it for:
- typo fixes
- formatting-only changes
- obvious one-file edits
- trivial refactors -->

## CONTINUITY.md (REQUIRED)

Maintain a single continuity file for the current workspace:

`.agent/CONTINUITY.md`

`.agent/CONTINUITY.md` is a living project briefing intended to survive compaction and context resets.

At the start of each assistant turn:
- read `.agent/CONTINUITY.md` before acting

Update `.agent/CONTINUITY.md` only when there is a meaningful project delta.

Do NOT update it for:
- tiny typo fixes
- formatting-only changes
- obvious one-file edits
- trivial refactors

## Continuity File Sections

### [PLANS]
Implementation plans and phased work guidance.

### [DECISIONS]
Architecture or workflow decisions and rationale.

### [PROGRESS]
Meaningful implementation progress or course corrections.

### [DISCOVERIES]
Important findings:
- optimizer behavior
- performance tradeoffs
- parser behavior
- compatibility edge cases
- unexpected bugs
- implementation constraints

### [OUTCOMES]
Summaries of completed work:
- what changed
- remaining risks
- lessons learned
- follow-up work

## Continuity Anti-Drift Rules

- Facts only
- No transcripts
- No raw logs
- Keep entries concise and high-signal

Every entry must include:
- ISO timestamp
- provenance tag:
  - `[USER]`
  - `[CODE]`
  - `[TOOL]`
  - `[ASSUMPTION]`

If unknown:
- write `UNCONFIRMED`
- never guess

If something changes:
- supersede explicitly
- do not silently rewrite history

If sections become bloated:
- compress older items into milestone summaries

## Secrets and Sensitive Data

- Never print secrets, tokens, private keys, or credentials.
- Do not ask the user to paste secrets.
- Avoid commands that dump broad environment/config data.
- Prefer existing authenticated CLIs.
- Redact sensitive strings in displayed output.
