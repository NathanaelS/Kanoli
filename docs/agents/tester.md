# Tester Guidance

Use this file for writing or updating tests.

## Purpose

Add focused tests that protect behavior without overfitting implementation details.

## Test Priorities

Prioritize tests for:
- Markdown parsing/serialization
- metadata preservation
- card ID stability
- `todo.txt` compatibility
- Trello import mapping
- persistence edge cases
- state transitions
- user-visible behavior

## Test Rules

- Prefer small behavior-focused tests.
- Use fixtures for file format compatibility changes.
- Avoid tests that merely mirror implementation details.
- Do not delete existing tests unless they are obsolete and the reason is stated.
- If a behavior is intentionally changed, update tests and document the change.

## Required Output

Return:
- tests added/changed
- behavior covered
- fixtures added/changed
- checks run
- remaining gaps

## Test Prompt Skeleton

```md
Reference only:
- AGENTS.md
- docs/agents/tester.md
- [relevant subsystem context]

Add focused tests for:
[behavior]

Do not refactor production code unless required to make the behavior testable.
```
