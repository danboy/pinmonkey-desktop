import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth
import qs

ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    function activate(device) {
        if (!device.paired) {
            device.pair();
        } else if (device.connected) {
            device.disconnect();
        } else {
            device.connect();
        }
    }

    function statusText(device) {
        if (device.pairing)
            return "Pairing…";
        if (device.connected)
            return device.batteryAvailable ? "Connected · " + Math.round(device.battery * 100) + "%" : "Connected";
        if (device.paired)
            return "Paired";
        return "Available";
    }

    spacing: Config.spacingSmall

    Component.onCompleted: if (adapter)
        adapter.discovering = true
    Component.onDestruction: if (adapter)
        adapter.discovering = false

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Config.spacingXSmall
        visible: root.adapter !== null
        model: root.adapter ? root.adapter.devices : null

        delegate: SettingsRow {
            id: deviceRow

            required property var modelData

            iconName: modelData.icon
            iconFallback: "bluetooth-symbolic"
            title: modelData.name
            subtitle: root.statusText(modelData)
            highlighted: modelData.connected

            onClicked: root.activate(modelData)

            IconImage {
                visible: deviceRow.modelData.paired
                source: Quickshell.iconPath("edit-delete-symbolic", "edit-delete")
                implicitSize: Config.iconSizeSmall

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceRow.modelData.forget()
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.adapter === null
        text: "No Bluetooth adapter found"
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }
}
