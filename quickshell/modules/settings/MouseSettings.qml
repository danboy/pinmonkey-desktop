import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components
import qs.modules.services

ColumnLayout {
    id: root

    spacing: Config.spacingSmall

    QuickToggleTile {
        iconName: "input-mouse-symbolic"
        on: NiriConfig.mouseNaturalScroll
        title: "Natural scroll"
        subtitle: on ? "On" : "Off"
        onToggled: NiriConfig.setFlag("mouse", "natural-scroll", !NiriConfig.mouseNaturalScroll)
    }

    QuickToggleTile {
        iconName: "input-mouse-symbolic"
        on: NiriConfig.mouseLeftHanded
        title: "Left-handed"
        subtitle: on ? "On" : "Off"
        onToggled: NiriConfig.setFlag("mouse", "left-handed", !NiriConfig.mouseLeftHanded)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.spacingSmall

        Text {
            text: "Acceleration"
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeCaption
            color: Config.colSubtext
        }

        Item {
            Layout.fillWidth: true
        }

        Repeater {
            model: ["adaptive", "flat"]

            delegate: Text {
                required property string modelData

                text: modelData
                font.family: Config.fontFamily
                font.bold: NiriConfig.mouseAccelProfile === modelData
                font.pixelSize: Config.fontSizeCaption
                color: NiriConfig.mouseAccelProfile === modelData ? Config.colAccent : Config.colSubtext

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NiriConfig.setValue("mouse", "accel-profile", parent.modelData, true)
                }
            }
        }
    }

    SliderRow {
        iconName: "input-mouse-symbolic"
        value: (NiriConfig.mouseAccelSpeed + 1) / 2
        onReleased: newValue => NiriConfig.setValue("mouse", "accel-speed", (newValue * 2 - 1).toFixed(2), false)
    }

    Item {
        Layout.fillHeight: true
    }
}
