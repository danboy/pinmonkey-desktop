import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs

// A clickable row: icon + title/subtitle + an optional trailing action slot (e.g. a small
// forget button). The row's own click target is declared first so trailing children stack
// on top of it and correctly intercept their own clicks.
Rectangle {
    id: root

    property string iconName
    property string iconFallback: iconName
    property string title
    property string subtitle
    property bool highlighted: false
    default property alias trailing: trailingRow.data

    signal clicked

    width: ListView.view ? ListView.view.width : implicitWidth
    Layout.fillWidth: true
    implicitHeight: Config.settingsRowHeight
    radius: Config.radiusMedium
    color: root.highlighted ? Config.colSurfaceHighlight : Config.colSurfaceVariant
    border.width: Config.borderWidth
    border.color: root.highlighted ? Config.colBorderAccent : Config.colBorder

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingLarge

        IconImage {
            source: Quickshell.iconPath(root.iconName, root.iconFallback)
            implicitSize: Config.iconSizeMedium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.title
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: Config.fontSizeBody
                color: Config.colText
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                visible: root.subtitle.length > 0
                text: root.subtitle
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }
        }

        RowLayout {
            id: trailingRow
            spacing: Config.spacingSmall
        }
    }
}
