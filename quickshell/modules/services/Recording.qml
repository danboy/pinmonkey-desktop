pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Owns the wf-recorder process so both the screenshot panel (which starts recordings) and
// the bar's recording indicator (which shows elapsed time and stops it) share one source of
// truth.
Singleton {
    id: root

    readonly property bool active: process.running
    property string outputPath: ""
    property int elapsedSeconds: 0

    function start(withAudio) {
        if (active)
            return;
        const dir = Quickshell.env("HOME") + "/Videos/Screencasts";
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        root.outputPath = `${dir}/Recording from ${stamp}.mp4`;
        mkdirProcess.command = ["mkdir", "-p", dir];
        mkdirProcess.running = true;
        const cmd = ["wf-recorder", "-f", root.outputPath];
        if (withAudio)
            cmd.push("-a");
        process.command = cmd;
        root.elapsedSeconds = 0;
        process.running = true;
    }

    function stop() {
        if (!active)
            return;
        // SIGINT (not a hard kill) so wf-recorder finalizes the video file properly.
        process.signal(2);
    }

    Process {
        id: mkdirProcess
    }

    Process {
        id: process

        onRunningChanged: if (!running)
            root.outputPath = ""
        stderr: StdioCollector {
            onStreamFinished: if (text.length > 0)
                console.log("wf-recorder:", text)
        }
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: root.elapsedSeconds += 1
    }
}
