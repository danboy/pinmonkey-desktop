import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs

// Icon + summary + body + close button for a single notification - shared by the dashboard
// list (NotificationsWidget) and the toast banner (NotificationToastWindow), which differ only
// in body wrapping and what "close" means (dismiss vs. just hide the toast).
RowLayout {
    id: root

    property var notification: null
    property int bodyWrapMode: Text.NoWrap
    property int bodyMaximumLineCount: 1

    signal closeClicked()

    spacing: Config.spacingSmall

    IconImage {
        source: Quickshell.iconPath(root.notification?.appIcon ?? "", "dialog-information-symbolic")
        implicitSize: Config.iconSizeMedium
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            Layout.fillWidth: true
            text: root.notification?.summary ?? ""
            elide: Text.ElideRight
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: Config.fontSizeCaption
            color: Config.colText
        }

        Text {
            Layout.fillWidth: true
            visible: (root.notification?.body ?? "").length > 0
            text: root.notification?.body ?? ""
            elide: Text.ElideRight
            wrapMode: root.bodyWrapMode
            maximumLineCount: root.bodyMaximumLineCount
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
            onClicked: root.closeClicked()
        }
    }
}
