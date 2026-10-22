import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs

Rectangle {
    id: root

    clip: true
    color: Config.colSurfaceVariant
    visible: SystemTray.items.values.length > 0
    implicitHeight: Config.pillHeight
    implicitWidth: trayRow.implicitWidth + Config.pillPaddingHorizontal
    radius: Config.radiusPill
    border.width: Config.borderWidth
    border.color: Config.colBorder

    RowLayout {
        id: trayRow

        anchors.centerIn: parent
        spacing: Config.spacingSmall

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayIcon

                required property SystemTrayItem modelData

                implicitWidth: Config.iconSizeStatus
                implicitHeight: Config.iconSizeStatus

                IconImage {
                    anchors.fill: parent
                    source: trayIcon.modelData.icon
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        // `onlyMenu` isn't reliable - some apps (e.g. Remmina, libappindicator
                        // in general) expose no working Activate without actually setting that
                        // flag, so calling activate() on them is a silent no-op. `hasMenu` is
                        // the trustworthy signal: if there's a menu, left-click opens it (same
                        // as right-click) - only fall back to activate() when there's no menu
                        // to fall back to.
                        if (mouse.button === Qt.LeftButton && !trayIcon.modelData.hasMenu) {
                            trayIcon.modelData.activate();
                        } else if (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton) {
                            // Anchored to the icon's bottom-right corner (window coordinates -
                            // mouse.x/y alone are local to this tiny icon Item and open the
                            // menu pinned near the window's origin instead) rather than the
                            // exact click point, which left it visibly offset.
                            const pos = trayIcon.QsWindow.itemPosition(trayIcon);
                            trayIcon.modelData.display(trayIcon.QsWindow.window, pos.x + trayIcon.width, pos.y + trayIcon.height);
                        }
                    }
                    onWheel: wheel => trayIcon.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}
