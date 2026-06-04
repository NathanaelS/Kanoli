# Markdown Format Context

## Purpose

Protect Kanoli's human-readable Markdown board format.

## Compatibility Rules

When changing Markdown parsing or serialization:
- Preserve existing board readability.
- Preserve card IDs where they already exist.
- Preserve metadata that Kanoli recognizes.
- Preserve unknown metadata when practical.
- Avoid unnecessary field reordering.
- Avoid destructive normalization.
- Add fixtures for format changes.

## Parser Rules

- Prefer explicit parse failures over silent fallbacks.
- Keep parsing behavior deterministic.
- Distinguish invalid input from unsupported but recoverable input.
- Do not discard user-authored content without explicit migration logic.

## Serializer Rules

- Emit stable, predictable output.
- Minimize unnecessary file churn.
- Preserve user-readable structure.
- Avoid adding noisy machine-only syntax unless required.

## Test Expectations

For parser/serializer changes, include tests for:
- round-trip behavior
- metadata preservation
- malformed input handling
- backward compatibility fixtures
- new format examples
