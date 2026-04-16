import Foundation
#if os(macOS)
import AppKit
#endif
import Darwin

struct CrashLogNotice: Identifiable {
    let id = UUID()
    let logURL: URL

    var message: String {
        "Kanoli found a crash log from the previous run. Include this file when reporting the issue:\n\n\(logURL.path)"
    }
}

final class CrashLogStore {
    static let shared = CrashLogStore()

    nonisolated(unsafe) private static var crashLogFileDescriptor: Int32 = -1
    private static let uncaughtExceptionMarker = "\nCRASH: uncaught NSException\n"

    private let queue = DispatchQueue(label: "Kanoli.CrashLogStore")
    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let shownCrashLogKey = "shownCrashLogPath"
    private var currentLogURL: URL?
    private var isInstalled = false

    init(fileManager: FileManager = .default, userDefaults: UserDefaults = .standard) {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
    }

    func install() {
        guard !isInstalled else {
            return
        }

        isInstalled = true

        do {
            let logURL = try makeCurrentLogURL()
            currentLogURL = logURL
            try writeLaunchHeader(to: logURL)
            openCrashFileDescriptor(for: logURL)
            installCrashHandlers()
            pruneOldLogs()
        } catch {
            NSLog("Kanoli crash logging failed to initialize: \(error.localizedDescription)")
        }
    }

    func record(_ event: String, metadata: [String: String] = [:]) {
        guard let currentLogURL else {
            return
        }

        let line = formattedLine(event: event, metadata: metadata)
        queue.async { [fileManager] in
            guard let data = line.data(using: .utf8) else {
                return
            }

            if fileManager.fileExists(atPath: currentLogURL.path),
               let handle = try? FileHandle(forWritingTo: currentLogURL) {
                defer { try? handle.close() }
                do {
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                } catch {
                    NSLog("Kanoli crash logging failed to append: \(error.localizedDescription)")
                }
            } else {
                try? data.write(to: currentLogURL, options: .atomic)
            }
        }
    }

    func pendingLaunchNotice() -> CrashLogNotice? {
        guard let crashLogURL = newestCrashLogURL() else {
            return nil
        }

        let path = crashLogURL.path
        guard userDefaults.string(forKey: shownCrashLogKey) != path else {
            return nil
        }

        userDefaults.set(path, forKey: shownCrashLogKey)
        return CrashLogNotice(logURL: crashLogURL)
    }

    func revealLogsInFinder() {
#if os(macOS)
        guard let logsDirectoryURL = try? logsDirectoryURL() else {
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([logsDirectoryURL])
#endif
    }

    private func makeCurrentLogURL() throws -> URL {
        let directoryURL = try logsDirectoryURL()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let timestamp = CrashLogStore.fileTimestampFormatter.string(from: Date())
        return directoryURL.appendingPathComponent("Kanoli-\(timestamp).log")
    }

    private func logsDirectoryURL() throws -> URL {
        let applicationSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return applicationSupportURL
            .appendingPathComponent("Kanoli", isDirectory: true)
            .appendingPathComponent("CrashLogs", isDirectory: true)
    }

    private func writeLaunchHeader(to logURL: URL) throws {
        let header = """
        Kanoli Diagnostic Log
        Started: \(CrashLogStore.displayDateFormatter.string(from: Date()))
        App Version: \(appVersion)
        OS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Process: \(ProcessInfo.processInfo.processName) (pid \(ProcessInfo.processInfo.processIdentifier))

        """

        try header.write(to: logURL, atomically: true, encoding: .utf8)
    }

    private func openCrashFileDescriptor(for logURL: URL) {
        let descriptor = open(logURL.path, O_WRONLY | O_APPEND)
        if descriptor >= 0 {
            CrashLogStore.crashLogFileDescriptor = descriptor
        }
    }

    private func installCrashHandlers() {
        NSSetUncaughtExceptionHandler { exception in
            CrashLogStore.writeCrashMarker(CrashLogStore.uncaughtExceptionMarker)
            CrashLogStore.writeCrashMarker("Name: \(exception.name.rawValue)\n")
            CrashLogStore.writeCrashMarker("Reason: \(exception.reason ?? "Unknown")\n")
            CrashLogStore.writeCrashMarker(exception.callStackSymbols.joined(separator: "\n"))
            CrashLogStore.writeCrashMarker("\n")
        }

        signal(SIGABRT) { CrashLogStore.handleSignal($0) }
        signal(SIGILL) { CrashLogStore.handleSignal($0) }
        signal(SIGSEGV) { CrashLogStore.handleSignal($0) }
        signal(SIGFPE) { CrashLogStore.handleSignal($0) }
        signal(SIGBUS) { CrashLogStore.handleSignal($0) }
        signal(SIGTRAP) { CrashLogStore.handleSignal($0) }

#if os(macOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
#endif
    }

    @objc private func handleApplicationWillTerminate() {
        record("application will terminate")

        if CrashLogStore.crashLogFileDescriptor >= 0 {
            close(CrashLogStore.crashLogFileDescriptor)
            CrashLogStore.crashLogFileDescriptor = -1
        }
    }

    nonisolated private static func handleSignal(_ signal: Int32) {
        writeCrashMarker("\nCRASH: process terminated unexpectedly\n")
        writeCrashMarker("Signal: \(signal)\n")
        Darwin.signal(signal, SIG_DFL)
        Darwin.raise(signal)
    }

    nonisolated private static func writeCrashMarker(_ message: String) {
        guard crashLogFileDescriptor >= 0,
              let data = message.data(using: .utf8) else {
            return
        }

        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return
            }

            _ = Darwin.write(crashLogFileDescriptor, baseAddress, buffer.count)
        }
    }

    private func formattedLine(event: String, metadata: [String: String]) -> String {
        let timestamp = CrashLogStore.displayDateFormatter.string(from: Date())
        let metadataText = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        if metadataText.isEmpty {
            return "[\(timestamp)] \(event)\n"
        }

        return "[\(timestamp)] \(event) \(metadataText)\n"
    }

    private func newestCrashLogURL() -> URL? {
        guard let directoryURL = try? logsDirectoryURL(),
              let logURLs = try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
              ) else {
            return nil
        }

        return logURLs
            .filter { $0.pathExtension == "log" && logContainsCrashMarker($0) }
            .sorted { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate > rhsDate
            }
            .first
    }

    private func logContainsCrashMarker(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else {
            return false
        }

        return text.contains("CRASH:")
    }

    private func pruneOldLogs() {
        queue.async { [fileManager] in
            guard let directoryURL = try? self.logsDirectoryURL(),
                  let logURLs = try? fileManager.contentsOfDirectory(
                    at: directoryURL,
                    includingPropertiesForKeys: [.contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                  ) else {
                return
            }

            let sortedLogURLs = logURLs
                .filter { $0.pathExtension == "log" }
                .sorted { lhs, rhs in
                    let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                    let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                    return lhsDate > rhsDate
                }

            for url in sortedLogURLs.dropFirst(20) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = info?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private static let displayDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fileTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter
    }()
}
