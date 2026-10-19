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
        onClicked: popup.open = !popup.open
    }

    AnchoredPopup {
        id: popup

        anchorItem: root
        implicitWidth: Config.infoPanelWidth
        minimumContentHeight: Config.infoPanelHeight
        onVisibleChanged: NotificationToast.suppressed = visible

        Connections {
            target: PopupCoordinator
            function onCloseAll() {
                popup.open = false;
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Config.spacingLarge

            ColumnLayout {
                Layout.preferredWidth: Config.infoPanelLeftColumnWidth
                Layout.fillHeight: true
                spacing: Config.spacingSmall

                WeatherWidget {}

                Item {
                    Layout.fillHeight: true
                }

                Divider {}

                Item {
                    Layout.fillHeight: true
                }

                CalendarWidget {}
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: Config.borderWidth
                color: Config.colDivider
            }

            NotificationsWidget {
                Layout.preferredWidth: Config.popupWidth
                Layout.alignment: Qt.AlignTop
            }
        }
    }
}
