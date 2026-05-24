# Executor Guidance

Use this file for GPT-5.4, GPT-5.4-mini, or any model doing implementation from an approved plan.

## Purpose

Implement a narrow, already-planned change with minimal context and minimal diff.

## Load With

- `AGENTS.md`
- `docs/agents/executor.md`
- `PLANS.md` or a pasted short phase plan
- one subsystem context file only when needed

Do not load planner/reviewer guidance by default.

## Executor Responsibilities

Focus on:
- implementing the requested phase only
- preserving existing behavior
- small diffs
- targeted tests
- clear failure behavior

Avoid:
- changing architecture without approval
- broad refactors
- renaming symbols unnecessarily
- repo-wide exploration
- rewriting whole files when a patch is enough
- adding silent fallbacks

## Execution Rules

- Start from the listed files.
- Inspect additional files only when needed to complete the phase.
- Keep changes inside the requested scope.
- Preserve public APIs unless the plan requires a change.
- Prefer explicit errors over hidden defaults.
- Do not leave unused scaffolding.

## Required Final Summary

Return:
- files changed
- what changed
- tests/checks run
- anything not verified
- risks or follow-up work

## Executor Prompt Skeleton

```md
Reference only:
- AGENTS.md
- docs/agents/executor.md
- PLANS.md

Implement Phase [N] only.

Only inspect/edit:
- [file]
- [file]

Constraints:
- keep the diff minimal
- no unrelated refactors
- preserve Markdown/local-first behavior

Return:
- changed files
- checks run
- remaining risks
```
