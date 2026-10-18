import QtQuick
import qs.modules.components
import qs.modules.services
import qs.modules.osd

SliderRow {
    id: root

    iconName: "video-display-brightness-symbolic"
    iconFallback: "video-display-brightness"
    value: Brightness.brightness

    onValueChanged: Osd.show(iconName, value, iconFallback)

    onReleased: newValue => Brightness.setBrightness(newValue)
}
