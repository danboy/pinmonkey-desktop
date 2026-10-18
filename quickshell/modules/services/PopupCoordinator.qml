pragma Singleton
import Quickshell

// Lets the lock screen force-close any open AnchoredPopup (ControlCenter, InfoPanel, ...)
// before locking. These are PopupWindow-based with grabFocus: true - if left open, the
// popup's surface stays mapped and keeps the Wayland keyboard grab, competing with the
// new lock surface for input (same class of bug as the launcher, see
// modules/services/LauncherState.qml).
Singleton {
    signal closeAll
}
