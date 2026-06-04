# Kanoli Architecture Context

## Purpose

This file records stable architectural guidance for Codex. Keep it concise and update only when architecture changes.

## Core Model

Kanoli is a Flutter/Dart local-first kanban app.

Primary priorities:
- local user-owned data
- human-readable Markdown
- optional `todo.txt` compatibility
- import/export friendliness
- cross-platform Flutter support

## Expected Boundaries

Prefer separation between:
- UI widgets
- state/controllers/view models
- domain models
- parsing/serialization
- persistence/file I/O
- import/export adapters

## Dependency Direction

Prefer dependencies flowing inward:
- UI depends on state/domain
- data adapters depend on domain models
- domain models should not depend on UI
- parser/persistence code should not depend on widgets

## Architecture Rules

- Preserve stable domain concepts when possible.
- Keep parser and persistence behavior explicit.
- Avoid coupling visual layout to serialized file structure.
- Avoid network/cloud assumptions.
- Favor simple local abstractions before service-heavy designs.

## When to Update This File

Update when:
- a major subsystem boundary changes
- a new persistence/import/export strategy is adopted
- state management architecture changes
- a meaningful architecture decision is made
