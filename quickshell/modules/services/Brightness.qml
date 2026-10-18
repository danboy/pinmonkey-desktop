pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

// Mirrors the backlight device's sysfs value so brightness changes made
// outside quickshell (keyboard brightness keys, other tools) are reflected
// live, the same way Pipewire pushes external volume changes.
Singleton {
    id: root

    readonly property real brightness: maxValue > 0 ? currentValue / maxValue : 0
    property int currentValue: 0
    property int maxValue: 0
    property string devicePath: ""

    function setBrightness(value) {
        const pct = Math.round(Math.max(0, Math.min(1, value)) * 100);
        setProcess.command = ["brightnessctl", "-c", "backlight", "set", pct + "%"];
        setProcess.running = true;
    }

    Process {
        id: deviceProcess

        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name)
                    root.devicePath = "/sys/class/backlight/" + name;
            }
        }
    }

    Process {
        id: setProcess
    }

    FileView {
        path: root.devicePath ? root.devicePath + "/max_brightness" : ""
        onLoaded: root.maxValue = parseInt(text()) || 0
    }

    FileView {
        id: currentFile

        path: root.devicePath ? root.devicePath + "/brightness" : ""
        watchChanges: true

        onLoaded: root.currentValue = parseInt(text()) || 0
        onFileChanged: reload()
    }
}
