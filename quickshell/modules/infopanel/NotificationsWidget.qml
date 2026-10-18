import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.modules.services

ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: Config.spacingSmall

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: "Notifications"
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: Config.fontSizeBody
            color: Config.colText
        }

        Text {
            visible: Notifications.trackedNotifications.values.length > 0
            text: "Clear all"
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeCaption
            color: Config.colAccent

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.clearAll()
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: Notifications.trackedNotifications.values.length === 0
        text: "No notifications"
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }

    Repeater {
        model: Notifications.trackedNotifications

        delegate: Rectangle {
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: Config.notificationRowHeight
            radius: Config.radiusSmall
            color: Config.colSurfaceVariant
            border.width: Config.borderWidth
            border.color: Config.colBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: Config.spacingSmall
                spacing: Config.spacingSmall

                IconImage {
                    source: Quickshell.iconPath(modelData.appIcon, "dialog-information-symbolic")
                    implicitSize: Config.iconSizeMedium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: modelData.summary
                        elide: Text.ElideRight
                        font.family: Config.fontFamily
                        font.bold: true
                        font.pixelSize: Config.fontSizeCaption
                        color: Config.colText
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: modelData.body.length > 0
                        text: modelData.body
                        elide: Text.ElideRight
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeCaption
                        color: Config.colSubtext
                    }
                }

                IconImage {
                    source: Quickshell.iconPath("window-close-symbolic", "window-close")
                    implicitSize: Config.iconSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.dismiss()
                    }
                }
            }
        }
    }
}
