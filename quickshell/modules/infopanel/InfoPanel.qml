import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.components
import qs.modules.services
import qs.modules.widgets

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
        onOpenChanged: NotificationToast.suppressed = open

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

                WeatherWidget {
                    size: "small"
                }

                Item {
                    Layout.fillHeight: true
                }

                Divider {}

                Item {
                    Layout.fillHeight: true
                }

                CalendarWidget {
                    size: "small"
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: Config.borderWidth
                color: Config.colDivider
            }

            NotificationsWidget {
                size: "small"
                Layout.preferredWidth: Config.popupWidth
                Layout.alignment: Qt.AlignTop
            }
        }
    }
}
