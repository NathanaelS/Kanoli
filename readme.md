# Kanoli

[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20iOS%20%7C%20Android-lightgrey)](#quick-start)
[![Storage](https://img.shields.io/badge/storage-Markdown%20%2B%20todo.txt-2ea44f)](#kanoli)
[![UI](https://img.shields.io/badge/UI-Flutter%20%2F%20Dart-02569B?logo=flutter&logoColor=white)](#kanoli)
[![Release](https://img.shields.io/badge/release-macOS%20.dmg-2ea44f)](#quick-start)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

<!-- CODEX DO NOT EDIT -->

Kanoli is a local-first, Trello-inspired kanban app centered on the philosophy of having your data available to you locally and regardless of the app working. 

Kanoli is the brain child of me, Nathanael Stutz, entirely vibecoded inside of Codex. I am not a software engineer and I do not claim that this app is without flaws. This app is built by me, for me, for my system, in an effort to have more of my information stored and handled locally. I am making it open source and public facing in the hopes that it can either help or inspire others.

The vast majority of the documents you are about to go through are AI generated, but I have done my best to include comments where possible, and to still be the "human face" of this project. I am working on a "Vision" document explaining workflow/thought process of the app and creation.

And now, begin the AI generated paragraphs edited by me.......

<!-- CODEX DO NOT EDIT -->


## Quick Start

Download the latest `.dmg` from the [GitHub Releases page](https://github.com/NathanaelS/Kanoli/releases), install Kanoli, and open the app normally.

Before installing, verify the checksum and signing identity using
[Verifying Kanoli Downloads](docs/security/VERIFYING_DOWNLOADS.md).

For the layperson or someone that doesn't use command line regularly, this might seem daunting, but I encourage you to follow the steps in an effort to understand app security a little better, and in the day and age of AI vibecoding everything everywhere, it's good to know how to verify authenticity.

## Dev Branch

If you want to have cool features that aren't available on the main release, and potentially have a broken app at times, you can clone the [dev branch](https://github.com/NathanaelS/Kanoli/tree/dev) and build off of that. I am NOT releasing dev versions, so this will require VS Code and the Flutter SDK on your machine.


## Local-First Data Model (Or "My stuff is my stuff")

Kanoli is entirely based on offline files that are still human readable if the app is not available. Being organized should not require a constant internet connection, and this app is built with that premise.

- Board columns are stored as Markdown `#` headings.
- Cards are stored as Markdown `##` headings.
- Card metadata includes priority, labels, due dates, and stable IDs.
- Notes and checklists are stored as quoted structured Markdown lines.
- Board todo items can be stored in companion `BoardName.todo.txt` files.
- Trello JSON imports are converted into Kanoli Markdown boards.


## Bug Tracker

Have a bug or feature request?
Open an issue in this repository and include:

- What you expected
- What happened
- Steps to reproduce
- Your platform and Flutter version
- Any sample board file, if safe to share

Issue tracker: [GitHub Issues](https://github.com/NathanaelS/Kanoli/issues)

Project tracking format and issue template examples live in [.github/PROJECT_LAYOUT.md](.github/PROJECT_LAYOUT.md).

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for Flutter/Dart setup, style, testing, and local-file compatibility guidance.

## Roadmap

Current ideas that I am rattling off my head in no particular order:

- Cleaning up UI and implementing "prettier" features.
- Markdown editor inside of app for drafting documents.
- Mermaid support for timeline Gantt chart visualization
- File attachment support
- Calendar view?
- Better filtering conditions
- Encryption?
- Ultimately trying to cross device share via SyncThing

## Inspiration

Inspiration for this app and how it looks come from the following places:

- [Plaintext Productivity][plaintext-productivity]
- [todo.txt][todotxt]
- [Sleek task management][sleek]
- [Aura theme][aura-theme]
- Local-first software principles

## License

Kanoli is licensed under the MIT License.
See [LICENSE](LICENSE) for details.

[plaintext-productivity]: https://plaintext-productivity.net/
[todotxt]: https://github.com/todotxt/todo.txt
[sleek]: https://github.com/ransome1/sleek
[aura-theme]: https://github.com/daltonmenezes/aura-theme
