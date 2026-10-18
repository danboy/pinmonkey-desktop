pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Small, user-configurable preferences that need to persist across restarts (unlike
// Config.qml, which is all compile-time-fixed readonly design tokens). Backed by a local,
// gitignored JSON file at the repo root - not a niri/system setting, so it has nothing to do
// with NiriConfig.qml.
Singleton {
    id: root

    readonly property string settingsPath: Quickshell.env("HOME") + "/Projects/pinmonkey-desktop/.shell-settings.json"

    property bool loaded: false
    property bool idleLockEnabled: true
    property int idleLockMinutes: 10

    function save() {
        // Don't overwrite the file with defaults before we've actually read whatever's
        // already there - onLoaded/onLoadFailed below always fires first and flips this.
        if (!root.loaded)
            return;
        file.setText(JSON.stringify({
            idleLockEnabled: root.idleLockEnabled,
            idleLockMinutes: root.idleLockMinutes
        }, null, 2));
    }

    onIdleLockEnabledChanged: root.save()
    onIdleLockMinutesChanged: root.save()

    FileView {
        id: file

        path: root.settingsPath
        watchChanges: true

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (typeof data.idleLockEnabled === "boolean")
                    root.idleLockEnabled = data.idleLockEnabled;
                if (typeof data.idleLockMinutes === "number")
                    root.idleLockMinutes = data.idleLockMinutes;
            } catch (e) {
                console.log("ShellSettings: parse error", e);
            }
            root.loaded = true;
        }

        onLoadFailed: error => {
            // First run - no file yet. Use the defaults above and create it.
            root.loaded = true;
            root.save();
        }
    }
}
