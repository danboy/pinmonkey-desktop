pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tracks the focused window's title via niri's own event-stream IPC (NDJSON over
// `niri msg --json event-stream`) rather than polling `niri msg focused-window` - the
// stream pushes WindowFocusChanged/WindowOpenedOrChanged/WindowClosed events as they happen,
// so the bar updates immediately instead of on some poll interval.
Singleton {
    id: root

    property var windows: ({})
    property var focusedId: null

    readonly property string title: {
        if (root.focusedId === null)
            return "";
        const w = root.windows[root.focusedId];
        return w ? w.title : "";
    }

    function handleLine(line) {
        if (line.length === 0)
            return;
        let msg;
        try {
            msg = JSON.parse(line);
        } catch (e) {
            return;
        }

        if (msg.WindowsChanged) {
            const map = {};
            for (const w of msg.WindowsChanged.windows)
                map[w.id] = w;
            root.windows = map;
        } else if (msg.WindowOpenedOrChanged) {
            const w = msg.WindowOpenedOrChanged.window;
            const map = Object.assign({}, root.windows);
            map[w.id] = w;
            root.windows = map;
        } else if (msg.WindowClosed) {
            const map = Object.assign({}, root.windows);
            delete map[msg.WindowClosed.id];
            root.windows = map;
        } else if (msg.WindowFocusChanged) {
            root.focusedId = msg.WindowFocusChanged.id;
        }
    }

    Process {
        id: proc

        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: line => root.handleLine(line)
        }
    }
}
