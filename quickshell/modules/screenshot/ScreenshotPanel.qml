import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.modules.components
import qs.modules.services

Item {
    id: root

    property string mode: "screenshot"
    property string screenshotMode: "screen"
    property bool showPointer: true
    property int delaySeconds: 0
    property bool recordAudio: false

    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    function close() {
        ScreenshotState.open = false;
    }

    Connections {
        target: PopupCoordinator
        function onCloseAll() {
            root.close();
        }
    }

    IpcHandler {
        target: "screenshot"

        function show(): void {
            ScreenshotState.open = true;
        }

        function hide(): void {
            root.close();
        }

        function screen(): void {
            root.captureNiri(["niri", "msg", "action", "screenshot-screen"]);
        }

        function window(): void {
            root.captureNiri(["niri", "msg", "action", "screenshot-window"]);
        }
    }

    function notifyFile(dir, label) {
        lsProcess.command = ["sh", "-c", `ls -t ${JSON.stringify(dir)} | head -1`];
        lsProcess.label = label;
        lsProcess.dir = dir;
        lsProcess.running = true;
    }

    Process {
        id: lsProcess

        property string label: ""
        property string dir: ""

        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name.length === 0)
                    return;
                notifyProcess.command = ["notify-send", lsProcess.label, name, "-i", "image-x-generic"];
                notifyProcess.running = true;
            }
        }
    }

    Process {
        id: notifyProcess
    }

    Process {
        id: captureProcess
    }

    // Screen/Window capture is synchronous (niri saves+copies immediately); Selection opens
    // niri's own interactive overlay and returns right away while the user is still picking,
    // so there's no reliable "done" moment to hook a notification to - only Screen/Window get
    // a post-capture notification.
    function captureNiri(command) {
        root.close();
        // Closing the panel doesn't unmap the Wayland surface instantly - the compositor
        // needs a moment to actually repaint without it. Running the capture in the same
        // tick grabbed a frame with the panel still on screen, baking it into the
        // screenshot. A short delay gives the unmap time to land first.
        captureTimer.pendingCommand = command;
        captureTimer.start();
    }

    Timer {
        id: captureTimer

        property var pendingCommand: null
        interval: 120
        repeat: false
        onTriggered: {
            captureProcess.command = pendingCommand;
            captureProcess.running = true;
            notifyTimer.start();
        }
    }

    Timer {
        id: notifyTimer

        interval: 600
        onTriggered: root.notifyFile(root.screenshotDir, "Screenshot captured")
    }

    function takeScreenshot(action) {
        const run = () => {
            if (action === "screen")
                root.captureNiri(["niri", "msg", "action", "screenshot-screen", "--show-pointer", root.showPointer ? "true" : "false"]);
            else if (action === "window")
                root.captureNiri(["niri", "msg", "action", "screenshot-window"]);
            else
                root.captureNiri(["niri", "msg", "action", "screenshot", "--show-pointer", root.showPointer ? "true" : "false"]);
        };
        if (root.delaySeconds > 0) {
            root.close();
            delayTimer.triggeredAction = run;
            delayTimer.interval = root.delaySeconds * 1000;
            delayTimer.start();
        } else {
            run();
        }
    }

    Timer {
        id: delayTimer

        property var triggeredAction: null
        repeat: false
        onTriggered: if (triggeredAction)
            triggeredAction()
    }

    function toggleRecording() {
        if (Recording.active) {
            Recording.stop();
            root.close();
            recordingStopTimer.start();
        } else {
            Recording.start(root.recordAudio);
            root.close();
        }
    }

    Timer {
        id: recordingStopTimer

        interval: 500
        onTriggered: root.notifyFile(Quickshell.env("HOME") + "/Videos/Screencasts", "Recording saved")
    }

    // Loader-gated so the layer-shell surface (and its on-demand keyboard focus) is fully
    // destroyed on close rather than left mapped-but-hidden - see Launcher.qml for the same
    // reasoning.
    Loader {
        active: ScreenshotState.open

        sourceComponent: WlrLayershell {
            screen: Quickshell.screens[0]
            layer: WlrLayer.Overlay
            namespace: "screenshot"
            color: "transparent"
            keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            FocusScope {
                id: focusScope

                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: root.close()

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Config.screenshotWidth
                    implicitHeight: content.implicitHeight + Config.popupMargin * 2
                    radius: Config.radiusLarge
                    color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
                    border.width: Config.borderWidth
                    border.color: Config.colDivider

                    MouseArea {
                        // swallow clicks so the background MouseArea doesn't close the panel
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: content

                        anchors.fill: parent
                        anchors.margins: Config.popupMargin
                        spacing: Config.spacingLarge

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Config.spacingSmall

                            Repeater {
                                model: [
                                    {
                                        id: "screenshot",
                                        label: "Screenshot",
                                        icon: "camera-photo-symbolic"
                                    },
                                    {
                                        id: "recording",
                                        label: "Recording",
                                        icon: "camera-video-symbolic"
                                    }
                                ]

                                delegate: Rectangle {
                                    id: modeTab

                                    required property var modelData
                                    readonly property bool active: root.mode === modelData.id

                                    Layout.fillWidth: true
                                    implicitHeight: Config.settingsTabHeight
                                    radius: Config.radiusMedium
                                    color: modeTab.active ? Config.colAccent : Config.colSurfaceVariant
                                    border.width: Config.borderWidth
                                    border.color: modeTab.active ? Config.colBorderAccent : Config.colBorder

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: Config.spacingSmall

                                        IconImage {
                                            source: Quickshell.iconPath(modeTab.modelData.icon)
                                            implicitSize: Config.iconSizeSmall
                                        }

                                        Text {
                                            text: modeTab.modelData.label
                                            font.family: Config.fontFamily
                                            font.bold: modeTab.active
                                            font.pixelSize: Config.fontSizeCaption
                                            color: modeTab.active ? Config.colAccentText : Config.colText
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.mode = modeTab.modelData.id
                                    }
                                }
                            }
                        }

                        // --- Screenshot mode ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.mode === "screenshot"
                            spacing: Config.spacingLarge

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Config.spacingSmall

                                Repeater {
                                    model: [
                                        {
                                            id: "screen",
                                            label: "Screen",
                                            icon: "computer-symbolic"
                                        },
                                        {
                                            id: "window",
                                            label: "Window",
                                            icon: "window-new-symbolic"
                                        },
                                        {
                                            id: "selection",
                                            label: "Selection",
                                            icon: "selection-symbolic"
                                        }
                                    ]

                                    delegate: Rectangle {
                                        id: captureMode

                                        required property var modelData
                                        readonly property bool active: root.screenshotMode === modelData.id

                                        Layout.fillWidth: true
                                        implicitHeight: Config.screenshotModeButtonHeight
                                        radius: Config.radiusMedium
                                        color: captureMode.active ? Config.colAccent : Config.colSurfaceVariant
                                        border.width: Config.borderWidth
                                        border.color: captureMode.active ? Config.colBorderAccent : Config.colBorder

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: Config.spacingXSmall

                                            IconImage {
                                                Layout.alignment: Qt.AlignHCenter
                                                source: Quickshell.iconPath(captureMode.modelData.icon)
                                                implicitSize: Config.iconSizeMedium
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: captureMode.modelData.label
                                                font.family: Config.fontFamily
                                                font.bold: captureMode.active
                                                font.pixelSize: Config.fontSizeCaption
                                                color: captureMode.active ? Config.colAccentText : Config.colText
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.screenshotMode = captureMode.modelData.id
                                        }
                                    }
                                }
                            }

                            QuickToggleTile {
                                iconName: "input-mouse-symbolic"
                                on: root.showPointer
                                title: "Show pointer"
                                subtitle: on ? "On" : "Off"
                                onToggled: root.showPointer = !root.showPointer
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Config.spacingSmall

                                IconImage {
                                    source: Quickshell.iconPath("alarm-symbolic")
                                    implicitSize: Config.iconSizeSmall
                                }

                                Text {
                                    text: "Delay"
                                    font.family: Config.fontFamily
                                    font.pixelSize: Config.fontSizeCaption
                                    color: Config.colSubtext
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Repeater {
                                    model: [0, 3, 5, 10]

                                    delegate: Text {
                                        required property int modelData

                                        text: modelData === 0 ? "Off" : modelData + "s"
                                        font.family: Config.fontFamily
                                        font.bold: root.delaySeconds === modelData
                                        font.pixelSize: Config.fontSizeCaption
                                        color: root.delaySeconds === modelData ? Config.colAccent : Config.colSubtext

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.delaySeconds = parent.modelData
                                        }
                                    }
                                }
                            }
                        }

                        // --- Recording mode ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.mode === "recording"
                            spacing: Config.spacingLarge

                            QuickToggleTile {
                                iconName: "audio-input-microphone-symbolic"
                                on: root.recordAudio
                                title: "Record audio"
                                subtitle: on ? "On" : "Off"
                                onToggled: root.recordAudio = !root.recordAudio
                            }

                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                visible: Recording.active
                                text: "Recording… " + Math.floor(Recording.elapsedSeconds / 60) + ":" + String(Recording.elapsedSeconds % 60).padStart(2, "0")
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeCaption
                                color: Config.colDanger
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Config.screenshotCaptureButtonHeight
                            radius: Config.radiusMedium
                            color: Config.colAccent
                            visible: root.mode === "screenshot" || !Recording.active

                            Text {
                                anchors.centerIn: parent
                                text: root.mode === "recording" ? "Start Recording" : "Take Screenshot"
                                font.family: Config.fontFamily
                                font.bold: true
                                font.pixelSize: Config.fontSizeBody
                                color: Config.colAccentText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.mode === "recording" ? root.toggleRecording() : root.takeScreenshot(root.screenshotMode)
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Config.screenshotCaptureButtonHeight
                            radius: Config.radiusMedium
                            color: Config.colDanger
                            visible: root.mode === "recording" && Recording.active

                            Text {
                                anchors.centerIn: parent
                                text: "Stop Recording"
                                font.family: Config.fontFamily
                                font.bold: true
                                font.pixelSize: Config.fontSizeBody
                                color: Config.colAccentText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleRecording()
                            }
                        }
                    }
                }
            }
        }
    }
}
