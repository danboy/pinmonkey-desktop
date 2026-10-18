import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.components
import qs.modules.services

ColumnLayout {
    id: root

    spacing: Config.spacingSmall

    QuickToggleTile {
        iconName: "system-lock-screen-symbolic"
        iconFallback: "system-lock-screen"
        on: ShellSettings.idleLockEnabled
        title: "Lock after inactivity"
        subtitle: on ? "On" : "Off"
        onToggled: ShellSettings.idleLockEnabled = !ShellSettings.idleLockEnabled
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.spacingSmall
        enabled: ShellSettings.idleLockEnabled
        opacity: enabled ? 1 : 0.4

        Text {
            text: "Lock after"
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeCaption
            color: Config.colSubtext
        }

        Item {
            Layout.fillWidth: true
        }

        Repeater {
            model: [1, 5, 10, 15, 30]

            delegate: Text {
                required property int modelData

                text: modelData + "m"
                font.family: Config.fontFamily
                font.bold: ShellSettings.idleLockMinutes === modelData
                font.pixelSize: Config.fontSizeCaption
                color: ShellSettings.idleLockMinutes === modelData ? Config.colAccent : Config.colSubtext

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellSettings.idleLockMinutes = parent.modelData
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Config.borderWidth
        color: Config.colDivider
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Config.screenshotCaptureButtonHeight
        radius: Config.radiusMedium
        color: Config.colSurfaceVariant
        border.width: Config.borderWidth
        border.color: Config.colBorder

        Text {
            anchors.centerIn: parent
            text: "Lock Now"
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: Config.fontSizeBody
            color: Config.colText
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "lock", "lock"])
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
