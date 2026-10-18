import QtQuick
import Quickshell
import Quickshell.Networking
import qs.modules.components

QuickToggleTile {
    id: root

    readonly property var wifiDevice: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi)
                return d;
        return null;
    }
    readonly property var connectedNetwork: {
        if (!wifiDevice)
            return null;
        for (const n of wifiDevice.networks.values)
            if (n.connected)
                return n;
        return null;
    }

    iconName: "network-wireless"
    on: Networking.wifiEnabled
    title: "Wi-Fi"
    subtitle: on ? (connectedNetwork ? connectedNetwork.name : "On") : "Off"

    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
    onTitleClicked: Quickshell.execDetached(["gnome-control-center", "wifi"])
}
