# Persistence Context

## Purpose

Protect local-first persistence behavior.

## Rules

- User data remains local unless explicitly requested otherwise.
- Do not add cloud sync, telemetry, analytics, or account dependencies without approval.
- Prefer explicit read/write behavior.
- Avoid silent data loss.
- Avoid hidden fallback files or duplicate sources of truth.
- Keep migrations intentional and testable.

## File I/O Expectations

When changing file access:
- preserve user-selected file/folder behavior
- keep error states visible and actionable
- avoid overwriting files unnecessarily
- document migration or recovery behavior

## Validation

For persistence changes, validate:
- save/load path
- missing file behavior
- malformed file behavior
- permission/access errors when practical
- cross-platform assumptions
