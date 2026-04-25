import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  private var nativeDialogsChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    setupNativeDialogsChannel(with: flutterViewController)
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
      presentSavePanel(suggestedName: suggestedName, result: result)
    case "hideWindow":
      hideWindow(result: result)
    case "showWindow":
      showWindow(result: result)
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
      self.debugLog("openPanel selectedPath=\(path ?? "<nil>")")
      result(path)
    }
  }

  private func presentSavePanel(suggestedName: String, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let panel = NSSavePanel()
      panel.canCreateDirectories = true
      panel.nameFieldStringValue = suggestedName
      self.applyAllowedTypes(panel: panel, extensions: ["md"])
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
      let path = panel.url?.path
      self.debugLog("savePanel selectedPath=\(path ?? "<nil>")")
      result(path)
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
