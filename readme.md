# Kanoli [![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey)](#building-kanoli) [![Storage](https://img.shields.io/badge/storage-Markdown%20%2B%20todo.txt-2ea44f)](#kanoli) [![UI](https://img.shields.io/badge/UI-SwiftUI-0A84FF)](#kanoli)

Kanoli is a local-first, Trello-inspired Kanban app that stores your board data in plain Markdown.
It is designed for offline use, human-readable files, and portable workflows.

## Quick Start

To get started with Kanoli:

1. Download the latest alpha `.dmg` from the GitHub Releases page and install Kanoli.
2. Open Kanoli and click **Create File** to start a new Markdown board.
3. Click **Open File** to load an existing board.
4. Click **Import Trello Board** to convert Trello JSON into a Kanoli Markdown board.

You do not need to assemble/build Kanoli in Xcode to use the alpha release.

If macOS blocks launch, go to **System Settings > Privacy & Security** and allow Kanoli to open.

## Bug Tracker

Have a bug or feature request?
Open an issue in this repository and include:

- What you expected
- What happened
- Steps to reproduce
- Any sample board file (if safe to share)

Issue tracker: [GitHub Issues](https://github.com/NathanaelS/Kanoli/issues)

## Building Kanoli

To run Kanoli locally:

1. Open `Kanoli.xcodeproj` in Xcode.
2. Select the `Kanoli` scheme.
3. Choose a macOS target and run.

The project is built with SwiftUI and Xcode project defaults.
Building in Xcode is optional if you are using the prebuilt alpha `.dmg` from Releases.

## Documentation

For project details and current implementation status:

- [Current State](Kanoli/Current-State.md)

## Roadmap

Kanoli is focused on:

- Better Markdown readability and safer file operations
- Card-level file attachments and image support
- Improved drag/drop UX and board navigation
- Faster filtering, search, and workflow shortcuts

See [Current State](Kanoli/Current-State.md) for the detailed phased roadmap.

## Inspiration

Kanoli takes inspiration from:

- [Plaintext Productivity][plaintext-productivity]
- [todo.txt][todotxt]
- [Sleek task management][sleek]
- [Aura theme][aura-theme]

## License

Kanoli is licensed under the MIT License.
See [LICENSE](LICENSE) for details.

[plaintext-productivity]: https://plaintext-productivity.net/
[todotxt]: https://github.com/todotxt/todo.txt
[sleek]: https://github.com/ransome1/sleek
[aura-theme]: https://github.com/daltonmenezes/aura-theme
