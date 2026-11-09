import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs

// Our own selection screenshot UI, replacing niri's native one (compiled into the niri
// binary itself - no way to add resize handles to that from here). Draw once to set the
// initial box, then drag its 8 handles or its body to adjust before confirming. The
// captured frame is a single still (ScreencopyView, live: false) taken once up front and
// reused for both the live dim/preview and the final crop, rather than re-capturing -
// capturing again at confirm time would bake this very UI into the shot.
Item {
    id: root

    signal closed()
    signal reallyDestroyed()

    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property var targetScreen: Quickshell.screens[0]

    property bool hasFrame: false
    property bool dragging: false
    property bool adjusting: false
    property real selX: 0
    property real selY: 0
    property real selW: 0
    property real selH: 0
    readonly property int minSelectionSize: 20
    readonly property int handleSize: 14

    function close() {
        root.closed();
    }

    // Capture context isn't realized synchronously on creation (same race as
    // BlurredBackdrop's) - deferred a tick with Qt.callLater.
    Component.onCompleted: Qt.callLater(backgroundCapture.captureFrame)

    function confirm() {
        if (!root.hasFrame || root.selW < root.minSelectionSize || root.selH < root.minSelectionSize)
            return;
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh-mm-ss");
        const path = `${root.screenshotDir}/Screenshot from ${stamp}.png`;
        mkdirProcess.command = ["mkdir", "-p", root.screenshotDir];
        mkdirProcess.running = true;

        // Resize the (normally full-screen, clip-is-a-no-op) crop host down to just the
        // selection and shift the capture underneath it so only that region lands inside -
        // then grab it. The overlay closes right after, so the one-frame visual jump this
        // causes never actually gets seen.
        cropFrame.width = root.selW;
        cropFrame.height = root.selH;
        backgroundCapture.x = -root.selX;
        backgroundCapture.y = -root.selY;

        cropFrame.grabToImage(result => {
            if (result && result.saveToFile(path)) {
                clipboardProcess.command = ["sh", "-c", `wl-copy --type image/png < ${JSON.stringify(path)}`];
                clipboardProcess.running = true;
                notifyProcess.command = ["notify-send", "-i", path, "Screenshot captured", "Copied to clipboard"];
                notifyProcess.running = true;
            }
            root.close();
        }, Qt.size(root.selW, root.selH));
    }

    Process {
        id: mkdirProcess
    }

    Process {
        id: clipboardProcess
    }

    Process {
        id: notifyProcess
    }

    WlrLayershell {
        id: surface

        screen: root.targetScreen
        layer: WlrLayer.Overlay
        namespace: "screenshot-selection"
        color: "transparent"
        keyboardFocus: WlrKeyboardFocus.OnDemand
        // Without this, niri still shrinks/offsets this surface to respect the top bar's
        // reserved strip even though it's on the Overlay layer - the captured frame (which
        // already has the real bar baked into its own top rows, since it's a screenshot of
        // the real desktop) then gets drawn starting below that reserved strip, stacking a
        // second bar-shaped slice directly under the real one.
        exclusiveZone: -1

        Component.onDestruction: root.reallyDestroyed()

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
            Keys.onReturnPressed: if (root.adjusting)
                root.confirm()
            Keys.onEnterPressed: if (root.adjusting)
                root.confirm()

            Item {
                id: cropFrame

                width: surface.screen.width
                height: surface.screen.height
                clip: true

                ScreencopyView {
                    id: backgroundCapture

                    x: 0
                    y: 0
                    width: surface.screen.width
                    height: surface.screen.height
                    live: false
                    captureSource: surface.screen
                    onHasContentChanged: if (hasContent)
                        root.hasFrame = true
                }
            }

            // Four strips dim everything outside the selection, leaving the selection itself
            // showing the raw captured frame underneath untouched - cheaper than masking and
            // avoids rendering the capture twice.
            Rectangle {
                visible: root.adjusting || root.dragging
                x: 0
                y: 0
                width: parent.width
                height: root.selY
                color: Qt.rgba(0, 0, 0, 0.55)
            }

            Rectangle {
                visible: root.adjusting || root.dragging
                x: 0
                y: root.selY + root.selH
                width: parent.width
                height: Math.max(0, parent.height - (root.selY + root.selH))
                color: Qt.rgba(0, 0, 0, 0.55)
            }

            Rectangle {
                visible: root.adjusting || root.dragging
                x: 0
                y: root.selY
                width: root.selX
                height: root.selH
                color: Qt.rgba(0, 0, 0, 0.55)
            }

            Rectangle {
                visible: root.adjusting || root.dragging
                x: root.selX + root.selW
                y: root.selY
                width: Math.max(0, parent.width - (root.selX + root.selW))
                height: root.selH
                color: Qt.rgba(0, 0, 0, 0.55)
            }

            Rectangle {
                visible: root.adjusting || root.dragging
                x: root.selX
                y: root.selY
                width: root.selW
                height: root.selH
                color: "transparent"
                border.width: 2
                border.color: Config.colBorderAccent
            }

            // --- Draw phase: press-drag-release anywhere defines the initial box ---
            MouseArea {
                id: drawArea

                anchors.fill: parent
                visible: !root.adjusting
                cursorShape: Qt.CrossCursor
                preventStealing: true

                property real startX: 0
                property real startY: 0

                onPressed: mouse => {
                    drawArea.startX = mouse.x;
                    drawArea.startY = mouse.y;
                    root.dragging = true;
                    root.selX = mouse.x;
                    root.selY = mouse.y;
                    root.selW = 0;
                    root.selH = 0;
                }
                onPositionChanged: mouse => {
                    if (!root.dragging)
                        return;
                    root.selX = Math.min(drawArea.startX, mouse.x);
                    root.selY = Math.min(drawArea.startY, mouse.y);
                    root.selW = Math.abs(mouse.x - drawArea.startX);
                    root.selH = Math.abs(mouse.y - drawArea.startY);
                }
                onReleased: {
                    root.dragging = false;
                    if (root.selW < root.minSelectionSize || root.selH < root.minSelectionSize) {
                        root.selW = 0;
                        root.selH = 0;
                        return;
                    }
                    root.adjusting = true;
                }
            }

            // --- Adjust phase: move + 8 resize handles + confirm/cancel ---
            Item {
                id: adjustLayer

                visible: root.adjusting
                anchors.fill: parent

                MouseArea {
                    id: moveArea

                    x: root.selX + root.handleSize / 2
                    y: root.selY + root.handleSize / 2
                    width: Math.max(0, root.selW - root.handleSize)
                    height: Math.max(0, root.selH - root.handleSize)
                    cursorShape: Qt.SizeAllCursor

                    property real lastGX: 0
                    property real lastGY: 0

                    onPressed: mouse => {
                        const g = moveArea.mapToGlobal(mouse.x, mouse.y);
                        moveArea.lastGX = g.x;
                        moveArea.lastGY = g.y;
                    }
                    onPositionChanged: mouse => {
                        if (!moveArea.pressed)
                            return;
                        const g = moveArea.mapToGlobal(mouse.x, mouse.y);
                        const dx = g.x - moveArea.lastGX;
                        const dy = g.y - moveArea.lastGY;
                        root.selX = Math.max(0, Math.min(adjustLayer.width - root.selW, root.selX + dx));
                        root.selY = Math.max(0, Math.min(adjustLayer.height - root.selH, root.selY + dy));
                        moveArea.lastGX = g.x;
                        moveArea.lastGY = g.y;
                    }
                }

                Repeater {
                    model: [
                        { edges: "nw" },
                        { edges: "n" },
                        { edges: "ne" },
                        { edges: "w" },
                        { edges: "e" },
                        { edges: "sw" },
                        { edges: "s" },
                        { edges: "se" }
                    ]

                    delegate: Rectangle {
                        id: handle

                        required property var modelData
                        readonly property string edges: modelData.edges
                        readonly property bool north: edges.includes("n")
                        readonly property bool south: edges.includes("s")
                        readonly property bool west: edges.includes("w")
                        readonly property bool east: edges.includes("e")

                        width: root.handleSize
                        height: root.handleSize
                        radius: root.handleSize / 2
                        color: Config.colAccent
                        border.width: 1
                        border.color: Config.colBorderAccent

                        x: west ? root.selX - width / 2 : east ? root.selX + root.selW - width / 2 : root.selX + root.selW / 2 - width / 2
                        y: north ? root.selY - height / 2 : south ? root.selY + root.selH - height / 2 : root.selY + root.selH / 2 - height / 2

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: (handle.north && handle.west) || (handle.south && handle.east) ? Qt.SizeFDiagCursor : (handle.north && handle.east) || (handle.south && handle.west) ? Qt.SizeBDiagCursor : handle.north || handle.south ? Qt.SizeVerCursor : Qt.SizeHorCursor

                            property real lastGX: 0
                            property real lastGY: 0

                            onPressed: mouse => {
                                const g = mapToGlobal(mouse.x, mouse.y);
                                lastGX = g.x;
                                lastGY = g.y;
                            }
                            onPositionChanged: mouse => {
                                if (!pressed)
                                    return;
                                const g = mapToGlobal(mouse.x, mouse.y);
                                const dx = g.x - lastGX;
                                const dy = g.y - lastGY;
                                lastGX = g.x;
                                lastGY = g.y;

                                if (handle.west) {
                                    const newX = Math.max(0, Math.min(root.selX + dx, root.selX + root.selW - root.minSelectionSize));
                                    root.selW += root.selX - newX;
                                    root.selX = newX;
                                } else if (handle.east) {
                                    root.selW = Math.max(root.minSelectionSize, Math.min(adjustLayer.width - root.selX, root.selW + dx));
                                }

                                if (handle.north) {
                                    const newY = Math.max(0, Math.min(root.selY + dy, root.selY + root.selH - root.minSelectionSize));
                                    root.selH += root.selY - newY;
                                    root.selY = newY;
                                } else if (handle.south) {
                                    root.selH = Math.max(root.minSelectionSize, Math.min(adjustLayer.height - root.selY, root.selH + dy));
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    id: toolbar

                    spacing: Config.spacingSmall
                    x: Math.min(root.selX, adjustLayer.width - toolbar.implicitWidth)
                    y: root.selY + root.selH + Config.spacingSmall + toolbar.implicitHeight <= adjustLayer.height ? root.selY + root.selH + Config.spacingSmall : Math.max(0, root.selY - toolbar.implicitHeight - Config.spacingSmall)

                    Rectangle {
                        implicitWidth: 80
                        implicitHeight: 32
                        radius: Config.radiusMedium
                        color: Config.colAccent

                        Text {
                            anchors.centerIn: parent
                            text: "Capture"
                            font.family: Config.fontFamily
                            font.bold: true
                            font.pixelSize: Config.fontSizeCaption
                            color: Config.colAccentText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.confirm()
                        }
                    }

                    Rectangle {
                        implicitWidth: 80
                        implicitHeight: 32
                        radius: Config.radiusMedium
                        color: Config.colSurfaceVariant
                        border.width: Config.borderWidth
                        border.color: Config.colBorder

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSizeCaption
                            color: Config.colText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }
            }
        }
    }
}
