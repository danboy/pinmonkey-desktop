import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.components
import qs.modules.services

Rectangle {
    id: root

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    color: Config.colSurfaceVariant
    implicitHeight: Config.pillHeight
    implicitWidth: clockText.implicitWidth + Config.pillPaddingHorizontal
    radius: Config.radiusPill
    border.width: Config.borderWidth
    border.color: Config.colBorder

    Text {
        id: clockText

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "h:mm AP · ddd, MMM d")
        font.family: Config.fontFamily
        font.bold: true
        font.pixelSize: Config.fontSizeCaption
        color: Config.colText
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.visible = !popup.visible
    }

    AnchoredPopup {
        id: popup

        anchorItem: root
        implicitWidth: Config.infoPanelWidth

        Connections {
            target: PopupCoordinator
            function onCloseAll() {
                popup.visible = false;
            }
        }

        WeatherWidget {}

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Config.borderWidth
            color: Config.colDivider
        }

        CalendarWidget {}

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Config.borderWidth
            color: Config.colDivider
        }

        NotificationsWidget {}
    }
}
