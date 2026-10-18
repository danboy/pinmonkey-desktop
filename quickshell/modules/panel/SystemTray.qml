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
                        if (mouse.button === Qt.LeftButton)
                            trayIcon.modelData.activate();
                        else if (mouse.button === Qt.RightButton)
                            trayIcon.modelData.display(trayIcon.QsWindow.window, mouse.x, mouse.y);
                    }
                    onWheel: wheel => trayIcon.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}
