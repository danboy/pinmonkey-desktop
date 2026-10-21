import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components
import qs.modules.services

// No title: the header here is a RowLayout (title + "Clear all"), not the plain-string
// title WidgetLayout renders - see WeatherWidget etc. for the common case.
WidgetLayout {
    id: root

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: "Notifications"
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: root.titleFontSize
            color: Config.colText
        }

        Text {
            visible: Notifications.trackedNotifications.values.length > 0
            text: "Clear all"
            font.family: Config.fontFamily
            font.pixelSize: root.captionFontSize
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
        font.pixelSize: root.captionFontSize
        color: Config.colSubtext
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.contentHeight, Config.notificationsListMaxHeight)
        clip: true
        spacing: Config.spacingSmall
        boundsBehavior: Flickable.StopAtBounds
        model: Notifications.trackedNotifications

        delegate: Rectangle {
            required property var modelData

            width: list.width
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

    // Soaks up leftover height when the box is resized taller than the content needs,
    // so content stays pinned to the top instead of ColumnLayout spreading it out.
    Item {
        Layout.fillHeight: true
    }
}
