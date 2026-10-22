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
        // Show/hide is purely visual below (opacity/scale), with input gated by `mask`
        // instead - same pattern as DesktopWidgetLayer.qml's widgetSurface. Without this,
        // the MouseArea's `enabled: wantOpen` only stops it from reacting; it does nothing
        // to the surface's input region, so this permanently-mapped window was eating every
        // click in its whole top-right rect (toast visible or not) with nothing there to
        // respond - the exact dead-click-zone bug this comment is here to prevent regressing.
        visible: true
        exclusiveZone: 0
        // closeDelay rather than wantOpen directly, so the toast stays clickable (e.g. to
        // dismiss it) through its own fade-out instead of going click-through mid-animation.
        mask: closeDelay.active ? null : clickThroughMask

        CloseDelay {
            id: closeDelay

            open: toastWindow.wantOpen
        }

        Region {
            id: clickThroughMask
        }

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
