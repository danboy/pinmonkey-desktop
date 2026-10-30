pragma Singleton
import Quickshell

// Drives PowerMenuModal.qml's full-screen surface from the control center's button,
// same pattern as SettingsState.
Singleton {
    property bool open: false
}
