import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    property string iconName
    property string iconFallback: iconName
    property bool on: false
    property string title
    property string subtitle

    signal toggled()
    signal titleClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: Config.tileHeight
    radius: Config.radiusMedium
    color: Config.colSurfaceVariant
    border.width: Config.borderWidth
    border.color: on ? Config.colBorderAccent : Config.colBorder

    RowLayout {
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingLarge

        IconToggle {
            Layout.fillHeight: true
            Layout.preferredWidth: Config.tileIconBoxSize
            iconName: root.iconName
            iconFallback: root.iconFallback
            on: root.on
            onClicked: root.toggled()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.spacingXSmall

            Text {
                text: root.title
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: Config.fontSizeBody
                color: Config.colText

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.titleClicked()
                }

            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.subtitle
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }

        }

    }

}
