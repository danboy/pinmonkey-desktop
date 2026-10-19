pragma Singleton
import Quickshell

// Shared so the bar's toggle button and DesktopWidgetLayer.qml can agree on open/closed
// in-process and synchronously (same reasoning as LauncherState/SettingsState).
Singleton {
    property bool open: false
}
