# Debugger Guidance

Use this file for compiler errors, runtime crashes, failing tests, and unexpected behavior.

## Purpose

Find the smallest root cause before editing code.

## Debugging Flow

1. Restate the symptom.
2. Identify the likely subsystem.
3. Inspect the smallest relevant file set.
4. Form one primary hypothesis.
5. Verify with logs, tests, or code evidence.
6. Patch only the root cause.
7. Run the narrowest relevant check.

## Avoid

- guessing from symptoms alone
- broad refactors while debugging
- adding fallback behavior to hide the bug
- changing unrelated files
- suppressing errors without explanation

## Required Output

Return:
- root cause
- evidence
- files changed
- validation performed
- remaining uncertainty

## Debugging Prompt Skeleton

```md
Reference only:
- AGENTS.md
- docs/agents/debugger.md

Bug:
[paste error/symptom]

Relevant files:
- [file]

Do not refactor. Find the smallest root cause first.
```
