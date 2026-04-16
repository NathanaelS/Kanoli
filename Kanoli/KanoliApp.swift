//
//  KanoliApp.swift
//  Kanoli
//
//  Created by Krysilis Productions on 4/9/26.
//

import Observation
import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

@main
struct KanoliApp: App {
    // Menu commands can be invoked even when the main window is closed. The
    // router carries the selected file URL into ContentView after reopening.
    @State private var commandRouter = AppCommandRouter()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(commandRouter)
        }
        .commands {
            KanoliFileCommands(commandRouter: commandRouter)
        }
    }
}

private struct KanoliFileCommands: Commands {
    let commandRouter: AppCommandRouter
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // Replace the default document actions so New/Open create or choose a
        // markdown board and then route it to the main Kanoli window.
        CommandGroup(replacing: .newItem) {
            Button("New") {
                presentCreatePanel()
            }
            .keyboardShortcut("n")

            Button("Open...") {
                presentOpenPanel()
            }
            .keyboardShortcut("o")
        }
    }

    private func presentOpenPanel() {
#if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.markdownText, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.directoryURL = defaultDocumentsDirectoryURL

        if panel.runModal() == .OK, let url = panel.url {
            open(url)
        }
#endif
    }

    private func presentCreatePanel() {
#if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.markdownText]
        panel.canCreateDirectories = true
        panel.directoryURL = defaultDocumentsDirectoryURL
        panel.nameFieldStringValue = "KanoliBoard.md"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try Data().write(to: url)
                }

                open(url)
            } catch {
                presentError(error)
            }
        }
#endif
    }

    private func open(_ url: URL) {
        commandRouter.pendingCommand = .loadFile(url)
        openWindow(id: "main")
    }

    private var defaultDocumentsDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
    }

    private func presentError(_ error: Error) {
#if os(macOS)
        let alert = NSAlert(error: error)
        alert.runModal()
#endif
    }
}

@Observable
final class AppCommandRouter {
    var pendingCommand: AppFileCommand?
}

enum AppFileCommand: Equatable {
    case loadFile(URL)
}
