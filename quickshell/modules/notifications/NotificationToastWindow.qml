import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.components
import qs.modules.services

Variants {
    model: Quickshell.screens

    delegate: WlrLayershell {
        id: toastWindow

        required property ShellScreen modelData
        readonly property bool wantOpen: NotificationToast.visible && NotificationToast.notification !== null

        layer: WlrLayer.Overlay
        screen: modelData
        color: "transparent"
        // Stays mapped permanently - toggling this (e.g. via CloseDelay) remaps the
        // wl_surface on every notification, which races Qt's Wayland output-enter
        // handling and segfaults in QWaylandWindow::calculateScreenFromSurfaceEvents.
        // Show/hide is purely visual below (opacity/scale + input gating).
        visible: true
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
            opacity: toastWindow.wantOpen ? 1 : 0
            scale: toastWindow.wantOpen ? 1 : 0.96

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animationDurationMs
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Config.animationDurationMs
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: toastWindow.wantOpen
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
