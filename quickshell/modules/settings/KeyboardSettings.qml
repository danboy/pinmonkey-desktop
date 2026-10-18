import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components
import qs.modules.services

ColumnLayout {
    id: root

    spacing: Config.spacingSmall

    QuickToggleTile {
        iconName: "input-keyboard-symbolic"
        on: NiriConfig.numlockEnabled
        title: "Numlock on startup"
        subtitle: on ? "On" : "Off"
        onToggled: NiriConfig.setFlag("keyboard", "numlock", !NiriConfig.numlockEnabled)
    }

    Item {
        Layout.fillHeight: true
    }
}
