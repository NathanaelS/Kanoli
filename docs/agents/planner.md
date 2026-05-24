# Planner Guidance

Use this file for GPT-5.5 or another strong planning model.

## Purpose

Produce a minimal, high-signal implementation plan before code changes.

## Load With

- `AGENTS.md`
- relevant project-context file(s)
- optionally `PLANS.md`

Do not load executor/reviewer/tester guidance unless specifically needed.

## Planner Responsibilities

Focus on:
- architecture impact
- affected files/modules
- local-first data compatibility
- state flow
- parsing/persistence risks
- testing strategy
- incremental phases

Avoid:
- generating full implementation code
- broad speculative refactors
- formatting-only changes
- exploring unrelated subsystems

## Required Output

Return:
1. task summary
2. relevant files to inspect/edit
3. non-goals
4. proposed phases
5. compatibility risks
6. test/validation plan
7. smallest safe first step

## Planning Rules

- Prefer the smallest useful phase.
- Keep public entrypoints stable when practical.
- Preserve Markdown and `todo.txt` compatibility.
- Identify when a task should be split.
- State assumptions explicitly.
- If information is missing, list the unknowns instead of inventing details.

## Planning Prompt Skeleton

```md
Reference only:
- AGENTS.md
- docs/agents/planner.md
- [one relevant project-context file]

Do not edit files yet.

Task:
[task]

Return:
- affected files
- minimal implementation plan
- non-goals
- compatibility risks
- tests/validation
- first implementation phase
```
