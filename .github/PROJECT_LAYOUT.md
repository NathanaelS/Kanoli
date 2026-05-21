# Kanoli Project Layout

This is the suggested GitHub Project layout for tracking active Kanoli work. It is documentation only until a GitHub Project is created manually.

## Purpose

Use the project to answer three questions quickly:

- What am I doing now?
- What is next?
- What bugs or follow-up issues came up while working?

Keep `Kanoli_Roadmap_Board.md` as the local-first planning board. Use GitHub Issues for specific, actionable work that can be discussed, linked to commits, and moved through the project.

## Views

### Now

Active work only. This should stay small enough to scan in one sitting.

Suggested filter:

```text
status:Now
```

### Next

Queued work that is likely to be picked up soon.

Suggested filter:

```text
status:Next
```

### Bugs

Confirmed defects and reproduction work.

Suggested filter:

```text
type:Bug
```

### Roadmap

Larger product ideas and feature direction.

Suggested filter:

```text
type:Feature
```

### Done

Recently finished work.

Suggested filter:

```text
status:Done
```

## Fields

| Field | Type | Suggested values |
| --- | --- | --- |
| Status | Single select | Inbox, Triage, Now, Next, Blocked, Done |
| Type | Single select | Bug, Feature, Task, Research, Release |
| Priority | Single select | A, B, C |
| Platform | Single select | All, macOS, Windows, Linux, iOS, Android |
| Area | Single select | Markdown, todo.txt, UI, Import, Storage, Build, Release, Docs |
| Source | Single select | Roadmap, User Testing, Codex Session, GitHub Issue |
| Target | Single select | Beta, v1.0, Later |

## Labels

Suggested labels mirror the fields so issues remain useful even outside the Project view.

- `type:bug`
- `type:feature`
- `type:task`
- `type:research`
- `type:release`
- `priority:A`
- `priority:B`
- `priority:C`
- `platform:macos`
- `platform:windows`
- `platform:linux`
- `platform:ios`
- `platform:android`
- `area:markdown`
- `area:todo`
- `area:ui`
- `area:import`
- `area:storage`
- `area:build`
- `area:release`
- `area:docs`

## Issue Flow

1. New ideas and rough bug notes start in `Inbox`.
2. Confirmed work moves to `Triage` with Type, Priority, Platform, and Area filled in.
3. Current work moves to `Now`.
4. Work waiting on setup, decisions, or reproduction moves to `Blocked`.
5. Completed work moves to `Done` after verification notes are added.

## Template Examples

### Bug

Title:

```text
Bug: Board fails to reopen after todo sidecar edit
```

Project fields:

```text
Status: Triage
Type: Bug
Priority: A
Platform: macOS
Area: Storage
Source: User Testing
Target: Beta
```

### Feature

Title:

```text
Feature: Show checklist and todo counts on cards
```

Project fields:

```text
Status: Next
Type: Feature
Priority: B
Platform: All
Area: UI
Source: Roadmap
Target: v1.0
```

### Task

Title:

```text
Task: Verify Windows create/open/import/relaunch smoke path
```

Project fields:

```text
Status: Blocked
Type: Task
Priority: B
Platform: Windows
Area: Build
Source: Roadmap
Target: Beta
```
