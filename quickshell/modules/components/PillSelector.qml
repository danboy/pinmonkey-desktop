import QtQuick
import QtQuick.Layouts
import qs

// Wrapping row of selectable pills - e.g. resolution/scale/orientation choices in
// DisplaySettings.qml. Each option is {label, value, highlighted (optional)}.
Flow {
    id: root

    property var options: []
    property var currentValue

    signal selected(var value)

    Layout.fillWidth: true
    spacing: Config.spacingSmall

    Repeater {
        model: root.options

        delegate: Rectangle {
            id: pill

            required property var modelData

            readonly property bool active: pill.modelData.value === root.currentValue

            implicitWidth: label.implicitWidth + Config.spacingLarge * 2
            implicitHeight: label.implicitHeight + Config.spacingSmall * 2
            radius: Config.radiusPill
            color: active ? Config.colAccent : Config.colSurfaceVariant
            border.width: Config.borderWidth
            border.color: active ? Config.colBorderAccent : Config.colBorder

            Text {
                id: label

                anchors.centerIn: parent
                text: pill.modelData.label
                font.family: Config.fontFamily
                font.bold: pill.modelData.preferred === true
                font.pixelSize: Config.fontSizeCaption
                color: pill.active ? Config.colAccentText : Config.colText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(pill.modelData.value)
            }
        }
    }
}
