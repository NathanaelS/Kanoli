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

    init() {
        CrashLogStore.shared.install()
        CrashLogStore.shared.record("application initialized")

#if os(macOS)
        // Ensure the Dock icon uses the bundled AppIcon asset even when the
        // system icon cache lags behind recent asset updates.
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }
#endif
    }

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

            Button("Import Trello Board...") {
                presentImportJSONPanel()
            }
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

    private func presentImportJSONPanel() {
#if os(macOS)
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.directoryURL = defaultDocumentsDirectoryURL

        guard openPanel.runModal() == .OK, let jsonURL = openPanel.url else {
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.markdownText]
        savePanel.canCreateDirectories = true
        savePanel.directoryURL = jsonURL.deletingLastPathComponent()
        savePanel.nameFieldStringValue = jsonURL
            .deletingPathExtension()
            .appendingPathExtension("md")
            .lastPathComponent

        guard savePanel.runModal() == .OK, let boardURL = savePanel.url else {
            return
        }

        do {
            try JSONBoardStore.importBoard(from: jsonURL, to: boardURL)
            open(boardURL)
        } catch {
            presentError(error)
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
