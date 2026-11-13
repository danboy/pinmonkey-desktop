import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth
import qs
import qs.modules.components

ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false

    // Last-built rows array plus the key it was built from, so unrelated property churn
    // (battery/RSSI/connected ticks on an existing device) returns the SAME array instance
    // instead of a new one - a new instance on every poll is what made the ListView reset
    // its scroll position to the top on each update.
    property var _rowsCache: []
    property string _rowsKey: ""

    // Flattened [header, device, ...] list so the whole panel scrolls as one view, grouped
    // like GNOME/macOS: paired devices first, then nearby devices still available to pair.
    readonly property var rows: {
        if (!root.adapter || !root.powered) {
            root._rowsCache = [];
            root._rowsKey = "";
            return root._rowsCache;
        }

        const paired = [];
        const other = [];
        for (const d of root.adapter.devices.values)
            (d.paired ? paired : other).push(d);

        const key = root.adapter.discovering + "|" + paired.map(d => d.address).join(",") + "|" + other.map(d => d.address).join(",");
        if (key === root._rowsKey)
            return root._rowsCache;

        const list = [];
        if (paired.length > 0) {
            list.push({
                kind: "header",
                label: "My Devices"
            });
            for (const d of paired)
                list.push({
                    kind: "device",
                    device: d
                });
        }

        list.push({
            kind: "header",
            label: root.adapter.discovering ? "Other Devices · Searching…" : "Other Devices"
        });
        if (other.length > 0) {
            for (const d of other)
                list.push({
                    kind: "device",
                    device: d
                });
        } else {
            list.push({
                kind: "empty",
                label: root.adapter.discovering ? "Looking for devices…" : "No devices found"
            });
        }

        root._rowsKey = key;
        root._rowsCache = list;
        return list;
    }

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
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
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

    QuickToggleTile {
        iconName: root.powered ? "network-bluetooth-activated-symbolic" : "network-bluetooth-inactive-symbolic"
        iconFallback: "network-bluetooth-symbolic"
        on: root.powered
        title: "Bluetooth"
        subtitle: root.adapter ? (root.powered ? "On" : "Off") : "No adapter found"
        onToggled: root.adapter.enabled = !root.adapter.enabled
    }

    Divider {}

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Config.spacingXSmall
        visible: root.adapter !== null && root.powered
        model: root.rows

        delegate: Item {
            id: entry

            required property var modelData

            width: ListView.view ? ListView.view.width : implicitWidth
            implicitHeight: modelData.kind === "device" ? deviceRow.implicitHeight : headerText.implicitHeight + Config.spacingMedium

            Text {
                id: headerText

                visible: modelData.kind === "header"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                text: modelData.label ?? ""
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }

            Text {
                visible: modelData.kind === "empty"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label ?? ""
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colSubtext
            }

            SettingsRow {
                id: deviceRow

                visible: modelData.kind === "device"
                width: parent.width

                iconName: modelData.kind === "device" ? modelData.device.icon : ""
                iconFallback: "bluetooth-symbolic"
                title: modelData.kind === "device" ? modelData.device.name : ""
                subtitle: modelData.kind === "device" ? root.statusText(modelData.device) : ""
                highlighted: modelData.kind === "device" && modelData.device.connected

                onClicked: root.activate(modelData.device)

                IconImage {
                    visible: modelData.kind === "device" && modelData.device.paired
                    source: Quickshell.iconPath("edit-delete-symbolic", "edit-delete")
                    implicitSize: Config.iconSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.device.forget()
                    }
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

    Text {
        Layout.fillWidth: true
        visible: root.adapter !== null && !root.powered
        text: "Turn on Bluetooth to see devices"
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }

    Item {
        Layout.fillHeight: true
        visible: !(root.adapter !== null && root.powered)
    }
}
