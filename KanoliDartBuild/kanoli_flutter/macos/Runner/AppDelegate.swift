import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "kanoli/native_dialogs",
        binaryMessenger: controller.engine.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(nil)
          return
        }
        self.handleNativeDialog(call: call, result: result)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func handleNativeDialog(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openBoard":
      presentOpenPanel(extensions: ["md", "txt"], result: result)
    case "openJson":
      presentOpenPanel(extensions: ["json"], result: result)
    case "saveBoard":
      let args = call.arguments as? [String: Any]
      let suggestedName = args?["suggestedName"] as? String ?? "KanoliBoard.md"
      presentSavePanel(suggestedName: suggestedName, result: result)
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
      panel.allowedFileTypes = extensions
      panel.begin { response in
        guard response == .OK else {
          result(nil)
          return
        }
        result(panel.url?.path)
      }
    }
  }

  private func presentSavePanel(suggestedName: String, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let panel = NSSavePanel()
      panel.canCreateDirectories = true
      panel.nameFieldStringValue = suggestedName
      panel.allowedFileTypes = ["md"]
      panel.begin { response in
        guard response == .OK else {
          result(nil)
          return
        }
        result(panel.url?.path)
      }
    }
  }
}
