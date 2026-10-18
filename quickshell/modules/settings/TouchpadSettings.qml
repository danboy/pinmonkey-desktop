import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components
import qs.modules.services

ColumnLayout {
    id: root

    spacing: Config.spacingSmall

    QuickToggleTile {
        iconName: "input-touchpad-symbolic"
        on: NiriConfig.touchpadTapToClick
        title: "Tap to click"
        subtitle: on ? "On" : "Off"
        onToggled: NiriConfig.setFlag("touchpad", "tap", !NiriConfig.touchpadTapToClick)
    }

    QuickToggleTile {
        iconName: "input-touchpad-symbolic"
        on: NiriConfig.touchpadNaturalScroll
        title: "Natural scroll"
        subtitle: on ? "On" : "Off"
        onToggled: NiriConfig.setFlag("touchpad", "natural-scroll", !NiriConfig.touchpadNaturalScroll)
    }

    QuickToggleTile {
        iconName: "input-touchpad-symbolic"
        on: NiriConfig.touchpadDisableWhileTyping
        title: "Disable while typing"
        subtitle: on ? "On" : "Off"
        onToggled: NiriConfig.setFlag("touchpad", "dwt", !NiriConfig.touchpadDisableWhileTyping)
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
                font.bold: NiriConfig.touchpadAccelProfile === modelData
                font.pixelSize: Config.fontSizeCaption
                color: NiriConfig.touchpadAccelProfile === modelData ? Config.colAccent : Config.colSubtext

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NiriConfig.setValue("touchpad", "accel-profile", parent.modelData, true)
                }
            }
        }
    }

    SliderRow {
        iconName: "input-touchpad-symbolic"
        value: (NiriConfig.touchpadAccelSpeed + 1) / 2
        onReleased: newValue => NiriConfig.setValue("touchpad", "accel-speed", (newValue * 2 - 1).toFixed(2), false)
    }

    Item {
        Layout.fillHeight: true
    }
}
