import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import qs

RowLayout {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property var wifiDevice: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi)
                return d;
        return null;
    }
    readonly property var connectedWifiNetwork: {
        if (!wifiDevice)
            return null;
        for (const n of wifiDevice.networks.values)
            if (n.connected)
                return n;
        return null;
    }

    function volumeIconName() {
        if (root.muted || root.volume <= 0)
            return "audio-volume-muted";
        if (root.volume < 0.34)
            return "audio-volume-low";
        if (root.volume < 0.67)
            return "audio-volume-medium";
        return "audio-volume-high";
    }

    function batteryIconName() {
        const pct = Math.round(UPower.displayDevice.percentage * 100);
        const charging = UPower.displayDevice.state == UPowerDeviceState.Charging;
        let level;
        if (pct >= 90)
            level = "full";
        else if (pct >= 60)
            level = "good";
        else if (pct >= 35)
            level = "low";
        else if (pct >= 15)
            level = "caution";
        else
            level = "empty";
        return "battery-" + level + (charging ? "-charging" : "") + "-symbolic";
    }

    function wifiIconName() {
        if (!Networking.wifiEnabled)
            return "network-wireless-disabled-symbolic";
        if (!root.connectedWifiNetwork)
            return "network-wireless-signal-none-symbolic";
        return "network-wireless-signal-good-symbolic";
    }

    function bluetoothIconName() {
        return (Bluetooth.defaultAdapter?.enabled ?? false) ? "network-bluetooth-activated-symbolic" : "network-bluetooth-inactive-symbolic";
    }

    spacing: Config.spacingMedium

    PwObjectTracker {
        objects: [root.sink]
    }

    IconImage {
        source: Quickshell.iconPath(root.volumeIconName(), "audio-volume-high")
        implicitSize: Config.iconSizeStatus
    }

    IconImage {
        source: Quickshell.iconPath(root.batteryIconName(), "battery-full-symbolic")
        implicitSize: Config.iconSizeStatus
        visible: UPower.displayDevice.isPresent
    }

    IconImage {
        source: Quickshell.iconPath(root.wifiIconName(), "network-wireless")
        implicitSize: Config.iconSizeStatus
    }

    IconImage {
        source: Quickshell.iconPath(root.bluetoothIconName(), "network-bluetooth-symbolic")
        implicitSize: Config.iconSizeStatus
    }
}
