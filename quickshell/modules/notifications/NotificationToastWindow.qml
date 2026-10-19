import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.components
import qs.modules.services

Variants {
    model: Quickshell.screens

    delegate: WlrLayershell {
        required property ShellScreen modelData

        layer: WlrLayer.Overlay
        screen: modelData
        color: "transparent"
        visible: NotificationToast.visible && NotificationToast.notification !== null
        exclusiveZone: 0

        implicitWidth: Config.popupWidth
        implicitHeight: content.implicitHeight + Config.popupMargin * 2

        anchors {
            top: true
            right: true
        }

        margins {
            top: Config.barHeight + Config.spacingMedium
            right: Config.spacingMedium
        }

        Rectangle {
            anchors.fill: parent
            radius: Config.radiusLarge
            color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
            border.width: Config.borderWidth
            border.color: Config.colBorderAccent

            MouseArea {
                anchors.fill: parent
                onClicked: NotificationToast.hide()
            }

            NotificationRow {
                id: content

                anchors.fill: parent
                anchors.margins: Config.popupMargin
                notification: NotificationToast.notification
                bodyWrapMode: Text.WordWrap
                bodyMaximumLineCount: 2
                onCloseClicked: NotificationToast.hide()
            }
        }
    }
}
