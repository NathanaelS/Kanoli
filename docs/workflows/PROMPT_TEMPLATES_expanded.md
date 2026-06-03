# Prompt Templates for Codex

These templates are optimized for context control, minimal token usage, and scoped work in Kanoli.

Use them by copying one template, replacing the placeholders, and referencing only the files listed. Do not paste broad project summaries unless the task truly requires them. This is how we avoid feeding Codex the entire pantry when it only asked for a spoon.

---

# Usage Rules

- Start a new Codex thread for unrelated work.
- Reference only the files listed in the prompt.
- Prefer file paths over prose explanations.
- Keep task descriptions short and concrete.
- Use GPT-5.5 for planning and review.
- Use GPT-5.4 or GPT-5.4-mini for scoped implementation.
- Do not ask the executor model to rediscover architecture.
- Do not load all docs unless the task genuinely spans all systems.

---

# 1. GPT-5.5 Planning Prompt

Use for architecture, multi-file changes, parser changes, persistence changes, or anything with compatibility risk.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md
- docs/project-context/[relevant].md

Do not edit files.

Task:
[one-sentence task]

Known files:
- [path]
- [path]

Return:
- affected files
- non-goals
- minimal phased plan
- compatibility risks
- tests/validation
- first executable phase
```

## Example: Markdown Metadata Planning

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md
- docs/project-context/markdown-format.md

Do not edit files.

Task:
Plan support for an optional card `due:` metadata field in Markdown boards.

Known files:
- kanoli_flutter/lib/data/board/
- kanoli_flutter/lib/domain/board/
- kanoli_flutter/test/

Return:
- affected files
- non-goals
- minimal phased plan
- backward compatibility risks
- tests/fixtures needed
- first executable phase
```

## Example: Trello Import Planning

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md
- docs/project-context/trello-import.md
- docs/project-context/markdown-format.md

Do not edit files.

Task:
Plan how Trello checklist imports should map into Kanoli card checklist data.

Known files:
- kanoli_flutter/lib/data/board/
- kanoli_flutter/test/

Return:
- affected files
- non-goals
- minimal phased plan
- import compatibility risks
- required tests/fixtures
- first executable phase
```

---

# 2. GPT-5.4 Execution Prompt

Use after GPT-5.5 has produced a plan. This prompt should be boring. Boring is cheap. Boring works.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md
- PLANS.md

Implement Phase [N] only.

Only inspect/edit:
- [path]
- [path]

Constraints:
- smallest safe diff
- no unrelated refactors
- no silent fallbacks
- preserve Markdown/local-first behavior

Run if feasible:
- dart format .
- flutter analyze
- flutter test

Return:
- files changed
- checks run
- risks/follow-up
```

## Example: Implement Parser Phase

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md
- PLANS.md

Implement Phase 1 only: parse optional `due:` metadata into the board model.

Only inspect/edit:
- kanoli_flutter/lib/data/board/
- kanoli_flutter/lib/domain/board/
- kanoli_flutter/test/

Constraints:
- smallest safe diff
- no unrelated refactors
- no silent fallbacks
- preserve existing Markdown files without `due:`
- do not change UI yet

Run if feasible:
- dart format .
- flutter analyze
- flutter test

Return:
- files changed
- checks run
- risks/follow-up
```

## Example: Implement UI Phase

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md
- PLANS.md
- docs/project-context/flutter-state-ui.md

Implement Phase 2 only: show existing card due dates in the card detail UI.

Only inspect/edit:
- kanoli_flutter/lib/features/board/

Constraints:
- smallest safe diff
- no parser changes
- no persistence changes
- no unrelated visual redesign
- keep widgets focused

Run if feasible:
- dart format .
- flutter analyze
- flutter test

Return:
- files changed
- checks run
- risks/follow-up
```

---

# 3. GPT-5.4-mini Small Fix Prompt

Use for tiny fixes, compiler errors, obvious test failures, or narrow formatting issues.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md

Fix:
[bug/error]

