import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.modules.components

ColumnLayout {
    id: root

    property bool expanded: false

    readonly property var actions: [
        {
            label: "Lock",
            iconName: "system-lock-screen-symbolic",
            iconFallback: "system-lock-screen",
            command: ["quickshell", "ipc", "call", "lock", "lock"]
        },
        {
            label: "Log out",
            iconName: "system-log-out-symbolic",
            iconFallback: "system-log-out",
            command: ["niri", "msg", "action", "quit"]
        },
        {
            label: "Switch user",
            iconName: "system-switch-user-symbolic",
            iconFallback: "system-switch-user",
            command: ["dbus-send", "--system", "--dest=org.gnome.DisplayManager", "--type=method_call", "/org/gnome/DisplayManager/LocalDisplayFactory", "org.gnome.DisplayManager.LocalDisplayFactory.CreateTransientDisplay"]
        },
        {
            label: "Suspend",
            iconName: "system-suspend-symbolic",
            iconFallback: "system-suspend",
            command: ["systemctl", "suspend"]
        },
        {
            label: "Restart",
            iconName: "system-reboot-symbolic",
            iconFallback: "system-reboot",
            command: ["systemctl", "reboot"]
        },
        {
            label: "Power off",
            iconName: "system-shutdown-symbolic",
            iconFallback: "system-shutdown",
            command: ["systemctl", "poweroff"]
        }
    ]

    Layout.fillWidth: true
    spacing: Config.spacingSmall

    Rectangle {
        id: header

        Layout.fillWidth: true
        implicitHeight: Config.tileHeight
        radius: Config.radiusMedium
        color: Config.colSurfaceVariant
        border.width: Config.borderWidth
        border.color: root.expanded ? Config.colBorderAccent : Config.colBorder

        RowLayout {
            anchors.fill: parent
            anchors.margins: Config.spacingSmall
            spacing: Config.spacingLarge

            Rectangle {
                Layout.preferredWidth: Config.tileIconBoxSize
                Layout.fillHeight: true
                radius: Config.radiusSmall
                color: root.expanded ? Config.colAccent : Config.colSurfaceHighlight
                border.width: Config.borderWidth
                border.color: root.expanded ? Config.colBorderAccent : Config.colBorder

                IconImage {
                    anchors.centerIn: parent
                    source: Quickshell.iconPath("system-shutdown-symbolic", "system-shutdown")
                    implicitSize: Config.iconSizeMedium
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Power"
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: Config.fontSizeBody
                color: Config.colText
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: root.expanded ? actionsColumn.implicitHeight : 0
        clip: true

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Config.animationDurationMs
            }
        }

        ColumnLayout {
            id: actionsColumn

            width: parent.width
            spacing: Config.spacingXSmall

            opacity: root.expanded ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animationDurationMs
                }
            }

            Repeater {
                model: root.actions

                delegate: RowLayout {
                    id: actionDelegate

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Config.spacingLarge

                    IconToggle {
                        implicitWidth: Config.iconButtonSize
                        implicitHeight: Config.iconButtonSize
                        iconName: actionDelegate.modelData.iconName
                        iconFallback: actionDelegate.modelData.iconFallback
                        onClicked: Quickshell.execDetached(actionDelegate.modelData.command)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: actionDelegate.modelData.label
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeBody
                        color: Config.colText

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(actionDelegate.modelData.command)
                        }
                    }
                }
            }
        }
    }
}
