import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  private var nativeDialogsChannel: FlutterMethodChannel?
  private var activeSecurityScopedUrls: [URL] = []
  private let bookmarkStoreKey = "kanoli.securityScopedBookmarks.v1"

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    setupNativeDialogsChannel(with: flutterViewController)
    restoreSecurityScopedBookmarks()
    self.delegate = self

    super.awakeFromNib()
  }

  private func setupNativeDialogsChannel(with flutterViewController: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "kanoli/native_dialogs",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    nativeDialogsChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      self.handleNativeDialog(call: call, result: result)
    }
  }

  private func handleNativeDialog(call: FlutterMethodCall, result: @escaping FlutterResult) {
    debugLog("method=\(call.method)")
    switch call.method {
    case "openBoard":
      presentOpenPanel(extensions: ["md", "txt"], result: result)
    case "openJson":
      presentOpenPanel(extensions: ["json"], result: result)
    case "saveBoard":
      let args = call.arguments as? [String: Any]
      let suggestedName = args?["suggestedName"] as? String ?? "KanoliBoard.md"
      presentSavePanel(suggestedName: suggestedName, extensions: ["md"], result: result)
    case "saveTodoList":
      let args = call.arguments as? [String: Any]
      let suggestedName = args?["suggestedName"] as? String ?? "KanoliBoard.todo.txt"
      presentSavePanel(suggestedName: suggestedName, extensions: ["txt"], result: result)
    case "hideWindow":
      hideWindow(result: result)
    case "showWindow":
      showWindow(result: result)
    case "rememberPathAccess":
      let args = call.arguments as? [String: Any]
      let path = args?["path"] as? String ?? ""
      rememberPathAccess(path: path, result: result)
    case "revealInFinder":
      let args = call.arguments as? [String: Any]
      let path = args?["path"] as? String ?? ""
      revealInFinder(path: path, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentOpenPanel(extensions: [String], result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let panel = NSOpenPanel()
      panel.canChooseFiles = true
      panel.canChooseDirectories = false
      panel.allowsMultipleSelection = false
      self.applyAllowedTypes(panel: panel, extensions: extensions)
      NSApp.activate(ignoringOtherApps: true)
      self.makeKeyAndOrderFront(nil)
      self.debugLog("openPanel allowedFileTypes=\(String(describing: panel.allowedFileTypes))")
      let response = panel.runModal()
      self.debugLog("openPanel response=\(response.rawValue)")
      guard response == .OK else {
        self.debugLog("openPanel cancelled")
        result(nil)
        return
      }
      let path = panel.url?.path
      if let selectedUrl = panel.url {
        self.rememberSecurityScopedAccess(for: selectedUrl)
      }
      self.debugLog("openPanel selectedPath=\(path ?? "<nil>")")
      result(path)
    }
  }

  private func presentSavePanel(
    suggestedName: String,
    extensions: [String],
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      let panel = NSSavePanel()
      panel.canCreateDirectories = true
      panel.nameFieldStringValue = suggestedName
      self.applyAllowedTypes(panel: panel, extensions: extensions)
      panel.isExtensionHidden = false
      NSApp.activate(ignoringOtherApps: true)
      self.makeKeyAndOrderFront(nil)
      self.debugLog("savePanel suggestedName=\(suggestedName)")
      self.focusSavePanelNameField(retryCount: 12)
      let response = panel.runModal()
      self.debugLog("savePanel response=\(response.rawValue)")
      guard response == .OK else {
        self.debugLog("savePanel cancelled")
        result(nil)
        return
      }
      guard let selectedUrl = panel.url else {
        self.debugLog("savePanel selectedPath=<nil>")
        result(nil)
        return
      }

      let normalizedUrl = self.normalizedSaveURL(from: selectedUrl, preferredExtensions: extensions)
      self.rememberSecurityScopedAccessForSaveTarget(normalizedUrl)
      self.debugLog("savePanel selectedPath=\(normalizedUrl.path)")
      result(normalizedUrl.path)
    }
  }

  private func hideWindow(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      self.orderOut(nil)
      result(nil)
    }
  }

  private func showWindow(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      self.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      result(nil)
    }
  }

  private func rememberPathAccess(path: String, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let normalizedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !normalizedPath.isEmpty else {
        result(nil)
        return
      }

      let url = URL(fileURLWithPath: normalizedPath)
      if FileManager.default.fileExists(atPath: url.path) {
        self.rememberSecurityScopedAccess(for: url)
      } else {
        self.rememberSecurityScopedAccessForSaveTarget(url)
      }
      result(nil)
    }
  }

  private func revealInFinder(path: String, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let normalizedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !normalizedPath.isEmpty else {
        result(nil)
        return
      }
      let url = URL(fileURLWithPath: normalizedPath)
      NSWorkspace.shared.activateFileViewerSelecting([url])
      result(nil)
    }
  }

  private func debugLog(_ message: String) {
    NSLog("[KanoliDialog] %@", message)
  }

  private func applyAllowedTypes(panel: NSSavePanel, extensions: [String]) {
    if #available(macOS 11.0, *) {
      let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
      if !contentTypes.isEmpty {
        panel.allowedContentTypes = contentTypes
        return
      }
    }
    panel.allowedFileTypes = extensions
  }

  private func normalizedSaveURL(from url: URL, preferredExtensions: [String]) -> URL {
    if url.pathExtension.isEmpty, let first = preferredExtensions.first, !first.isEmpty {
      return url.appendingPathExtension(first)
    }
    return url
  }

  private func restoreSecurityScopedBookmarks() {
    guard let stored = UserDefaults.standard.dictionary(forKey: bookmarkStoreKey) as? [String: Data] else {
      return
    }

    var updated = stored
    var restoredCount = 0
    for (path, bookmarkData) in stored {
      var isStale = false
      do {
        let url = try URL(
          resolvingBookmarkData: bookmarkData,
          options: [.withSecurityScope],
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
        if url.startAccessingSecurityScopedResource() {
          activeSecurityScopedUrls.append(url)
          restoredCount += 1
        }
        if isStale {
          let refreshed = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
          )
          updated[path] = refreshed
        }
      } catch {
        updated.removeValue(forKey: path)
        debugLog("bookmark restore failed path=\(path) error=\(error.localizedDescription)")
      }
    }

    UserDefaults.standard.set(updated, forKey: bookmarkStoreKey)
    debugLog("bookmark restore count=\(restoredCount)")
  }

  private func rememberSecurityScopedAccess(for url: URL) {
    let didStart = url.startAccessingSecurityScopedResource()
    if didStart {
      activeSecurityScopedUrls.append(url)
    }

    do {
      let bookmark = try url.bookmarkData(
        options: [.withSecurityScope],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      var bookmarks = UserDefaults.standard.dictionary(forKey: bookmarkStoreKey) as? [String: Data] ?? [:]
      bookmarks[url.path] = bookmark
      UserDefaults.standard.set(bookmarks, forKey: bookmarkStoreKey)
      debugLog("bookmark saved path=\(url.path)")
    } catch {
      debugLog("bookmark save failed path=\(url.path) error=\(error.localizedDescription)")
    }
  }

  private func rememberSecurityScopedAccessForSaveTarget(_ fileUrl: URL) {
    if FileManager.default.fileExists(atPath: fileUrl.path) {
      rememberSecurityScopedAccess(for: fileUrl)
      return
    }

    let directoryUrl = fileUrl.deletingLastPathComponent()
    rememberSecurityScopedAccess(for: directoryUrl)
    debugLog("savePanel bookmark used parent directory=\(directoryUrl.path)")
    retryBookmarkForCreatedFile(fileUrl, attemptsRemaining: 20)
  }

  private func retryBookmarkForCreatedFile(_ fileUrl: URL, attemptsRemaining: Int) {
    guard attemptsRemaining > 0 else {
      debugLog("savePanel bookmark retry exhausted path=\(fileUrl.path)")
      return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      if FileManager.default.fileExists(atPath: fileUrl.path) {
        self.rememberSecurityScopedAccess(for: fileUrl)
        self.debugLog("savePanel bookmark retry succeeded path=\(fileUrl.path)")
        return
      }
      self.retryBookmarkForCreatedFile(fileUrl, attemptsRemaining: attemptsRemaining - 1)
    }
  }

  private func focusSavePanelNameField(retryCount: Int) {
    guard retryCount >= 0 else {
      return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
      guard let saveWindow = NSApp.keyWindow else {
        self.focusSavePanelNameField(retryCount: retryCount - 1)
        return
      }
      guard let textField = self.findEditableTextField(in: saveWindow.contentView) else {
        self.focusSavePanelNameField(retryCount: retryCount - 1)
        return
      }
      saveWindow.makeFirstResponder(textField)
      textField.selectText(nil)
      self.debugLog("savePanel focused name field")
    }
  }

  private func findEditableTextField(in view: NSView?) -> NSTextField? {
    guard let view = view else {
      return nil
    }
    if let textField = view as? NSTextField, textField.isEditable, !textField.isHidden {
      return textField
    }
    for subview in view.subviews {
      if let textField = findEditableTextField(in: subview) {
        return textField
      }
    }
    return nil
  }
}

extension MainFlutterWindow: NSWindowDelegate {
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    sender.orderOut(nil)
    return false
  }
}
