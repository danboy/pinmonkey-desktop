import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

Rectangle {
    id: root

    property string iconName
    property string iconFallback: iconName
    property bool on: false
    property int iconSize: Config.iconSizeMedium

    signal clicked

    radius: Config.radiusSmall
    color: on ? Config.colAccent : Config.colSurfaceHighlight
    border.width: Config.borderWidth
    border.color: on ? Config.colBorderAccent : Config.colBorder

    IconImage {
        anchors.centerIn: parent
        source: Quickshell.iconPath(root.iconName, root.iconFallback)
        implicitSize: root.iconSize
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