Scope:
- [path]

Rules:
- patch only
- no refactor
- no unrelated formatting
- do not inspect unrelated files unless blocked

Run if feasible:
- [specific command]

Return:
- changed file(s)
- check result
```

## Example: Analyzer Error

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md

Fix:
`flutter analyze` reports an unused import in `board_view.dart`.

Scope:
- kanoli_flutter/lib/features/board/board_view.dart

Rules:
- patch only
- no refactor
- no unrelated formatting
- do not inspect unrelated files unless blocked

Run if feasible:
- flutter analyze

Return:
- changed file(s)
- check result
```

## Example: Broken Test Assertion

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md

Fix:
`board_parser_test.dart` fails because the expected metadata order changed.

Scope:
- kanoli_flutter/test/board_parser_test.dart

Rules:
- patch only
- do not change production code unless the test reveals a real bug
- no unrelated formatting

Run if feasible:
- flutter test test/board_parser_test.dart

Return:
- changed file(s)
- check result
```

---

# 4. GPT-5.5 Review Prompt

Use after an implementation phase, before committing or merging.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/reviewer.md
- current diff

Review only. Do not edit.

Focus:
- scope creep
- architecture drift
- Markdown/todo/Trello compatibility
- state/persistence bugs
- missing tests

Return:
- blockers
- non-blocking risks
- missing tests
- approval recommendation
```

## Example: Parser Review

```md
Reference only:
- AGENTS.md
- docs/agents/reviewer.md
- docs/project-context/markdown-format.md
- current diff

Review only. Do not edit.

Focus:
- Markdown backward compatibility
- metadata preservation
- parser/serializer symmetry
- unnecessary file churn
- missing fixtures or tests

Return:
- blockers
- non-blocking risks
- missing tests
- approval recommendation
```

## Example: UI Review

```md
Reference only:
- AGENTS.md
- docs/agents/reviewer.md
- docs/project-context/flutter-state-ui.md
- current diff

Review only. Do not edit.

Focus:
- state flow correctness
- widget responsibility boundaries
- accidental visual churn
- unnecessary rebuild risk
- missing tests or manual validation

Return:
- blockers
- non-blocking risks
- missing tests
- approval recommendation
```

---

# 5. Debugging Prompt

Use when there is a concrete failure: build error, test failure, runtime crash, bad import result, or parser mismatch.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/debugger.md

Symptom:
[paste exact error/log]

Relevant files:
- [path]

Do first:
- identify root cause
- cite evidence

Do not:
- refactor
- add fallbacks
- inspect unrelated files unless necessary

Return:
- likely root cause
- minimal fix plan
- files to edit
```

## Example: Parser Failure

```md
Reference only:
- AGENTS.md
- docs/agents/debugger.md
- docs/project-context/markdown-format.md

Symptom:
`board_parser_test.dart` fails when parsing a card with checklist items after metadata.

Relevant files:
- kanoli_flutter/lib/data/board/
- kanoli_flutter/test/board_parser_test.dart

Do first:
- identify root cause
- cite evidence from the parser/test

Do not:
- refactor
- add fallbacks
- inspect UI files

Return:
- likely root cause
- minimal fix plan
- files to edit
```

## Example: Flutter Build Error

```md
Reference only:
- AGENTS.md
- docs/agents/debugger.md

Symptom:
`flutter analyze` reports: "The method 'copyWith' isn't defined for the type 'BoardCard'."

Relevant files:
- kanoli_flutter/lib/domain/board/
- kanoli_flutter/lib/features/board/

Do first:
- identify whether the call site or model is wrong
- cite evidence

Do not:
- add a generated-code dependency
- refactor the domain model
- inspect unrelated features unless necessary

Return:
- likely root cause
- minimal fix plan
- files to edit
```

---

# 6. Test Addition Prompt

Use when behavior exists but needs coverage, or when a parser/import/persistence change needs fixtures.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/tester.md
- docs/project-context/[relevant].md

Add tests for:
[behavior]

Relevant files:
- [path]

Rules:
- behavior-focused tests
- use fixtures if file format behavior changes
- do not refactor production code unless required

Run if feasible:
- flutter test [specific test path]

Return:
- tests added
- checks run
- coverage gaps
```

