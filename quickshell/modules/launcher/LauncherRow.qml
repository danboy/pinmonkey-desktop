import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs

Rectangle {
    id: root

    property string iconName
    property string label
    property bool selected: false

    signal activated

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: Config.launcherRowHeight
    radius: Config.radiusSmall
    color: selected ? Config.colAccent : "transparent"
    border.width: selected ? Config.borderWidth : 0
    border.color: Config.colBorderAccent

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.spacingLarge
        anchors.rightMargin: Config.spacingLarge
        spacing: Config.spacingLarge

        IconImage {
            source: Quickshell.iconPath(root.iconName, "application-x-executable")
            implicitSize: Config.launcherIconSize
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeBody
            color: root.selected ? Config.colAccentText : Config.colText
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.activated()
    }
}
