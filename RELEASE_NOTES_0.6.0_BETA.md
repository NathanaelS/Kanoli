# Kanoli 0.6.0 Beta

Kanoli 0.6.0 Beta is a macOS-first public beta of the Flutter/Dart rebuild.

## Important macOS Install Note

This beta is unsigned and not notarized by Apple. macOS may block the first launch because Kanoli is from an unidentified developer.

If blocked, open Kanoli by Control-clicking `Kanoli.app` in Finder and choosing `Open`, or go to **System Settings > Privacy & Security** and choose **Open Anyway** after the first blocked launch.

## Highlights

- Local-first kanban boards stored as Markdown.
- Companion `todo.txt` sidecar files for card-scoped todos.
- Trello and Kanoli JSON import.
- Multi-board tabs and session restore.
- Due-date and label filtering, including cross-board filtered results.
- Card editor with notes, labels, due dates, priorities, checklists, and todos.
- Safe persistence improvements, including atomic writes and best-effort backups.
- Local diagnostics panel and exportable troubleshooting information.

## Known Limitations

- This release is unsigned and not notarized.
- Gatekeeper warning is expected on first launch.
- Windows, Linux, iOS, and Android smoke testing remains deferred.
- Backup creation is best-effort and may be limited by sandboxed or restricted paths.
- Signed/notarized macOS distribution requires future Apple Developer Program setup.

## Release Details

- Version: `0.6.0-beta+1`
- macOS bundle version: `0.6.0`, build `1`
- Artifact: `Kanoli-0.6.0-beta.dmg`
- Bundle ID: `ko.kanoli.kanoliFlutter`
- Recommended Git tag: `v0.6.0-beta`
- GitHub release type: prerelease
