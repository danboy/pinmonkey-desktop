import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.services

ColumnLayout {
    id: root

    spacing: Config.spacingSmall

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: NiriConfig.tabletConfigured ? "Tablet mapped to:" : "No tablet configured. Pick an output below to map a connected tablet to it."
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }

    Repeater {
        model: Quickshell.screens

        delegate: Rectangle {
            id: outputButton

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: Config.settingsRowHeight
            radius: Config.radiusMedium
            color: NiriConfig.tabletOutput === modelData.name ? Config.colAccent : Config.colSurfaceVariant
            border.width: Config.borderWidth
            border.color: NiriConfig.tabletOutput === modelData.name ? Config.colBorderAccent : Config.colBorder

            Text {
                anchors.centerIn: parent
                text: outputButton.modelData.name
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: Config.fontSizeBody
                color: NiriConfig.tabletOutput === outputButton.modelData.name ? Config.colAccentText : Config.colText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NiriConfig.setTabletOutput(outputButton.modelData.name)
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
