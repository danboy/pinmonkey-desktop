import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components

// Combines Keyboard/Mouse/Touchpad into one nav section with an inner pill tab-bar, instead
// of three separate top-level nav entries - the individual *Settings.qml components are
// unchanged, just nested and switched here.
ColumnLayout {
    id: root

    spacing: Config.spacingLarge

    property string subTab: "keyboard"

    PillSelector {
        options: [
            { label: "Keyboard", value: "keyboard" },
            { label: "Mouse", value: "mouse" },
            { label: "Touchpad", value: "touchpad" }
        ]
        currentValue: root.subTab
        onSelected: value => root.subTab = value
    }

    Divider {}

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        KeyboardSettings {
            anchors.fill: parent
            visible: root.subTab === "keyboard"
        }

        MouseSettings {
            anchors.fill: parent
            visible: root.subTab === "mouse"
        }

        TouchpadSettings {
            anchors.fill: parent
            visible: root.subTab === "touchpad"
        }
    }
}
