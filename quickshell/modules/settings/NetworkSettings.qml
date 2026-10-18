import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import qs

ColumnLayout {
    id: root

    readonly property var wifiDevice: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi)
                return d;
        return null;
    }
    property var pendingNetwork: null

    function wifiIconName(network) {
        const s = network.signalStrength;
        if (s >= 80)
            return "network-wireless-signal-excellent-symbolic";
        if (s >= 55)
            return "network-wireless-signal-good-symbolic";
        if (s >= 30)
            return "network-wireless-signal-ok-symbolic";
        if (s > 0)
            return "network-wireless-signal-weak-symbolic";
        return "network-wireless-signal-none-symbolic";
    }

    function activate(network) {
        if (network.connected)
            return;
        if (!network.known && network.security !== WifiSecurityType.Open) {
            root.pendingNetwork = network;
            return;
        }
        network.connect();
    }

    spacing: Config.spacingSmall

    Component.onCompleted: if (wifiDevice)
        wifiDevice.scannerEnabled = true
    Component.onDestruction: if (wifiDevice)
        wifiDevice.scannerEnabled = false

    RowLayout {
        Layout.fillWidth: true
        visible: root.pendingNetwork !== null
        spacing: Config.spacingSmall

        TextField {
            id: pskField

            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: "Password for " + (root.pendingNetwork ? root.pendingNetwork.name : "")
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeBody
            color: Config.colText
            placeholderTextColor: Config.colSubtext

            background: Rectangle {
                radius: Config.radiusMedium
                color: Config.colSurfaceVariant
                border.width: Config.borderWidth
                border.color: pskField.activeFocus ? Config.colBorderAccent : Config.colBorder
            }

            onAccepted: {
                root.pendingNetwork.connectWithPsk(text);
                root.pendingNetwork = null;
                text = "";
            }
        }

        Text {
            text: "Cancel"
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeCaption
            color: Config.colSubtext

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.pendingNetwork = null;
                    pskField.text = "";
                }
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Config.spacingXSmall
        visible: root.wifiDevice !== null
        model: root.wifiDevice ? root.wifiDevice.networks : null

        delegate: SettingsRow {
            id: networkRow

            required property var modelData

            iconName: root.wifiIconName(modelData)
            iconFallback: "network-wireless-signal-good-symbolic"
            title: modelData.name
            subtitle: modelData.connected ? "Connected" : (modelData.known ? "Saved" : (modelData.security !== WifiSecurityType.Open ? "Secured" : ""))
            highlighted: modelData.connected

            onClicked: root.activate(modelData)

            IconImage {
                visible: modelData.known
                source: Quickshell.iconPath("edit-delete-symbolic", "edit-delete")
                implicitSize: Config.iconSizeSmall

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.forget()
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.wifiDevice === null
        text: "No Wi-Fi device found"
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }
}
