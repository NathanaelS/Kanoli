# Contributing to Kanoli

Thanks for your interest in contributing to Kanoli.

This repository contains the Flutter/Dart rebuild of Kanoli. The original Swift version lives separately at [NathanaelS/KanoliSwift](https://github.com/NathanaelS/KanoliSwift).

## How to Contribute

1. Fork the repository and create a feature branch.
2. Keep changes focused and small when possible.
3. Prefer changes that preserve Kanoli's local-first, offline document workflow.
4. Open a pull request with:
   - A clear summary of the change
   - Why the change is needed
   - Any testing steps
   - Screenshots or screen recordings for UI changes when helpful

## Bug Reports and Feature Requests

Please use GitHub Issues:

- https://github.com/NathanaelS/KanoliDart/issues

When reporting bugs, include:

- Expected behavior
- Actual behavior
- Steps to reproduce
- Platform and OS version
- Flutter version, if building from source
- Screenshots or sample files when safe to share

## Project Layout

The Flutter app lives in:

```text
kanoli_flutter/
```

Useful areas:

- `kanoli_flutter/lib/` for app source code
- `kanoli_flutter/lib/domain/` for board entities and pure logic
- `kanoli_flutter/lib/data/` for Markdown, todo, and import persistence
- `kanoli_flutter/lib/features/` for user-facing feature code
- `kanoli_flutter/test/` for tests

## Code Style

- Follow existing Flutter and Dart patterns in the project.
- Prefer readable, maintainable code over clever shortcuts.
- Keep UI changes consistent with the existing Kanoli design language.
- Preserve local-first behavior; do not add cloud, telemetry, analytics, or network dependencies without explicit discussion.
- Avoid unrelated refactors in feature or fix PRs.
- Keep generated build artifacts out of commits.

## Testing

Run available checks before opening a PR:

```bash
cd kanoli_flutter
flutter analyze
flutter test
```

If no test exists for your change type, include manual validation steps in the PR.

For platform-specific work, mention which target was tested:

- macOS
- Windows
- Linux
- iOS
- Android

## Local Files and Compatibility

Kanoli stores user data in local Markdown and companion `todo.txt` files. Contributions should preserve:

- Markdown board compatibility
- Card IDs and metadata
- todo.txt companion file behavior
- Trello JSON import behavior
- Offline use with local documents

If a change modifies file parsing or serialization, include focused tests or sample files that show the expected behavior.
