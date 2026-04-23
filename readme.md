# Kanoli [![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey)](#building-kanoli) [![Storage](https://img.shields.io/badge/storage-Markdown%20%2B%20todo.txt-2ea44f)](#kanoli) [![UI](https://img.shields.io/badge/UI-SwiftUI-0A84FF)](#kanoli) [![Version](https://img.shields.io/badge/version-0.6-0A84FF?logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAABGdBTUEAALGPC%2FxhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAARGVYSWZNTQAqAAAACAABh2kABAAAAAEAAAAaAAAAAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAAAQoAMABAAAAAEAAAAQAAAAADRVcfIAAAHNaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI%2BCiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI%2BCiAgICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIj4KICAgICAgICAgPGV4aWY6Q29sb3JTcGFjZT4xPC9leGlmOkNvbG9yU3BhY2U%2BCiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4xMjAyPC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICAgICAgICAgPGV4aWY6UGl4ZWxZRGltZW5zaW9uPjEyMDI8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KvUt5GQAAAhZJREFUKBVtkt9r01AUx5M0zc3PVpqtbUrcYEPYZvdgscpAFJ34YzBBEXxUYQh70WdBn%2FwHfBIfhYEg82GCoOLTEIVRqENQ0WFlrdvQJf1l86tJ7vVCQjK33YfLOZfzOT%2B%2B5xLEnkMnEnve4gcyMhMU6UN0cXpqIJPWmh3PR8sfqv1%2BPwoIjDAZRZIcQ126cOru7etWV589W752ZcZ1vdXPaxDCnUwI8Gxy%2BtjonfkbiIAHlWyxOOH7nprL1Brb643NfQCRY%2B7dmpkslR89WXJRor5eV%2FI5tZAdHx9bfPHW8%2FyIoQML1x0ckNdqjYXnbwSByw%2FKpeqPZrMFAEinJNt2dgMiDxobWy8rVZYFbt81Lfvr958rldUhtdBqd6JobIQzgCR9SD1Q%2BbJp9T2KIiFCju3wPJ9M0rre2gcwHfdbXVOUQqfbw4phfdrtbkHJbWtNy7Z3AlTk6F0bElRKEgmClEShZ5hqXgbM7iXGAEKEYVoQIsOyKNwWQchp1jTD9CQZrjgGoO%2F3DINhkiwApokZsvZL7%2Fw1BJ69OntGVbJBLzGAfQQx5XMswKUyslzf%2BH3%2B9PGnjx%2BIAr%2F1RwuAcA%2FYwcrg7rHkkiQODw9RTuvyufLc3M2FxddLr5aj3cWfD3d5YuooRNDo9Y6MyidLIxPFyXcrn%2B4%2FfGY5XpAe3zGAHTwrQkji6MMjuaycev%2BxpnX%2F0xTH%2FAPofN%2FwDrXOeAAAAABJRU5ErkJggg%3D%3D&logoColor=white)](#kanoli)

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
