import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs
import qs.modules.components

// Controls niri's live (temporary, not config.kdl-persisted) output settings via
// `niri msg output`. These reset if the output configuration in config.kdl later changes -
// that's niri's own documented behavior for this command, not a limitation of this panel.
ColumnLayout {
    id: root

    spacing: Config.spacingLarge

    Process {
        id: outputProcess
    }

    function run(outputName, args) {
        outputProcess.command = ["niri", "msg", "output", outputName].concat(args);
        outputProcess.running = true;
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Config.spacingLarge
        model: Quickshell.screens

        delegate: ColumnLayout {
            id: outputCard

            required property var modelData

            width: ListView.view ? ListView.view.width : implicitWidth
            spacing: Config.spacingSmall

            Text {
                text: outputCard.modelData.name
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: Config.fontSizeBody
                color: Config.colText
            }

            Text {
                text: outputCard.modelData.width + "×" + outputCard.modelData.height + " @ " + Math.round(outputCard.modelData.refreshRate) + "Hz"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Config.spacingSmall

                Text {
                    text: "Scale"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colSubtext
                }

                TextField {
                    Layout.preferredWidth: 60
                    text: outputCard.modelData.devicePixelRatio.toFixed(2)
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colText

                    background: Rectangle {
                        radius: Config.radiusSmall
                        color: Config.colSurfaceVariant
                        border.width: Config.borderWidth
                        border.color: Config.colBorder
                    }

                    onAccepted: root.run(outputCard.modelData.name, ["scale", text])
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "VRR"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colSubtext
                }

                Text {
                    text: "On"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colAccent

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(outputCard.modelData.name, ["vrr", "on"])
                    }
                }

                Text {
                    text: "Off"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colAccent

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(outputCard.modelData.name, ["vrr", "off"])
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Config.spacingSmall

                Text {
                    text: "Rotation"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colSubtext
                }

                Repeater {
                    model: ["normal", "90", "180", "270"]

                    delegate: Text {
                        required property string modelData

                        text: modelData
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeCaption
                        color: Config.colAccent

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run(outputCard.modelData.name, ["transform", parent.modelData])
                        }
                    }
                }
            }

            Divider {}
        }
    }
}
