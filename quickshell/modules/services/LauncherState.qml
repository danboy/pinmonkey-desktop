pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Shared so other components (e.g. the lock screen) can close the launcher synchronously,
// in-process, instead of racing an async IPC round-trip against something time-sensitive.
Singleton {
    id: root

    property bool open: false

    readonly property string historyPath: Quickshell.env("HOME") + "/Projects/pinmonkey-desktop/.launcher-history.json"

    property bool historyLoaded: false

    // Per-search selection counts: { "<normalized query>": { "<appId>": count } }. "" is the
    // key for the no-query (empty search box) case, so frequently-launched apps still bubble
    // up before the user types anything.
    property var history: ({})

    function normalize(query) {
        return (query || "").trim().toLowerCase();
    }

    // How many times `appId` was picked after typing `query` - used to sort that query's
    // results, not just a global popularity count, since "ff" might mean Firefox but "term"
    // should favor a terminal.
    function scoreFor(query, appId) {
        const bucket = root.history[root.normalize(query)];
        return bucket ? (bucket[appId] || 0) : 0;
    }

    function recordSelection(query, appId) {
        if (!appId)
            return;
        const key = root.normalize(query);
        const history = Object.assign({}, root.history);
        const bucket = Object.assign({}, history[key]);
        bucket[appId] = (bucket[appId] || 0) + 1;
        history[key] = bucket;
        root.history = history;
    }

    function save() {
        // Don't overwrite the file with defaults before we've actually read whatever's
        // already there - onLoaded/onLoadFailed below always fires first and flips this.
        if (!root.historyLoaded)
            return;
        historyFile.setText(JSON.stringify(root.history, null, 2));
    }

    onHistoryChanged: root.save()

    FileView {
        id: historyFile

        path: root.historyPath
        watchChanges: true

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data && typeof data === "object")
                    root.history = data;
            } catch (e) {
                console.log("LauncherState: history parse error", e);
            }
            root.historyLoaded = true;
        }

        onLoadFailed: error => {
            // First run - no file yet. Use the defaults above and create it.
            root.historyLoaded = true;
            root.save();
        }
    }
}
