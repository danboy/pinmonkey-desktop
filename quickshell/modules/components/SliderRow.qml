import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

RowLayout {
    id: root

    property string iconName
    property string iconFallback: iconName
    property int iconSize: Config.iconSizeSmall
    property real value: 0

    signal moved(real newValue)
    signal released(real newValue)
    signal iconClicked

    Layout.fillWidth: true
    spacing: Config.spacingLarge

    IconToggle {
        implicitWidth: Config.iconButtonSize
        implicitHeight: Config.iconButtonSize
        radius: Config.radiusPill
        iconName: root.iconName
        iconFallback: root.iconFallback
        iconSize: root.iconSize
        onClicked: root.iconClicked()
    }

    Slider {
        id: slider

        Layout.fillWidth: true
        from: 0
        to: 1
        value: root.value
        onMoved: root.moved(value)
        onPressedChanged: if (!pressed)
            root.released(value)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Config.sliderTrackMinWidth
            implicitHeight: Config.sliderTrackHeight
            width: slider.availableWidth
            radius: Config.sliderTrackRadius
            color: Config.colSurfaceHighlight

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: Config.sliderTrackRadius
                color: Config.colAccent
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Config.sliderHandleSize
            implicitHeight: Config.sliderHandleSize
            radius: Config.sliderHandleRadius
            color: Config.colText
        }
    }

    Text {
        text: Math.round(root.value * 100) + "%"
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
        Layout.preferredWidth: Config.percentTextWidth
    }
}