## Example: Markdown Fixture Test

```md
Reference only:
- AGENTS.md
- docs/agents/tester.md
- docs/project-context/markdown-format.md

Add tests for:
Parsing and serializing cards with optional `due:` metadata.

Relevant files:
- kanoli_flutter/test/
- kanoli_flutter/lib/data/board/

Rules:
- behavior-focused tests
- include a fixture or inline Markdown sample
- verify round-trip serialization
- do not refactor production code unless required

Run if feasible:
- flutter test test/board_parser_test.dart

Return:
- tests added
- checks run
- coverage gaps
```

## Example: Trello Import Test

```md
Reference only:
- AGENTS.md
- docs/agents/tester.md
- docs/project-context/trello-import.md

Add tests for:
Importing Trello checklist items into Kanoli card checklist data.

Relevant files:
- kanoli_flutter/test/
- kanoli_flutter/lib/data/board/

Rules:
- use a minimal Trello JSON fixture
- verify imported checklist text and completion state
- do not modify UI code

Run if feasible:
- flutter test

Return:
- tests added
- checks run
- coverage gaps
```

---

# 7. Markdown Parser Change Prompt

Use for any board file format change. This deserves planning first because breaking user files is frowned upon by civilizations that enjoy functioning software.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md
- docs/project-context/markdown-format.md

Do not edit files yet.

Change requested:
[change]

Return:
- parser/serializer impact
- backward compatibility risks
- fixtures needed
- minimal phase plan
```

## Example: Add Archive Metadata

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md
- docs/project-context/markdown-format.md

Do not edit files yet.

Change requested:
Add optional archived-card metadata to Markdown serialization.

Return:
- parser/serializer impact
- backward compatibility risks
- fixtures needed
- minimal phase plan
- non-goals
```

---

# 8. Persistence Change Prompt

Use for storage, save/load, migrations, file picker flows, or anything that could cause data loss.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md
- docs/project-context/persistence.md

Do not edit files yet.

Task:
[task]

Return:
- data-loss risks
- migration needs
- affected files
- tests/validation
- minimal first phase
```

## Example: Autosave Planning

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md
- docs/project-context/persistence.md

Do not edit files yet.

Task:
Plan autosave for board edits without changing the Markdown file format.

Return:
- data-loss risks
- migration needs
- affected files
- tests/manual validation
- minimal first phase
- non-goals
```

---

# 9. Flutter UI Prompt

Use for UI-only work after data/model behavior is defined.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md
- docs/project-context/flutter-state-ui.md

Implement:
[UI change]

Only inspect/edit:
- [path]
- [path]

Constraints:
- preserve user flow
- no schema-driven UI decisions
- no unrelated visual churn
- keep widgets focused

Run if feasible:
- dart format .
- flutter analyze
```

## Example: Card Badge UI

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md
- docs/project-context/flutter-state-ui.md

Implement:
Show a compact due-date badge on board cards when a card has a due date.

Only inspect/edit:
- kanoli_flutter/lib/features/board/

Constraints:
- preserve existing board interactions
- no parser/persistence changes
- no unrelated visual redesign
- keep widgets focused

Run if feasible:
- dart format .
- flutter analyze
```

---

# 10. Low-Context Continuation Prompt

Use when continuing a task in the same branch after prior planning. This prevents Codex from doing an archaeological dig through the repo again.

## Template

```md
Reference only:
- AGENTS.md
- .agent/CONTINUITY.md
- PLANS.md

Continue Phase [N].

Do not re-analyze the whole repo.
Inspect only files listed in PLANS.md unless blocked.

Return:
- progress
- checks run
- next smallest step
```

## Example

