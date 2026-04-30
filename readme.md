# Kanoli

[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20iOS%20%7C%20Android-lightgrey)](#build-options)
[![Storage](https://img.shields.io/badge/storage-Markdown%20%2B%20todo.txt-2ea44f)](#kanoli)
[![UI](https://img.shields.io/badge/UI-Flutter%20%2F%20Dart-02569B?logo=flutter&logoColor=white)](#kanoli)
[![Release](https://img.shields.io/badge/release-macOS%20.dmg-2ea44f)](#quick-start)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

<!-- CODEX DO NOT EDIT -->

Kanoli is a local-first, Trello-inspired kanban app that stores board data in plain Markdown and optional `todo.txt` files. The app was originally created in the Swift language and that repo in it's current state can be found [here](https://github.com/NathanaelS/KanoliSwift). This repository contains the Flutter/Dart rebuild intended to make Kanoli useable on macOS, Windows, iOS, and Android, and probably Linux just because it's the only one left.

Kanoli is the brain child of me, Nathanael Stutz, entirely vibecoded inside of Codex. I am not a software engineer and I do not claim that this app is without flaws. This app is built by me, for me, for my system, in an effort to have more of my information stored and handled locally. I am making it open source and public facing in the hopes that it can either help or inspire others.

The vast majority of the documents you are about to go through are AI generated, but I have done my best to include comments where possible, and to still be the "human face" of this project. I have a "Vision" document available explaining workflow/thought process of the app and creation.

And now, begin the AI paragraphs......

<!-- CODEX DO NOT EDIT -->


## Quick Start

Kanoli Dart has a macOS `.dmg` build available for release. Download the latest `.dmg` from the GitHub Releases page when it is published, install Kanoli, and open the app normally.

If macOS blocks launch, go to **System Settings > Privacy & Security** and allow Kanoli to open.

To run from source instead:

1. Install Flutter and platform toolchains for your target OS.
2. Clone this repository.
3. Enter the Flutter app folder:

   ```bash
   cd kanoli_flutter
   ```

4. Fetch dependencies:

   ```bash
   flutter pub get
   ```

5. Run on an available device:

   ```bash
   flutter run
   ```

<!-- For a specific desktop target:

```bash
flutter run -d macos
flutter run -d windows
flutter run -d linux
``` -->

<!-- Use `flutter devices` to see which targets are available on your machine. -->

## Current Build Status

- A macOS `.dmg` artifact has been created and is intended for release distribution.
- Source builds remain available for development and non-macOS targets.
- Core board workflows are implemented in Flutter.
- Additional platform packaging, signing, and distribution are still pending.

<!-- ## Build Options

Run these commands from:

```bash
/Users/krysilisproductions/Documents/Kanoli/KanoliDart/kanoli_flutter
```

or from the cloned repo's `kanoli_flutter` folder.

### Analyze and Test

```bash
flutter analyze
flutter test
```

### Desktop Builds

macOS:

```bash
flutter build macos
```

Windows:

```bash
flutter build windows
```

Linux:

```bash
flutter build linux
```

Desktop builds require the relevant platform toolchain. macOS builds require Xcode and CocoaPods support where needed. Windows and Linux builds must be performed on their respective supported host platforms.

### Mobile Builds

Android APK:

```bash
flutter build apk
```

Android app bundle:

```bash
flutter build appbundle
```

iOS:

```bash
flutter build ios
```

iOS builds require Xcode and Apple signing configuration. Android builds require Android Studio or equivalent Android SDK tooling. -->

## Local-First Data Model

Kanoli uses local files as the source of truth:

- Board columns are stored as Markdown `#` headings.
- Cards are stored as Markdown `##` headings.
- Card metadata includes priority, labels, due dates, and stable IDs.
- Notes and checklists are stored as quoted structured Markdown lines.
- Board todo items can be stored in companion `BoardName.todo.txt` files.
- Trello JSON imports are converted into Kanoli Markdown boards.

The app should remain usable offline with local documents. External links in notes may open outside the app only when the user explicitly clicks them.

## Bug Tracker

Have a bug or feature request?
Open an issue in this repository and include:

- What you expected
- What happened
- Steps to reproduce
- Your platform and Flutter version
- Any sample board file, if safe to share

Issue tracker: [GitHub Issues](https://github.com/NathanaelS/KanoliDart/issues)

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for Flutter/Dart setup, style, testing, and local-file compatibility guidance.

<!-- ## Documentation

Project planning and parity documents live in [Markdown Plan Files](<Markdown Plan Files/>).

Useful starting points:

- [Feature Parity Checklist](<Markdown Plan Files/FEATURE_PARITY_CHECKLIST.md>)
- [Full Parity Signoff](<Markdown Plan Files/FULL_PARITY_SIGNOFF.md>)
- [Port Spec Phase 1](<Markdown Plan Files/PORT_SPEC_PHASE1.md>)
- [Risk Register Phase 1](<Markdown Plan Files/RISK_REGISTER_PHASE1.md>)
- [Phase 3 Production Hardening Plan](<Markdown Plan Files/PHASE3_PRODUCTION_HARDENING_PLAN.md>)

The Flutter project itself lives in [kanoli_flutter](kanoli_flutter/). -->

## Roadmap

Kanoli Dart is focused on:

- Maintaining parity with the original Swift build.
- Hardening local file access across supported platforms.
- Preserving Markdown and `todo.txt` compatibility.
- Improving offline reliability and save safety.
- Preparing platform packaging and signed releases.
- Adding future enhancements such as attachments, richer Markdown workflows, and optional encryption.

## Inspiration

Kanoli takes inspiration from:

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
