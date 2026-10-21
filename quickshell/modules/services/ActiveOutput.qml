pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tracks which monitor (niri "output") currently has focus, via the same niri event-stream
// IPC pattern as ActiveWindow.qml. Needed because Quickshell.screens[0] is just "whatever
// niri enumerated first" - stable, but not tied to where the user actually is - so surfaces
// that should appear "where you're looking" (the launcher) need this instead.
Singleton {
    id: root

    // workspace id -> output name, kept in sync so a WorkspaceActivated event (which only
    // carries the workspace id) can be resolved to an output.
    property var workspaceOutputs: ({})
    property string name: ""

    readonly property var screen: {
        for (const s of Quickshell.screens)
            if (s.name === root.name)
                return s;
        return Quickshell.screens[0] ?? null;
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

        if (msg.WorkspacesChanged) {
            const map = {};
            for (const w of msg.WorkspacesChanged.workspaces) {
                map[w.id] = w.output;
                if (w.is_focused)
                    root.name = w.output;
            }
            root.workspaceOutputs = map;
        } else if (msg.WorkspaceActivated && msg.WorkspaceActivated.focused) {
            const output = root.workspaceOutputs[msg.WorkspaceActivated.id];
            if (output)
                root.name = output;
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