```md
Reference only:
- AGENTS.md
- .agent/CONTINUITY.md
- PLANS.md

Continue Phase 2: add UI display for parsed due dates.

Do not re-analyze the whole repo.
Inspect only files listed in PLANS.md unless blocked.

Return:
- progress
- checks run
- next smallest step
```

---

# 11. Context Reset Prompt

Use after context compaction, a model switch, or a stale thread.

## Template

```md
Reference only:
- AGENTS.md
- .agent/CONTINUITY.md
- PLANS.md

Reconstruct current task state.

Return:
- current goal
- active phase
- relevant files
- last known risks
- next action

Do not edit files.
```

## Example

```md
Reference only:
- AGENTS.md
- .agent/CONTINUITY.md
- PLANS.md

Reconstruct current task state for the due-date metadata work.

Return:
- current goal
- active phase
- relevant files
- last known risks
- next action

Do not edit files.
```

---

# 12. Prompt Generator Prompt

Use GPT-5.5 to generate task-specific prompts for the planner/executor/reviewer split.

## Template

```md
Reference only:
- AGENTS.md
- docs/workflows/context-efficient-codex.md
- docs/project-context/[relevant].md

Generate three prompts for this task:
1. GPT-5.5 planning prompt
2. GPT-5.4 execution prompt
3. GPT-5.5 review prompt

Task:
[task]

Optimize for:
- minimal context
- exact file scope
- small diffs
- compatibility safety
```

## Example

```md
Reference only:
- AGENTS.md
- docs/workflows/context-efficient-codex.md
- docs/project-context/markdown-format.md
- docs/project-context/flutter-state-ui.md

Generate three prompts for this task:
1. GPT-5.5 planning prompt
2. GPT-5.4 execution prompt
3. GPT-5.5 review prompt

Task:
Add optional due-date support to cards, including Markdown parse/serialize support and a compact UI badge.

Optimize for:
- minimal context
- exact file scope
- small diffs
- compatibility safety
```

---

# 13. File Scope Discovery Prompt

Use before implementation when you do not know the exact files yet. This is cheaper than letting the implementation model roam freely.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md

Do not edit files.

Task:
[task]

Find the smallest relevant file set.

Return only:
- likely files
- why each file matters
- files not to inspect
- recommended next prompt
```

## Example

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md

Do not edit files.

Task:
Find where Kanoli loads and saves board Markdown files.

Find the smallest relevant file set.

Return only:
- likely files
- why each file matters
- files not to inspect
- recommended next prompt
```

---

# 14. Diff Cleanup Prompt

Use after Codex made a working change but touched too much. This happens because machines, like interns, confuse productivity with movement.

## Template

```md
Reference only:
- AGENTS.md
- docs/agents/reviewer.md
- current diff

Goal:
Reduce this diff to the smallest safe change.

Do not add new behavior.

Return:
- unnecessary edits
- files that can be reverted
- smallest safe cleanup plan

Ask before editing.
```

## Example

```md
Reference only:
- AGENTS.md
- docs/agents/reviewer.md
- current diff

Goal:
Reduce this diff to the smallest safe change for due-date parsing.

Do not add new behavior.
Do not rename symbols.
Do not reformat unrelated files.

Return:
- unnecessary edits
- files that can be reverted
- smallest safe cleanup plan

Ask before editing.
```

---

# 15. Commit Summary Prompt

Use after completing a phase, before writing a commit message or updating continuity.

## Template

```md
Reference only:
- AGENTS.md
- .agent/CONTINUITY.md
- current diff

Summarize this completed phase.

Return:
- concise commit message
- files changed
- behavior changed
- tests/checks run
- risks/follow-up
- suggested CONTINUITY.md entry

Do not edit files.
```

## Example

```md
Reference only:
- AGENTS.md
- .agent/CONTINUITY.md
- current diff

Summarize Phase 1: optional due-date metadata parsing.

Return:
- concise commit message
- files changed
- behavior changed
- tests/checks run
- risks/follow-up
- suggested CONTINUITY.md entry

Do not edit files.
```
