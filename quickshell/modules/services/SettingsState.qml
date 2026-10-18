pragma Singleton
import Quickshell

// Shared so WifiToggle/BluetoothToggle can open the settings panel on a specific tab,
// in-process and synchronously (same reasoning as LauncherState).
Singleton {
    property bool open: false
    property string tab: "network"

    function openOn(tabName) {
        tab = tabName;
        open = true;
    }
}
