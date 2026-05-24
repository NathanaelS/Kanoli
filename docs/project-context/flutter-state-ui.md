# Flutter State and UI Context

## Purpose

Guide Flutter UI and state changes without overloading every task.

## UI Rules

- Design UI for the end-user, not for the schema.
- Keep widgets focused and composable.
- Avoid large widget files when responsibilities can be cleanly extracted.
- Preserve existing user flows unless the task changes them.
- Avoid visual churn unrelated to the task.

## State Rules

- Keep business logic outside widgets when practical.
- Prefer predictable state flow.
- Avoid mixing persistence, parsing, and UI concerns.
- Keep error states explicit.
- Avoid adding hidden default state that masks bugs.

## Validation

For UI/state changes, consider:
- expected empty states
- failure states
- loading/saving states
- keyboard/mouse behavior for desktop
- platform differences where relevant
