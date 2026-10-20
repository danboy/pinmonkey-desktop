pragma Singleton
import QtQuick
import Quickshell
import qs

// Shared so the bar's toggle button and DesktopWidgetLayer.qml can agree on open/closed
// in-process and synchronously (same reasoning as LauncherState/SettingsState).
//
// Mutate only through toggle()/show()/hide(), never by assigning `open` directly: opening
// this layer (re)creates a real layer-shell surface plus its client-side blur capture (see
// BlurredBackdrop.qml), and flipping that faster than one close animation can settle -
// mashing the bar icon or spamming the IPC toggle - was crashing quickshell outright. The
// debounce below caps how fast any caller can drive it, instead of relying on each caller
// to pace itself.
Singleton {
    id: root

    property bool open: false
    property bool debounced: false

    function show(): void {
        root.setOpen(true);
    }

    function hide(): void {
        root.setOpen(false);
    }

    function toggle(): void {
        root.setOpen(!root.open);
    }

    function setOpen(value: bool): void {
        if (root.debounced || value === root.open)
            return;
        root.open = value;
        root.debounced = true;
        debounceTimer.restart();
    }

    Timer {
        id: debounceTimer

        interval: Config.animationDurationMs
        onTriggered: root.debounced = false
    }
}
