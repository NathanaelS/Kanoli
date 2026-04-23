import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var nativeDialogsChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    setupNativeDialogsChannel(with: flutterViewController)

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
      panel.beginSheetModal(for: self) { response in
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
      panel.beginSheetModal(for: self) { response in
        guard response == .OK else {
          result(nil)
          return
        }
        result(panel.url?.path)
      }
    }
  }
}
