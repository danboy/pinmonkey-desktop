import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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
    // Set on standing, always-visible surfaces (desktop widget, lock screen) so a glance
    // at the screen - or a screenshot/screenshare - can't read someone else's message
    // previews. Left off for the toast and the info panel's own list, both of which only
    // show up when a notification just arrived or the panel was deliberately opened.
    property bool obscureDetails: false

    signal closeClicked()

    spacing: Config.spacingSmall

    IconImage {
        source: Quickshell.iconPath(root.notification?.appIcon ?? "", "dialog-information-symbolic")
        implicitSize: Config.iconSizeMedium
    }

    Item {
        id: detailsWrapper

        Layout.fillWidth: true
        Layout.preferredHeight: details.implicitHeight

        ColumnLayout {
            id: details

            // Moved off-screen rather than hidden while obscured - MultiEffect still needs
            // to render this to grab a texture for the blur (see SelectionCapture.qml's
            // off-screen grabFrame for the same trick), but painting a translucent blur on
            // top of the sharp text IN PLACE barely obscured it: the blur's own alpha falls
            // off toward the edges of each glyph, letting the crisp original show straight
            // through. Moving it off-screen means the real text is never painted at the
            // visible position at all - only the opaque blurred copy ever is.
            x: root.obscureDetails ? -10000 : 0
            y: 0
            width: detailsWrapper.width
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

        // Anchored to detailsWrapper (which never moves), not to `details` itself (which
        // does) - this is the only thing actually painted at the visible position when
        // obscured.
        MultiEffect {
            anchors.fill: parent
            source: details
            visible: root.obscureDetails
            blurEnabled: root.obscureDetails
            blur: 1
            blurMax: 48
            autoPaddingEnabled: false
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
