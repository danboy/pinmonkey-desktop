pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

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
    property bool notificationsDndEnabled: false
    property bool stayAwakeEnabled: false

    // One widget type per column slot, 3 slots per row. Adjacent slots in a row sharing the
    // same type are rendered as a single spanning cell (see LockGrid.qml) - that's the only
    // notion of "span" this model has, so the data stays a plain flat grid with no separate
    // span field that could drift out of sync with the column count.
    property var lockGridRows: [
        ["weather", "news", "news"],
        ["holiday", "transit", "transit"],
        ["calendar", "calendar", "notifications"]
    ]

    // Mutators always rebuild the array (rather than mutating in place) so the
    // lockGridRowsChanged signal - and therefore save() and the lock screen's binding - fires.
    function setLockGridCell(rowIndex, columnIndex, type) {
        const rows = root.lockGridRows.map(row => [...row]);
        rows[rowIndex][columnIndex] = type;
        root.lockGridRows = rows;
    }

    function addLockGridRow() {
        root.lockGridRows = [...root.lockGridRows, ["empty", "empty", "empty"]];
    }

    function removeLockGridRow(rowIndex) {
        root.lockGridRows = root.lockGridRows.filter((_, i) => i !== rowIndex);
    }

    // Freeform widgets shown on the desktop widget layer (see DesktopWidgetLayer.qml) -
    // unlike the lock grid, these aren't slotted into columns, so each one just carries its
    // own absolute rect.
    property var desktopWidgets: []

    function addDesktopWidget(type) {
        const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
        root.desktopWidgets = [...root.desktopWidgets, {
                id,
                type,
                x: 80,
                y: 80,
                width: Config.desktopWidgetDefaultWidth,
                height: Config.desktopWidgetDefaultHeight
            }];
    }

    function removeDesktopWidget(id) {
        root.desktopWidgets = root.desktopWidgets.filter(w => w.id !== id);
    }

    function updateDesktopWidgetRect(id, x, y, width, height) {
        root.desktopWidgets = root.desktopWidgets.map(w => w.id === id ? Object.assign({}, w, {
                x,
                y,
                width,
                height
            }) : w);
    }

    function save() {
        // Don't overwrite the file with defaults before we've actually read whatever's
        // already there - onLoaded/onLoadFailed below always fires first and flips this.
        if (!root.loaded)
            return;
        file.setText(JSON.stringify({
            idleLockEnabled: root.idleLockEnabled,
            idleLockMinutes: root.idleLockMinutes,
            notificationsDndEnabled: root.notificationsDndEnabled,
            stayAwakeEnabled: root.stayAwakeEnabled,
            lockGridRows: root.lockGridRows,
            desktopWidgets: root.desktopWidgets
        }, null, 2));
    }

    onIdleLockEnabledChanged: root.save()
    onIdleLockMinutesChanged: root.save()
    onNotificationsDndEnabledChanged: root.save()
    onStayAwakeEnabledChanged: root.save()
    onLockGridRowsChanged: root.save()
    onDesktopWidgetsChanged: root.save()

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
                if (typeof data.notificationsDndEnabled === "boolean")
                    root.notificationsDndEnabled = data.notificationsDndEnabled;
                if (typeof data.stayAwakeEnabled === "boolean")
                    root.stayAwakeEnabled = data.stayAwakeEnabled;
                if (Array.isArray(data.lockGridRows))
                    root.lockGridRows = data.lockGridRows;
                if (Array.isArray(data.desktopWidgets))
                    root.desktopWidgets = data.desktopWidgets;
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
