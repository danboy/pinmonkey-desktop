import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components
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

            NotificationRow {
                anchors.fill: parent
                anchors.margins: Config.spacingSmall
                notification: modelData
                onCloseClicked: modelData.dismiss()
            }
        }
    }
}
