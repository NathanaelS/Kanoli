# Trello Import Context

## Purpose

Protect Trello JSON import behavior.

## Rules

When changing import logic:
- Preserve existing import mappings unless intentionally changed.
- Do not discard recognizable Trello data silently.
- Keep unsupported fields non-destructive where practical.
- Preserve card/list relationships.
- Preserve user-visible content.
- Add fixtures for import changes.

## Test Expectations

For Trello import changes, include tests or fixtures for:
- basic board import
- lists/columns
- cards
- descriptions/notes
- checklists when supported
- labels/metadata when supported
- missing or partial fields

## Review Risks

Watch for:
- losing descriptions
- unstable IDs
- list order changes
- card order changes
- date/metadata parsing drift
