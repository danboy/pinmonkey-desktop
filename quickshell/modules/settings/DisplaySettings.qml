import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs
import qs.modules.components

// GNOME/macOS-style display settings: a scaled-down drag-to-arrange diagram of the
// outputs, plus resolution/scale/orientation/VRR controls for whichever one is selected.
// Backed by `niri msg output ...` - niri's own documented *temporary* output config, which
// resets if the output configuration in config.kdl later changes. `niri msg --json outputs`
// is the only source for available modes/logical position/scale - Quickshell.screens
// doesn't expose any of that.
ColumnLayout {
    id: root

    spacing: Config.spacingLarge

    property var outputs: ({})
    property string selectedOutput: ""

    readonly property var selected: outputs[selectedOutput]

    function refresh() {
        queryProcess.running = true;
    }

    function run(outputName, args) {
        mutateProcess.command = ["niri", "msg", "output", outputName].concat(args);
        mutateProcess.running = true;
    }

    function modeLabel(mode) {
        return mode.width + "×" + mode.height + " @ " + Math.round(mode.refresh_rate / 1000) + "Hz";
    }

    function modeArg(mode) {
        return mode.width + "x" + mode.height + "@" + (mode.refresh_rate / 1000).toFixed(3);
    }

    Component.onCompleted: refresh()

    Process {
        id: queryProcess

        command: ["niri", "msg", "--json", "outputs"]

        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try {
                    data = JSON.parse(text);
                } catch (e) {
                    return;
                }
                root.outputs = data;
                if (!(root.selectedOutput in data)) {
                    const names = Object.keys(data);
                    root.selectedOutput = names.length > 0 ? names[0] : "";
                }
            }
        }
    }

    Process {
        id: mutateProcess

        onExited: root.refresh()
    }

    // --- Arrangement diagram ---
    Rectangle {
        id: canvas

        Layout.fillWidth: true
        Layout.preferredHeight: 180
        radius: Config.radiusMedium
        color: Config.colSurfaceVariant
        border.width: Config.borderWidth
        border.color: Config.colBorder
        clip: true

        readonly property int padding: Config.spacingLarge
        readonly property var enabledNames: Object.keys(root.outputs).filter(n => !!root.outputs[n].logical)

        readonly property real minX: enabledNames.length ? Math.min(...enabledNames.map(n => root.outputs[n].logical.x)) : 0
        readonly property real minY: enabledNames.length ? Math.min(...enabledNames.map(n => root.outputs[n].logical.y)) : 0
        readonly property real totalWidth: enabledNames.length ? Math.max(...enabledNames.map(n => root.outputs[n].logical.x + root.outputs[n].logical.width)) - minX : 1
        readonly property real totalHeight: enabledNames.length ? Math.max(...enabledNames.map(n => root.outputs[n].logical.y + root.outputs[n].logical.height)) - minY : 1

        readonly property real diagramScale: Math.min((width - padding * 2) / Math.max(totalWidth, 1), (height - padding * 2) / Math.max(totalHeight, 1), 0.08)

        Repeater {
            model: canvas.enabledNames

            delegate: Rectangle {
                id: card

                required property string modelData
                readonly property var logical: root.outputs[card.modelData].logical

                property real pressX: 0
                property real pressY: 0
                property real pressMouseX: 0
                property real pressMouseY: 0

                width: Math.max(logical.width * canvas.diagramScale, 32)
                height: Math.max(logical.height * canvas.diagramScale, 32)
                x: canvas.padding + (logical.x - canvas.minX) * canvas.diagramScale
                y: canvas.padding + (logical.y - canvas.minY) * canvas.diagramScale
                radius: Config.radiusSmall
                color: root.selectedOutput === card.modelData ? Config.colAccent : Config.colSurfaceHighlight
                border.width: Config.borderWidth
                border.color: root.selectedOutput === card.modelData ? Config.colBorderAccent : Config.colBorder

                Text {
                    anchors.centerIn: parent
                    text: card.modelData
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: root.selectedOutput === card.modelData ? Config.colAccentText : Config.colText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor

                    onPressed: mouse => {
                        root.selectedOutput = card.modelData;
                        card.pressX = card.x;
                        card.pressY = card.y;
                        card.pressMouseX = mouse.x;
                        card.pressMouseY = mouse.y;
                    }

                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        card.x = Math.max(0, Math.min(canvas.width - card.width, card.pressX + (mouse.x - card.pressMouseX)));
                        card.y = Math.max(0, Math.min(canvas.height - card.height, card.pressY + (mouse.y - card.pressMouseY)));
                    }

                    onReleased: {
                        const logicalX = Math.round(canvas.minX + (card.x - canvas.padding) / canvas.diagramScale);
                        const logicalY = Math.round(canvas.minY + (card.y - canvas.padding) / canvas.diagramScale);
                        root.run(card.modelData, ["position", "set", logicalX.toString(), logicalY.toString()]);
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: canvas.enabledNames.length === 0
            text: "No displays"
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeCaption
            color: Config.colSubtext
        }
    }

    Divider {}

    // --- Selected output detail ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingLarge
        visible: !!root.selected

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingSmall

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: root.selectedOutput
                    font.family: Config.fontFamily
                    font.bold: true
                    font.pixelSize: Config.fontSizeBody
                    color: Config.colText
                }

                Text {
                    text: root.selected ? [root.selected.make, root.selected.model].filter(s => !!s).join(" ") : ""
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colSubtext
                }
            }

            IconToggle {
                implicitWidth: Config.iconButtonSize
                implicitHeight: Config.iconButtonSize
                radius: Config.radiusPill
                iconName: "video-display-symbolic"
                on: !!(root.selected && root.selected.logical)
                onClicked: root.run(root.selectedOutput, [(root.selected && root.selected.logical) ? "off" : "on"])
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.spacingSmall
            visible: !!(root.selected && root.selected.logical)

            Text {
                text: "Resolution"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }

            DropdownSelect {
                options: root.selected ? root.selected.modes.map(m => ({
                    label: root.modeLabel(m) + (m.is_preferred === true ? " (preferred)" : ""),
                    value: root.modeArg(m)
                })) : []
                selectedValue: root.selected && root.selected.current_mode !== undefined && root.selected.current_mode !== null ? root.modeArg(root.selected.modes[root.selected.current_mode]) : ""
                onSelected: value => root.run(root.selectedOutput, ["mode", value])
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.spacingSmall
            visible: !!(root.selected && root.selected.logical)

            Text {
                text: "Scale"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }

            PillSelector {
                readonly property var baseSteps: [1, 1.25, 1.5, 1.75, 2, 2.5, 3]
                readonly property real current: root.selected && root.selected.logical ? root.selected.logical.scale : 1
                readonly property var steps: baseSteps.includes(current) ? baseSteps : baseSteps.concat([current]).sort((a, b) => a - b)

                options: steps.map(s => ({
                    label: Math.round(s * 100) + "%",
                    value: s
                }))
                currentValue: current
                onSelected: value => root.run(root.selectedOutput, ["scale", value.toString()])
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.spacingSmall
            visible: !!(root.selected && root.selected.logical)

            Text {
                text: "Orientation"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }

            PillSelector {
                options: [
                    { label: "Normal", value: "normal" },
                    { label: "90°", value: "90" },
                    { label: "180°", value: "180" },
                    { label: "270°", value: "270" }
                ]
                currentValue: root.selected && root.selected.logical ? root.selected.logical.transform.toLowerCase() : "normal"
                onSelected: value => root.run(root.selectedOutput, ["transform", value])
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingSmall
            visible: !!(root.selected && root.selected.vrr_supported)

            Text {
                text: "Variable refresh rate"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }

            Item {
                Layout.fillWidth: true
            }

            IconToggle {
                implicitWidth: Config.iconButtonSize
                implicitHeight: Config.iconButtonSize
                radius: Config.radiusPill
                iconName: "video-display-symbolic"
                on: !!(root.selected && root.selected.vrr_enabled)
                onClicked: root.run(root.selectedOutput, ["vrr", (root.selected && root.selected.vrr_enabled) ? "off" : "on"])
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
