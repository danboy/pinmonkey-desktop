import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.services

Rectangle {
    id: root

    visible: Recording.active
    color: Config.colSurfaceVariant
    implicitHeight: Config.pillHeight
    implicitWidth: rowLayout.implicitWidth + Config.pillPaddingHorizontal
    radius: Config.radiusPill
    border.width: Config.borderWidth
    border.color: Config.colDanger

    RowLayout {
        id: rowLayout

        anchors.centerIn: parent
        spacing: Config.spacingSmall

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Config.spacingMedium
            implicitHeight: Config.spacingMedium
            radius: width / 2
            color: Config.colDanger

            SequentialAnimation on opacity {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.3
                    duration: 700
                }
                NumberAnimation {
                    to: 1
                    duration: 700
                }
            }
        }

        Text {
            text: Math.floor(Recording.elapsedSeconds / 60) + ":" + String(Recording.elapsedSeconds % 60).padStart(2, "0")
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeCaption
            font.bold: true
            color: Config.colText
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Recording.stop()
    }
}
