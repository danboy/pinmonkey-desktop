import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.modules.services

Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: Config.tileHeight
    radius: Config.radiusMedium
    color: Config.colSurfaceVariant
    border.width: Config.borderWidth
    border.color: Config.colBorder

    RowLayout {
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingLarge

        Rectangle {
            Layout.preferredWidth: Config.tileIconBoxSize
            Layout.fillHeight: true
            radius: Config.radiusSmall
            color: Config.colSurfaceHighlight
            border.width: Config.borderWidth
            border.color: Config.colBorder

            IconImage {
                anchors.centerIn: parent
                source: Quickshell.iconPath("system-shutdown-symbolic", "system-shutdown")
                implicitSize: Config.iconSizeMedium
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Power"
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: Config.fontSizeBody
            color: Config.colText
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            PopupCoordinator.closeAll();
            PowerMenuState.open = true;
        }
    }
}
