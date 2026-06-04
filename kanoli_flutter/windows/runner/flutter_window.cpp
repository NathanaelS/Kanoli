#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {

constexpr char kNativeDialogsChannelName[] = "kanoli/native_dialogs";
constexpr char kMenuActionMethod[] = "menuAction";
constexpr char kSyncWindowsMenuStateMethod[] = "setWindowsMenuState";

std::optional<std::string> MenuActionForCommand(UINT command_id) {
  switch (command_id) {
    case IDM_FILE_CREATE_BOARD:
      return "createBoard";
    case IDM_FILE_OPEN_BOARD:
      return "openBoard";
    case IDM_FILE_IMPORT_TRELLO_JSON:
      return "importBoard";
    case IDM_FILE_CLOSE_ACTIVE_BOARD:
      return "closeActiveBoard";
    case IDM_FILE_CLOSE_WINDOW:
      return "closeWindow";
    case IDM_VIEW_TOGGLE_TAB_BAR:
      return "toggleBoardTabBar";
    case IDM_TOOLS_PRIVACY_SETTINGS:
      return "openPrivacySettings";
    case IDM_TOOLS_DIAGNOSTICS:
      return "openDiagnostics";
    case IDM_TOOLS_REVEAL_ACTIVE_BOARD:
      return "revealActiveBoard";
    case IDM_TOOLS_COPY_ACTIVE_BOARD:
      return "copyActiveBoardPath";
    case IDM_EDIT_SEARCH_CARDS:
      return "searchCards";
    case IDM_EDIT_UNDO:
      return "undo";
    case IDM_EDIT_REDO:
      return "redo";
    case IDM_EDIT_CUT:
      return "cut";
    case IDM_EDIT_COPY:
      return "copy";
    case IDM_EDIT_PASTE:
      return "paste";
    case IDM_EDIT_SELECT_ALL:
      return "selectAll";
  }

  return std::nullopt;
}

bool RevealPathInExplorer(const std::wstring& path) {
  const std::wstring explorer_args = L"/select,\"" + path + L"\"";
  const auto instance =
      reinterpret_cast<INT_PTR>(ShellExecuteW(nullptr, L"open", L"explorer.exe",
                                              explorer_args.c_str(), nullptr,
                                              SW_SHOWNORMAL));
  return instance > 32;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }

  const int required_size = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, value.c_str(),
      static_cast<int>(value.size()), nullptr, 0);
  if (required_size <= 0) {
    return std::wstring();
  }

  std::wstring converted(required_size, L'\0');
  const int converted_size = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, value.c_str(),
      static_cast<int>(value.size()), converted.data(), required_size);
  if (converted_size != required_size) {
    return std::wstring();
  }

  return converted;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetUpMenuChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  native_menu_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_COMMAND && lparam == 0) {
    if (HandleMenuCommand(LOWORD(wparam))) {
      return 0;
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::SetUpMenuChannel() {
  native_menu_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), kNativeDialogsChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  native_menu_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == kSyncWindowsMenuStateMethod) {
          const auto* state =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (state == nullptr) {
            result->Error("bad-args",
                          "setWindowsMenuState expects a map argument.");
            return;
          }
          UpdateMenuState(*state);
          result->Success();
          return;
        }

        if (call.method_name() == "revealInFinder") {
          const auto* arguments =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments == nullptr) {
            result->Error("bad-args", "revealInFinder expects a map argument.");
            return;
          }

          const auto path_it = arguments->find(flutter::EncodableValue("path"));
          if (path_it == arguments->end()) {
            result->Error("bad-args", "revealInFinder requires a path.");
            return;
          }

          const auto* path = std::get_if<std::string>(&path_it->second);
          if (path == nullptr || path->empty()) {
            result->Error("bad-args", "revealInFinder requires a string path.");
            return;
          }

          const std::wstring wide_path = Utf8ToWide(*path);
          if (wide_path.empty() || !RevealPathInExplorer(wide_path)) {
            result->Error("shell-exec-failed",
                          "Failed to reveal the requested file in Explorer.");
            return;
          }

          result->Success();
          return;
        }

        result->NotImplemented();
      });
}

bool FlutterWindow::HandleMenuCommand(UINT command_id) {
  const auto action = MenuActionForCommand(command_id);
  if (!action.has_value()) {
    return false;
  }

  DispatchMenuAction(*action);
  return true;
}

void FlutterWindow::DispatchMenuAction(const std::string& action) {
  if (!native_menu_channel_) {
    return;
  }

  native_menu_channel_->InvokeMethod(
      kMenuActionMethod,
      std::make_unique<flutter::EncodableValue>(action));
}

void FlutterWindow::UpdateMenuState(const flutter::EncodableMap& state) {
  const auto show_tab_bar_it =
      state.find(flutter::EncodableValue("showBoardTabBar"));
  if (show_tab_bar_it == state.end()) {
    return;
  }

  const auto* show_tab_bar = std::get_if<bool>(&show_tab_bar_it->second);
  if (show_tab_bar == nullptr) {
    return;
  }

  UpdateToggleTabBarLabel(*show_tab_bar);
}

void FlutterWindow::UpdateToggleTabBarLabel(bool show_board_tab_bar) {
  HMENU menu = GetMenu(GetHandle());
  if (menu == nullptr) {
    return;
  }

  const wchar_t* label =
      show_board_tab_bar ? L"Hide Tab Bar" : L"Show Tab Bar";
  ModifyMenuW(menu, IDM_VIEW_TOGGLE_TAB_BAR,
              MF_BYCOMMAND | MF_STRING, IDM_VIEW_TOGGLE_TAB_BAR, label);
  DrawMenuBar(GetHandle());
}
